# PolyVault 性能监控报告

## 1. 监控架构

```
┌─────────────────┐     ┌─────────────────┐
│ Flutter Client  │     │   C++ Agent     │
│ Performance     │     │   eCAL Monitor  │
│ Monitor         │     │                 │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────────┬───────────┘
                     ▼
            ┌─────────────────┐
            │   Prometheus    │
            │   + Grafana     │
            └─────────────────┘
```

## 2. Flutter性能监控

### 监控指标
| 指标 | 说明 | 目标值 |
|------|------|--------|
| FPS | 帧率 | > 55 |
| 掉帧率 | 丢帧比例 | < 5% |
| 内存 | RSS使用 | < 200MB |
| 操作耗时 | API响应 | < 500ms |

### 使用方式
```dart
FlutterPerformanceMonitor().startMonitoring();
final metrics = FlutterPerformanceMonitor().getMetrics();
```

## 3. eCAL通信监控

### 监控内容
- 消息发送统计
- 消息接收统计
- 通信延迟
- 错误计数

### 使用方式
```cpp
#include "monitoring/ecal_monitor.hpp"

// 计时
ScopedTimer timer("credential_sync");

// 获取统计
auto stats = EcalMonitor::instance().getSendStats();
```

## 4. 资源监控

### 系统资源
- 内存使用
- CPU使用
- 网络IO
- 磁盘IO

## 5. 告警规则

| 指标 | 阈值 | 级别 |
|------|------|------|
| FPS | < 30 | Warning |
| 内存 | > 300MB | Warning |
| eCAL延迟 | > 100ms | Warning |
| 错误率 | > 1% | Critical |

## 6. 结论

PolyVault性能监控系统已配置：
- ✅ Flutter性能监控
- ✅ eCAL通信监控
- ✅ 资源使用监控
- ✅ Prometheus集成