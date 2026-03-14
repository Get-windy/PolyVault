#!/bin/bash
# ============================================
# PolyVault部署脚本
# 用法: ./scripts/deploy.sh [环境] [版本] [选项]
# ============================================

set -e

# ==================== 配置 ====================
ENVIRONMENT="${1:-development}"
VERSION="${2:-latest}"
OPTIONS="${3:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

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

# ==================== 部署服务 ====================
deploy_service() {
    log_step "部署服务到 $ENVIRONMENT 环境..."
    
    cd "$PROJECT_DIR"
    
    # 停止现有服务
    docker compose --profile "$PROFILE" down
    
    # 启动服务
    docker compose --profile "$PROFILE" up -d
    
    # 等待服务启动
    sleep 5
    
    # 健康检查
    if curl -sf "http://localhost:8080/health" > /dev/null; then
        log_info "服务健康检查通过 ✅"
    else
        log_warn "服务健康检查失败，请检查日志"
    fi
    
    log_info "部署完成 ✅"
}

# ==================== 查看日志 ====================
show_logs() {
    log_info "查看服务日志..."
    docker compose logs -f agent
}

# ==================== 停止服务 ====================
stop_service() {
    log_step "停止服务..."
    docker compose --profile "$PROFILE" down
    log_info "服务已停止 ✅"
}

# ==================== 清理资源 ====================
cleanup() {
    log_step "清理资源..."
    
    docker compose down -v --rmi local
    docker system prune -f
    
    log_info "清理完成 ✅"
}

# ==================== 显示状态 ====================
show_status() {
    echo ""
    echo "========================================"
    echo "  PolyVault 服务状态"
    echo "========================================"
    echo ""
    
    docker compose ps
    
    echo ""
    echo "健康检查:"
    if curl -sf "http://localhost:8080/health" > /dev/null; then
        echo -e "  ${GREEN}✅ Agent服务正常${NC}"
    else
        echo -e "  ${RED}❌ Agent服务异常${NC}"
    fi
    
    echo ""
}

# ==================== 帮助信息 ====================
show_help() {
    cat << EOF
PolyVault部署脚本

用法: $0 <环境> [版本] [选项]

环境:
  development    开发环境（默认）
  staging        测试环境
  production     生产环境

版本:
  latest         最新版本（默认）
  v0.1.0         指定版本

选项:
  --build        仅构建镜像
  --deploy       构建并部署
  --logs         查看日志
  --stop         停止服务
  --status       查看状态
  --clean        清理资源
  --help         显示帮助

示例:
  $0 development              # 开发环境部署
  $0 production v0.1.0        # 生产环境部署指定版本
  $0 --logs                   # 查看日志
  $0 --status                 # 查看状态

Docker Compose Profiles:
  dev           开发模式（agent-dev）
  staging       测试模式（agent + redis）
  monitoring    监控模式（agent + prometheus + grafana）
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
            build_image
            deploy_service
            ;;
        --logs)
            show_logs
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
            build_image
            deploy_service
            ;;
    esac
}

main