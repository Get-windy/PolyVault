#!/usr/bin/env python3
"""
PolyVault 自动扩展脚本
支持手动和自动扩缩容
"""

import os
import sys
import json
import time
import subprocess
import requests
from typing import Dict, List, Optional

# 配置
CONFIG = {
    "min_instances": 2,
    "max_instances": 10,
    "cpu_threshold_up": 70,
    "cpu_threshold_down": 30,
    "memory_threshold_up": 80,
    "memory_threshold_down": 40,
    "cooldown_period": 300,
    "compose_file": "docker-compose.lb.yml",
    "project_name": "polyvault",
}

# 状态文件
STATE_FILE = "/tmp/polyvault_scale_state.json"


def log_info(msg: str):
    print(f"[INFO] {msg}")


def log_warn(msg: str):
    print(f"[WARN] {msg}")


def log_error(msg: str):
    print(f"[ERROR] {msg}")


def get_current_instances() -> int:
    """获取当前运行的实例数"""
    try:
        result = subprocess.run(
            ["docker", "ps", "--filter", f"name=polyvault-agent-", 
             "--filter", "status=running", "--format", "{{.Names}}"],
            capture_output=True, text=True
        )
        containers = result.stdout.strip().split('\n')
        return len([c for c in containers if c])
    except Exception as e:
        log_error(f"获取实例数失败: {e}")
        return 0


def get_resource_usage() -> Dict[str, float]:
    """获取资源使用率"""
    try:
        result = subprocess.run(
            ["docker", "stats", "--no-stream", "--format", 
             "{{.CPUPerc}}\t{{.MemPerc}}"],
            capture_output=True, text=True
        )
        lines = result.stdout.strip().split('\n')
        
        cpu_values = []
        mem_values = []
        
        for line in lines:
            if line:
                parts = line.split('\t')
                if len(parts) >= 2:
                    cpu = float(parts[0].replace('%', ''))
                    mem = float(parts[1].replace('%', ''))
                    cpu_values.append(cpu)
                    mem_values.append(mem)
        
        return {
            "cpu": sum(cpu_values) / len(cpu_values) if cpu_values else 0,
            "memory": sum(mem_values) / len(mem_values) if mem_values else 0
        }
    except Exception as e:
        log_error(f"获取资源使用率失败: {e}")
        return {"cpu": 0, "memory": 0}


def scale_up() -> bool:
    """扩容"""
    current = get_current_instances()
    new_count = current + 1
    
    if new_count > CONFIG["max_instances"]:
        log_warn(f"已达到最大实例数限制: {CONFIG['max_instances']}")
        return False
    
    log_info(f"扩容: {current} -> {new_count} 实例")
    
    # 更新docker-compose配置并启动
    try:
        subprocess.run(
            ["docker-compose", "-f", CONFIG["compose_file"], 
             "-p", CONFIG["project_name"], "up", "-d", f"agent-{new_count}"],
            check=True
        )
        
        # 更新nginx配置
        update_nginx_config(new_count)
        
        log_info("扩容完成")
        return True
    except Exception as e:
        log_error(f"扩容失败: {e}")
        return False


def scale_down() -> bool:
    """缩容"""
    current = get_current_instances()
    new_count = current - 1
    
    if new_count < CONFIG["min_instances"]:
        log_warn(f"已达到最小实例数限制: {CONFIG['min_instances']}")
        return False
    
    log_info(f"缩容: {current} -> {new_count} 实例")
    
    try:
        # 停止最后一个实例
        subprocess.run(
            ["docker", "stop", f"polyvault-agent-{current}"],
            check=True
        )
        subprocess.run(
            ["docker", "rm", f"polyvault-agent-{current}"],
            check=True
        )
        
        # 更新nginx配置
        update_nginx_config(new_count)
        
        # 重载nginx
        subprocess.run(
            ["docker", "exec", "polyvault-nginx-lb", "nginx", "-s", "reload"],
            check=True
        )
        
        log_info("缩容完成")
        return True
    except Exception as e:
        log_error(f"缩容失败: {e}")
        return False


def scale_to(target: int) -> bool:
    """设置指定实例数"""
    current = get_current_instances()
    
    if target < CONFIG["min_instances"] or target > CONFIG["max_instances"]:
        log_error(f"实例数必须在 {CONFIG['min_instances']} 到 {CONFIG['max_instances']} 之间")
        return False
    
    if target == current:
        log_info(f"当前已是 {target} 个实例")
        return True
    
    diff = target - current
    success = True
    
    for _ in range(abs(diff)):
        if diff > 0:
            if not scale_up():
                success = False
                break
        else:
            if not scale_down():
                success = False
                break
        time.sleep(5)
    
    return success


def auto_scale():
    """自动扩展"""
    usage = get_resource_usage()
    current = get_current_instances()
    
    log_info(f"当前状态: 实例={current}, CPU={usage['cpu']:.1f}%, 内存={usage['memory']:.1f}%")
    
    # 检查冷却期
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE) as f:
            state = json.load(f)
        last_scale = state.get("last_scale", 0)
        if time.time() - last_scale < CONFIG["cooldown_period"]:
            log_info("冷却期中，跳过自动扩展")
            return
    
    # 扩容判断
    if usage["cpu"] > CONFIG["cpu_threshold_up"] or usage["memory"] > CONFIG["memory_threshold_up"]:
        log_warn("资源使用率过高，触发扩容")
        if scale_up():
            save_state()
    # 缩容判断
    elif usage["cpu"] < CONFIG["cpu_threshold_down"] and usage["memory"] < CONFIG["memory_threshold_down"]:
        log_info("资源使用率较低，触发缩容")
        if scale_down():
            save_state()
    else:
        log_info("资源使用正常，无需扩缩容")


def update_nginx_config(count: int):
    """更新nginx配置"""
    upstream = "\n".join([
        f"        server agent-{i}:8080 weight=5 max_fails=3 fail_timeout=30s;"
        for i in range(1, count + 1)
    ])
    
    config_path = "../config/nginx/nginx-cluster.conf"
    
    try:
        with open(config_path, 'r') as f:
            content = f.read()
        
        # 替换upstream配置
        import re
        pattern = r'(upstream polyvault_cluster \{[^}]*?server ).*?;'
        replacement = f'upstream polyvault_cluster {{\n        least_conn;\n        \n{upstream}\n        \n        keepalive 64;'
        
        new_content = re.sub(
            r'upstream polyvault_cluster \{[^}]+\}',
            replacement,
            content,
            flags=re.DOTALL
        )
        
        with open(config_path, 'w') as f:
            f.write(new_content)
        
        log_info("已更新nginx配置")
    except Exception as e:
        log_error(f"更新nginx配置失败: {e}")


def save_state():
    """保存状态"""
    with open(STATE_FILE, 'w') as f:
        json.dump({"last_scale": time.time()}, f)


def show_status():
    """显示状态"""
    current = get_current_instances()
    usage = get_resource_usage()
    
    print("\n================================")
    print("  PolyVault 集群状态")
    print("================================")
    print(f"\n后端实例: {current} / {CONFIG['max_instances']}")
    print(f"CPU使用率: {usage['cpu']:.1f}%")
    print(f"内存使用率: {usage['memory']:.1f}%")
    print("\n阈值配置:")
    print(f"  扩容: CPU > {CONFIG['cpu_threshold_up']}% 或 内存 > {CONFIG['memory_threshold_up']}%")
    print(f"  缩容: CPU < {CONFIG['cpu_threshold_down']}% 且 内存 < {CONFIG['memory_threshold_down']}%")
    print("\n运行中的容器:")
    
    result = subprocess.run(
        ["docker", "ps", "--filter", "name=polyvault", 
         "--format", "table {{.Names}}\t{{.Status}}\t{{.Ports}}"],
        capture_output=True, text=True
    )
    print(result.stdout)


def main():
    if len(sys.argv) < 2:
        print("用法: scale.py {up|down|status|auto|<实例数>}")
        sys.exit(1)
    
    action = sys.argv[1]
    
    if action == "up":
        scale_up()
    elif action == "down":
        scale_down()
    elif action == "status":
        show_status()
    elif action == "auto":
        auto_scale()
    elif action.isdigit():
        scale_to(int(action))
    else:
        print(f"未知操作: {action}")
        sys.exit(1)


if __name__ == "__main__":
    main()