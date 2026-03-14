# ============================================
# PolyVault Agent - Dockerfile
# 多阶段构建：构建 + 运行时镜像
# ============================================

# ==================== 构建阶段 ====================
FROM ubuntu:22.04 AS builder

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive

# 安装构建依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /build

# 复制源代码
COPY src/agent/ ./agent/
COPY protos/ ./protos/

# 构建Agent
WORKDIR /build/agent

# 创建构建目录
RUN mkdir -p build && cd build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SIMPLE=ON \
        -DBUILD_TESTS=OFF \
        -G Ninja && \
    cmake --build . --parallel

# ==================== 运行时阶段 ====================
FROM ubuntu:22.04 AS runtime

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive

# 安装运行时依赖
RUN apt-get update && apt-get install -y \
    libssl3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 创建非root用户
RUN useradd -m -s /bin/bash polyvault

# 设置工作目录
WORKDIR /app

# 从构建阶段复制可执行文件
COPY --from=builder /build/agent/build/polyvault_agent_simple /app/bin/

# 创建配置和日志目录
RUN mkdir -p /app/config /app/logs /app/data && \
    chown -R polyvault:polyvault /app

# 切换到非root用户
USER polyvault

# 设置环境变量
ENV POLYVAULT_LOG_LEVEL=info
ENV POLYVAULT_LOG_DIR=/app/logs
ENV POLYVAULT_DATA_DIR=/app/data

# 暴露端口（REST API）
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# 启动命令
ENTRYPOINT ["/app/bin/polyvault_agent_simple"]
CMD ["--config", "/app/config/config.yaml"]

# ==================== 开发镜像 ====================
FROM builder AS development

# 安装开发工具
RUN apt-get update && apt-get install -y \
    gdb \
    valgrind \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build/agent

CMD ["/bin/bash"]

# ==================== 标签 ====================
LABEL org.opencontainers.image.title="PolyVault Agent"
LABEL org.opencontainers.image.description="PolyVault Remote Authorization Agent"
LABEL org.opencontainers.image.version="0.1.0"
LABEL org.opencontainers.image.vendor="OpenClaw"
LABEL org.opencontainers.image.source="https://github.com/openclaw/polyvault"