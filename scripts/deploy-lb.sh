#!/bin/bash
# ============================================
# PolyVault部署脚本（负载均衡版本）
# 用法: ./scripts/deploy-lb.sh [环境] [版本] [选项]
# ============================================

set -e

# ==================== 配置 ====================
ENVIRONMENT="${1:-development}"
VERSION="${2:-latest}"
OPTIONS="${3:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
COMPOSE_LB_FILE="$PROJECT_DIR/docker-compose.lb.yml"

# 负载均衡配置
DEFAULT_REPLICAS=2
MAX_REPLICAS=10
REPLICAS="${REPLICAS:-$DEFAULT_REPLICAS}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_lb() { echo -e "${CYAN}[LB]${NC} $1"; }

# ==================== 环境配置 ====================
declare -A ENV_CONFIG=(
    ["development"]="dev"
    ["staging"]="staging"
    ["production"]="production"
)

PROFILE="${ENV_CONFIG[$ENVIRONMENT]:-dev}"

# ==================== 检查依赖 ====================
check_dependencies() {
    log_step "检查依赖..."
    
    local missing=()
    
    if ! command -v docker &> /dev/null; then
        missing+=("docker")
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        missing+=("docker-compose")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "缺少依赖: ${missing[*]}"
        exit 1
    fi
    
    log_info "依赖检查完成 ✅"
}

# ==================== 验证配置 ====================
validate_config() {
    log_step "验证配置..."
    
    # 检查SSL证书
    if [ ! -f "$PROJECT_DIR/config/ssl/cert.pem" ]; then
        log_warn "SSL证书未找到，生成自签名证书..."
        mkdir -p "$PROJECT_DIR/config/ssl"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$PROJECT_DIR/config/ssl/key.pem" \
            -out "$PROJECT_DIR/config/ssl/cert.pem" \
            -subj "/CN=localhost/O=PolyVault/C=US"
        log_info "自签名证书已生成 ⚠️ (仅用于开发/测试)"
    fi
    
    # 检查环境变量
    if [ -z "$ENCRYPTION_KEY" ]; then
        log_warn "ENCRYPTION_KEY 未设置，使用默认值..."
        export ENCRYPTION_KEY="dev-encryption-key-$(date +%s)"
    fi
    
    log_info "配置验证完成 ✅"
}

# ==================== 构建镜像 ====================
build_image() {
    log_step "构建Docker镜像..."
    
    cd "$PROJECT_DIR"
    
    docker compose build \
        --build-arg VERSION="$VERSION" \
        --no-cache \
        agent
    
    log_info "镜像构建完成 ✅"
}

# ==================== 部署负载均衡 ====================
deploy_load_balanced() {
    log_step "部署负载均衡服务到 $ENVIRONMENT 环境..."
    log_lb "实例数量: $REPLICAS"
    
    cd "$PROJECT_DIR"
    
    # 停止现有服务
    docker compose -f "$COMPOSE_FILE" -f "$COMPOSE_LB_FILE" --profile "$PROFILE" down
    
    # 拉取基础镜像
    log_info "拉取基础镜像..."
    docker compose -f "$COMPOSE_FILE" -f "$COMPOSE_LB_FILE" pull nginx-lb redis 2>/dev/null || true
    
    # 启动服务（带副本数）
    docker compose -f "$COMPOSE_FILE" -f "$COMPOSE_LB_FILE" \
        --profile "$PROFILE" \
        up -d \
        --scale agent="$REPLICAS"
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 10
    
    # 健康检查
    check_lb_health
    
    log_info "负载均衡部署完成 ✅"
}

# ==================== 滚动更新 ====================
rolling_update() {
    log_step "执行滚动更新..."
    log_lb "保持服务可用性，逐个更新实例"
    
    cd "$PROJECT_DIR"
    
    # 使用Docker Compose的滚动更新
    docker compose -f "$COMPOSE_FILE" -f "$COMPOSE_LB_FILE" \
        --profile "$PROFILE" \
        up -d \
        --no-deps \
        --scale agent="$REPLICAS" \
        agent
    
    # 等待新实例健康
    sleep 5
    
    check_lb_health
    
    log_info "滚动更新完成 ✅"
}

# ==================== 扩缩容 ====================
scale_service() {
    local target_replicas="$1"
    
    if [ -z "$target_replicas" ]; then
        log_error "请指定目标实例数量"
        echo "用法: $0 scale <数量>"
        echo "示例: $0 scale 5"
        exit 1
    fi
    
    if [ "$target_replicas" -gt "$MAX_REPLICAS" ]; then
        log_error "实例数量不能超过 $MAX_REPLICAS"
        exit 1
    fi
    
    log_step "扩缩容服务: $REPLICAS -> $target_replicas 实例"
    
    cd "$PROJECT_DIR"
    
    docker compose -f "$COMPOSE_FILE" -f "$COMPOSE_LB_FILE" \
        --profile "$PROFILE" \
        up -d \
        --scale agent="$target_replicas" \
        --no-deps \
        agent
    
    # 更新当前副本数
    REPLICAS="$target_replicas"
    
    check_lb_health
    
    log_info "扩缩容完成 ✅"
}

# ==================== 健康检查 ====================
check_lb_health() {
    log_lb "检查负载均衡健康状态..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # 检查NGINX
        if curl -sf "http://localhost/health" > /dev/null 2>&1; then
            log_lb "NGINX负载均衡器: 健康 ✅"
            
            # 检查后端实例
            local healthy_backends=0
            for container in $(docker ps --filter "name=polyvault-agent" --format "{{.Names}}"); do
                if docker exec "$container" curl -sf "http://localhost:8080/health" > /dev/null 2>&1; then
                    ((healthy_backends++))
                fi
            done
            
            log_lb "健康后端实例: $healthy_backends/$REPLICAS"
            
            if [ "$healthy_backends" -ge 1 ]; then
                log_lb "负载均衡健康检查通过 ✅"
                return 0
            fi
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    echo ""
    log_warn "负载均衡健康检查超时，请检查日志"
    return 1
}

# ==================== 查看日志 ====================
show_logs() {
    local service="${1:-}"
    
    if [ -n "$service" ]; then
        docker compose -f "$COMPOSE_FILE" -f "$COMPOSE_LB_FILE" logs -f "$service"
    else
        docker compose -f "$COMPOSE_FILE" -f "$COMPOSE_LB_FILE" logs -f
    fi
}

# ==================== 停止服务 ====================
stop_service() {
    log_step "停止负载均衡服务..."
    cd "$PROJECT_DIR"
    docker compose -f "$COMPOSE_FILE" -f "$COMPOSE_LB_FILE" --profile "$PROFILE" down
    log_info "服务已停止 ✅"
}

# ==================== 清理资源 ====================
cleanup() {
    log_step "清理资源..."
    cd "$PROJECT_DIR"
    
    docker compose -f "$COMPOSE_FILE" -f "$COMPOSE_LB_FILE" down -v --rmi local
    docker system prune -f
    
    log_info "清理完成 ✅"
}

# ==================== 显示状态 ====================
show_status() {
    echo ""
    echo "========================================"
    echo "  PolyVault 负载均衡服务状态"
    echo "========================================"
    echo ""
    
    cd "$PROJECT_DIR"
    docker compose -f "$COMPOSE_FILE" -f "$COMPOSE_LB_FILE" ps
    
    echo ""
    echo "负载均衡状态:"
    
    # NGINX状态
    if curl -sf "http://localhost/health" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ NGINX负载均衡器正常${NC}"
    else
        echo -e "  ${RED}❌ NGINX负载均衡器异常${NC}"
    fi
    
    # 后端实例状态
    echo ""
    echo "后端实例状态:"
    local healthy=0
    local total=0
    
    for container in $(docker ps --filter "name=polyvault-agent" --format "{{.Names}}"); do
        ((total++))
        if docker exec "$container" curl -sf "http://localhost:8080/health" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✅ $container${NC}"
            ((healthy++))
        else
            echo -e "  ${RED}❌ $container${NC}"
        fi
    done
    
    echo ""
    echo "实例统计: $healthy/$total 健康"
    echo ""
    
    # Redis状态
    if docker exec polyvault-redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
        echo -e "  ${GREEN}✅ Redis服务正常${NC}"
    else
        echo -e "  ${RED}❌ Redis服务异常${NC}"
    fi
    
    echo ""
}

# ==================== 显示帮助 ====================
show_help() {
    cat << EOF
PolyVault 负载均衡部署脚本

用法: $0 [环境] [版本] [选项]

环境:
  development    开发环境（默认）
  staging        测试环境
  production     生产环境

版本:
  latest         最新版本（默认）
  v0.1.0         指定版本

选项:
  --build        仅构建镜像
  --deploy       构建并部署负载均衡
  --update       滚动更新（零停机）
  --scale N      扩缩容到N个实例
  --logs [服务]  查看日志
  --stop         停止服务
  --status       查看状态
  --clean        清理资源
  --help         显示帮助

环境变量:
  REPLICAS       实例数量（默认: 2）
  ENCRYPTION_KEY 加密密钥

示例:
  $0 development                    # 开发环境负载均衡部署
  $0 production v0.1.0 --deploy     # 生产环境部署指定版本
  $0 --scale 5                      # 扩容到5个实例
  $0 --update                       # 滚动更新
  $0 --logs nginx-lb                # 查看负载均衡器日志
  $0 --status                       # 查看状态

负载均衡架构:
  ┌─────────────┐
  │   Client    │
  └──────┬──────┘
         │
  ┌──────▼──────┐
  │    NGINX    │  负载均衡器
  │  (LB + SSL) │
  └──────┬──────┘
         │
    ┌────┴────┬────────┐
    │         │        │
  ┌─▼─┐    ┌─▼─┐    ┌─▼─┐
  │ A │    │ A │    │ A │  Agent实例
  │ 1 │    │ 2 │    │ N │  (可扩展)
  └─┬─┘    └─┬─┘    └─┬─┘
    │         │        │
    └────┬────┴────────┘
         │
  ┌──────▼──────┐
  │    Redis    │  共享会话存储
  └─────────────┘

EOF
}

# ==================== 主流程 ====================
main() {
    case "$OPTIONS" in
        --build)
            check_dependencies
            build_image
            ;;
        --deploy)
            check_dependencies
            validate_config
            build_image
            deploy_load_balanced
            ;;
        --update)
            check_dependencies
            build_image
            rolling_update
            ;;
        --scale*)
            local target="${OPTIONS#--scale }"
            scale_service "$target"
            ;;
        --logs*)
            local service="${OPTIONS#--logs }"
            show_logs "$service"
            ;;
        --stop)
            stop_service
            ;;
        --status)
            show_status
            ;;
        --clean)
            cleanup
            ;;
        --help|-h)
            show_help
            ;;
        *)
            check_dependencies
            validate_config
            build_image
            deploy_load_balanced
            ;;
    esac
}

main