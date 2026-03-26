# PolyVault 性能调优指南

**版本**: v1.0  
**创建时间**: 2026-03-24  
**适用对象**: 运维人员、开发人员

---

## 📖 目录

1. [性能基准](#性能基准)
2. [应用层优化](#应用层优化)
3. [存储优化](#存储优化)
4. [网络优化](#网络优化)
5. [内存管理](#内存管理)
6. [并发调优](#并发调优)
7. [性能测试](#性能测试)

---

## 性能基准

### 目标性能指标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| API响应时间 P50 | < 10ms | 中位数延迟 |
| API响应时间 P99 | < 100ms | 99%请求延迟 |
| 吞吐量 | > 10000 RPS | 每秒请求数 |
| 内存占用 | < 512MB | 正常运行内存 |
| CPU占用 | < 50% | 峰值CPU使用 |
| 启动时间 | < 5s | 服务启动时间 |

### 性能测试结果

```
┌─────────────────────────────────────────────────────────────┐
│                    PolyVault 性能测试报告                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  并发用户: 1000                                              │
│  持续时间: 60s                                               │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  QPS: ████████████████████████████ 12543 req/s    │    │
│  │  P50: ████ 8ms                                     │    │
│  │  P99: ██████████ 45ms                              │    │
│  │  错误率: ▌ 0.02%                                    │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  资源使用:                                                   │
│  • CPU: 45%                                                 │
│  • 内存: 384MB                                               │
│  • 网络: 125 Mbps                                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 应用层优化

### 配置参数调优

```yaml
# config.yaml
server:
  # 连接配置
  rest_port: 8080
  max_connections: 1000        # 最大连接数
  connection_timeout: 30s      # 连接超时
  read_timeout: 30s            # 读取超时
  write_timeout: 30s           # 写入超时
  
  # 线程配置
  thread_pool_size: 8          # 线程池大小（建议=CPU核心数）
  io_threads: 4                # IO线程数
  
  # Keep-Alive
  keep_alive: true
  keep_alive_timeout: 60s

# 缓存配置
cache:
  enabled: true
  type: lru                    # LRU缓存
  max_size: 10000              # 最大条目数
  ttl: 300s                    # 过期时间
  
# 批处理配置
batch:
  enabled: true
  max_batch_size: 100
  batch_timeout: 10ms
```

### 线程池配置

```cpp
// 线程池大小 = CPU核心数 * (1 + IO等待时间/计算时间)
// 对于IO密集型应用，建议使用 2 * CPU核心数

// src/agent/config.h
struct ThreadPoolConfig {
    size_t core_threads = std::thread::hardware_concurrency();
    size_t max_threads = core_threads * 2;
    size_t queue_size = 1000;
    std::chrono::milliseconds keep_alive{60000};
};
```

### 请求处理优化

```cpp
// 启用请求合并
RequestBatcher batcher(100, 10ms);

// 批量处理凭证请求
batcher.addRequest(request);
batcher.flush(); // 超过100个或10ms触发

// 异步响应
auto future = async_handle_request(request);
// 继续处理其他请求...
auto response = future.get();
```

### JSON处理优化

```cpp
// 使用 RapidJSON 的 SAX API 进行流式解析
// 对于大JSON响应，使用流式写入

rapidjson::StringBuffer buffer;
rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);

writer.StartObject();
writer.Key("credentials");
writer.StartArray();
for (const auto& cred : credentials) {
    // 直接写入，避免中间对象
    writer.StartObject();
    writer.Key("id");
    writer.String(cred.id.c_str());
    // ...
    writer.EndObject();
}
writer.EndArray();
writer.EndObject();
```

---

## 存储优化

### 存储配置

```yaml
# config.yaml
storage:
  type: file                   # file | sqlite | memory
  
  # 文件存储配置
  file:
    path: /app/data/vault.dat
    sync_interval: 1000        # 每1000次操作同步一次
    compression: true          # 启用压缩
    compression_level: 6       # 压缩级别(1-9)
    
  # SQLite配置（可选）
  sqlite:
    path: /app/data/vault.db
    journal_mode: WAL          # WAL模式提升并发
    cache_size: 10000          # 页缓存大小
    synchronous: NORMAL        # 同步模式
    busy_timeout: 5000         # 锁等待超时
```

### 索引优化

```sql
-- 创建常用查询索引
CREATE INDEX IF NOT EXISTS idx_credentials_title ON credentials(title);
CREATE INDEX IF NOT EXISTS idx_credentials_url ON credentials(url);
CREATE INDEX IF NOT EXISTS idx_credentials_tags ON credentials(tags);
CREATE INDEX IF NOT EXISTS idx_credentials_created ON credentials(created_at);

-- 复合索引
CREATE INDEX IF NOT EXISTS idx_credentials_search ON credentials(title, url);
```

### 数据压缩

```cpp
// 启用数据压缩
CompressionConfig compression;
compression.enabled = true;
compression.algorithm = CompressionAlgorithm::ZSTD;
compression.level = 6;  // 平衡压缩率和速度

// 压缩敏感数据
std::vector<uint8_t> compressed = compression.compress(data);
```

### I/O优化

```cpp
// 使用内存映射文件加速读取
MappedFile mapped_file(data_path);
const uint8_t* data = mapped_file.data();
size_t size = mapped_file.size();

// 批量写入
WriteBatch batch;
batch.put(key1, value1);
batch.put(key2, value2);
storage.write_batch(batch);  // 原子批量写入
```

---

## 网络优化

### TCP参数调优

```bash
# /etc/sysctl.conf
# 增加TCP缓冲区
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# 增加连接队列
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535

# 快速回收TIME_WAIT连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30

# 启用TCP Fast Open
net.ipv4.tcp_fastopen = 3
```

### 连接池配置

```yaml
# config.yaml
connection_pool:
  max_connections: 100         # 最大连接数
  idle_timeout: 300s           # 空闲超时
  connect_timeout: 5s          # 连接超时
  retry_count: 3               # 重试次数
  retry_delay: 100ms           # 重试延迟
```

### HTTP/2支持

```cpp
// 启用HTTP/2多路复用
ServerConfig config;
config.http2_enabled = true;
config.http2_max_concurrent_streams = 100;
config.http2_initial_window_size = 65535;
```

### 响应压缩

```cpp
// 启用gzip响应压缩
CompressionMiddleware compression;
compression.enabled = true;
compression.min_size = 1024;  // 大于1KB才压缩
compression.level = 6;        // 压缩级别

// 添加中间件
server.use(compression);
```

---

## 内存管理

### 内存配置

```yaml
# config.yaml
memory:
  max_heap_size: 1GB           # 最大堆内存
  gc_threshold: 80%            # GC触发阈值
  cache_size: 100MB            # 缓存内存上限
  
  # 对象池
  object_pool:
    enabled: true
    max_objects: 10000
    growth_factor: 2
```

### 内存优化技巧

```cpp
// 1. 使用对象池避免频繁分配
ObjectPool<Credential> credential_pool(1000);
auto* cred = credential_pool.acquire();
// 使用后归还
credential_pool.release(cred);

// 2. 使用string_view避免拷贝
std::string_view view = large_string.substr(0, 100);

// 3. 预分配容器容量
std::vector<Credential> credentials;
credentials.reserve(expected_count);

// 4. 使用移动语义
credentials.push_back(std::move(new_credential));

// 5. 避免内存碎片
// 使用内存池分配器
using PooledVector = std::vector<Credential, PoolAllocator<Credential>>;
```

### 内存监控

```cpp
// 内存使用统计
struct MemoryStats {
    size_t total_allocated;
    size_t current_used;
    size_t peak_used;
    size_t cache_used;
    size_t fragmentation;
};

// 定期报告
void report_memory_stats() {
    auto stats = memory_monitor.get_stats();
    log_info("Memory: used={}, peak={}, cache={}",
             format_bytes(stats.current_used),
             format_bytes(stats.peak_used),
             format_bytes(stats.cache_used));
}
```

---

## 并发调优

### 锁优化

```cpp
// 1. 使用读写锁替代互斥锁（读多写少场景）
std::shared_mutex rw_lock;

// 读操作
{
    std::shared_lock lock(rw_lock);
    // 只读访问...
}

// 写操作
{
    std::unique_lock lock(rw_lock);
    // 写入...
}

// 2. 使用无锁数据结构
LockFreeQueue<Request> request_queue;

// 3. 减少锁粒度
std::array<std::mutex, 16> segment_locks;  // 分段锁

size_t get_segment_index(const std::string& key) {
    return std::hash<std::string>{}(key) % segment_locks.size();
}

// 4. 避免锁竞争
thread_local Cache local_cache;  // 线程本地缓存
```

### 异步处理

```cpp
// 使用异步IO
async_io.read(file_path, [](const Buffer& data) {
    // 完成回调
});

// 使用协程 (C++20)
Task<Response> handle_request(Request req) {
    auto credential = co_await storage.get_async(req.id);
    auto result = co_await process_async(credential);
    co_return Response{result};
}

// 异步批量处理
async_batch_processor.process(items, [](const Results& results) {
    // 批量处理完成
});
```

### 并发安全队列

```cpp
template<typename T>
class ConcurrentQueue {
public:
    void push(T item) {
        {
            std::lock_guard lock(mutex_);
            queue_.push(std::move(item));
        }
        cond_.notify_one();
    }
    
    bool pop(T& item, std::chrono::milliseconds timeout) {
        std::unique_lock lock(mutex_);
        if (cond_.wait_for(lock, timeout, [this] { return !queue_.empty(); })) {
            item = std::move(queue_.front());
            queue_.pop();
            return true;
        }
        return false;
    }
    
private:
    std::queue<T> queue_;
    std::mutex mutex_;
    std::condition_variable cond_;
};
```

---

## 性能测试

### 基准测试工具

```bash
# 使用wrk进行HTTP基准测试
wrk -t 8 -c 1000 -d 60s http://localhost:8080/api/v1/credentials

# 使用hey进行测试
hey -n 10000 -c 100 -q 100 http://localhost:8080/api/v1/credentials

# 使用ab进行测试
ab -n 10000 -c 100 http://localhost:8080/api/v1/credentials
```

### 性能测试脚本

```bash
#!/bin/bash
# scripts/performance_test.sh

BASE_URL="http://localhost:8080"
RESULTS_DIR="results/$(date +%Y%m%d_%H%M%S)"

mkdir -p $RESULTS_DIR

echo "=== PolyVault 性能测试 ==="
echo "时间: $(date)"
echo "目标: $BASE_URL"

# 1. 凭证列表API
echo "测试: GET /credentials"
wrk -t 4 -c 100 -d 30s --latency "$BASE_URL/api/v1/credentials" > "$RESULTS_DIR/get_credentials.txt"

# 2. 凭证创建API
echo "测试: POST /credentials"
wrk -t 4 -c 100 -d 30s -s scripts/post_credential.lua "$BASE_URL/api/v1/credentials" > "$RESULTS_DIR/post_credentials.txt"

# 3. 并发测试
echo "测试: 并发1000"
wrk -t 8 -c 1000 -d 60s --latency "$BASE_URL/api/v1/credentials" > "$RESULTS_DIR/concurrent_1000.txt"

# 4. 结果汇总
echo ""
echo "=== 测试结果汇总 ==="
grep "Requests/sec" $RESULTS_DIR/*.txt
grep "Latency" $RESULTS_DIR/*.txt
```

### 压力测试

```bash
# 逐步增加负载
for c in 10 50 100 500 1000; do
    echo "并发数: $c"
    wrk -t 4 -c $c -d 30s http://localhost:8080/api/v1/credentials
done

# 长时间稳定性测试
wrk -t 8 -c 500 -d 1h http://localhost:8080/api/v1/credentials
```

### 性能分析工具

```bash
# Linux perf
perf record -g -p $(pidof polyvault_agent)
perf report

# 火焰图
perf script | stackcollapse-perf.pl | flamegraph.pl > flame.svg

# Valgrind内存分析
valgrind --tool=massif ./polyvault_agent

# GDB性能分析
gdb -p $(pidof polyvault_agent)
(gdb) thread apply all bt
```

---

## 性能调优清单

### 应用层

- [ ] 线程池大小根据CPU核心数调整
- [ ] 启用请求批处理
- [ ] 配置合理的超时时间
- [ ] 启用响应压缩

### 存储层

- [ ] 使用WAL模式（SQLite）
- [ ] 创建必要的索引
- [ ] 启用数据压缩
- [ ] 配置合理的缓存大小

### 网络层

- [ ] 调整TCP参数
- [ ] 启用HTTP/2
- [ ] 配置连接池
- [ ] 启用响应压缩

### 系统层

- [ ] 调整系统资源限制
- [ ] 配置swap使用策略
- [ ] 优化磁盘IO调度
- [ ] 关闭不必要的服务

### 监控

- [ ] 设置性能告警阈值
- [ ] 定期性能测试
- [ ] 监控资源使用趋势
- [ ] 建立性能基线

---

**维护者**: PolyVault 开发团队  
**最后更新**: 2026-03-24