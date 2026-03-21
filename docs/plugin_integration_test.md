# PolyVault 插件接口集成测试用例文档

**文档版本**: v1.0  
**创建日期**: 2026-03-21  
**编写人员**: test-agent-1  
**项目**: PolyVault  
**目录**: I:\PolyVault

---

## 📋 文档概述

本文档为PolyVault插件系统提供完整的集成测试用例，涵盖四大核心插件接口：
1. 过滤器(Filter)插件接口
2. 转换器(Transformer)插件接口
3. 汇流器(Aggregator/Merger)插件接口
4. 分发器(Distributor)插件接口

---

## 🔧 测试环境配置

### 硬件要求
- CPU: 4核及以上
- 内存: 8GB及以上
- 存储: 50GB可用空间

### 软件环境
```yaml
操作系统: Windows 10/11 或 Linux Ubuntu 20.04+
编译器: MSVC 2022 / GCC 11+
测试框架: Google Test 1.12+
依赖库:
  - eCAL 5.12+
  - Protobuf 3.21+
  - gRPC 1.50+
```

### 测试数据准备
```cpp
// 测试消息模板
bus::Message createTestMessage(const std::string& type, 
                                const std::map<std::string, std::string>& fields) {
    bus::Message msg;
    msg.set_type(type);
    for (const auto& [key, value] : fields) {
        msg.set_field(key, value);
    }
    return msg;
}
```

---

## 1️⃣ 过滤器(Filter)插件接口测试

### 1.1 接口规范

```cpp
class IFilterPlugin : public IPlugin {
public:
    struct FilterCondition {
        std::string field;      // 字段名
        std::string op;         // 操作符: eq, ne, gt, lt, gte, lte, contains, regex
        std::string value;      // 比较值
    };
    
    virtual void addCondition(const FilterCondition& condition) = 0;
    virtual void clearConditions() = 0;
    virtual std::vector<FilterCondition> getConditions() const = 0;
    virtual bool filter(const bus::Message& message) = 0;
};
```

### 1.2 测试用例集

#### TC-F-001: 基础过滤 - 等于操作
**测试目的**: 验证等于(eq)操作符的过滤功能
**前置条件**: 插件已初始化
**测试步骤**:
1. 创建过滤器实例
2. 添加条件: field="type", op="eq", value="sensor"
3. 创建测试消息: type="sensor", value="100"
4. 执行过滤
5. 验证返回true

**预期结果**:
```cpp
TEST(FilterTest, EqualOperation) {
    auto filter = createFilterPlugin();
    filter->addCondition({"type", "eq", "sensor"});
    
    auto msg = createMessage({{"type", "sensor"}, {"value", "100"}});
    EXPECT_TRUE(filter->filter(msg));
    
    auto msg2 = createMessage({{"type", "event"}, {"value", "100"}});
    EXPECT_FALSE(filter->filter(msg2));
}
```
**优先级**: P0  
**状态**: 待执行

---

#### TC-F-002: 基础过滤 - 不等于操作
**测试目的**: 验证不等于(ne)操作符的过滤功能
**测试步骤**:
1. 添加条件: field="status", op="ne", value="deleted"
2. 测试消息1: status="active" → 应通过
3. 测试消息2: status="deleted" → 应拒绝

**预期结果**: 非deleted状态的消息通过过滤
**优先级**: P0
**状态**: 待执行

---

#### TC-F-003: 数值比较 - 大于操作
**测试目的**: 验证大于(gt)操作符的数值比较
**测试步骤**:
1. 添加条件: field="priority", op="gt", value="5"
2. 测试消息: priority="10" → 应通过
3. 测试消息: priority="3" → 应拒绝
4. 测试消息: priority="5" → 应拒绝(等于不满足大于)

**预期结果**: 仅priority > 5的消息通过
**优先级**: P0
**状态**: 待执行

---

#### TC-F-004: 数值比较 - 小于操作
**测试目的**: 验证小于(lt)操作符的数值比较
**测试步骤**:
1. 添加条件: field="temperature", op="lt", value="100"
2. 测试消息: temperature="50" → 应通过
3. 测试消息: temperature="150" → 应拒绝

**预期结果**: 仅temperature < 100的消息通过
**优先级**: P0
**状态**: 待执行

---

#### TC-F-005: 数值比较 - 大于等于操作
**测试目的**: 验证大于等于(gte)操作符
**测试步骤**:
1. 添加条件: field="level", op="gte", value="3"
2. 测试消息: level="3" → 应通过
3. 测试消息: level="5" → 应通过
4. 测试消息: level="2" → 应拒绝

**预期结果**: level >= 3的消息通过
**优先级**: P0
**状态**: 待执行

---

#### TC-F-006: 数值比较 - 小于等于操作
**测试目的**: 验证小于等于(lte)操作符
**测试步骤**:
1. 添加条件: field="score", op="lte", value="100"
2. 测试消息: score="100" → 应通过
3. 测试消息: score="50" → 应通过
4. 测试消息: score="150" → 应拒绝

**预期结果**: score <= 100的消息通过
**优先级**: P0
**状态**: 待执行

---

#### TC-F-007: 字符串匹配 - 包含操作
**测试目的**: 验证contains操作符的字符串匹配
**测试步骤**:
1. 添加条件: field="tags", op="contains", value="important"
2. 测试消息: tags="urgent,important,critical" → 应通过
3. 测试消息: tags="normal,low" → 应拒绝
4. 测试消息: tags="IMPORTANT" → 应拒绝(区分大小写)

**预期结果**: 包含指定子串的消息通过
**优先级**: P0
**状态**: 待执行

---

#### TC-F-008: 字符串匹配 - 正则表达式
**测试目的**: 验证regex操作符的正则匹配
**测试步骤**:
1. 添加条件: field="device_id", op="regex", value="^sensor_[0-9]+$"
2. 测试消息: device_id="sensor_123" → 应通过
3. 测试消息: device_id="sensor_abc" → 应拒绝
4. 测试消息: device_id="device_123" → 应拒绝

**预期结果**: 符合正则表达式的消息通过
**优先级**: P1
**状态**: 待执行

---

#### TC-F-009: 多条件组合 - AND逻辑
**测试目的**: 验证多个条件的AND组合
**测试步骤**:
1. 添加条件1: field="type", op="eq", value="sensor"
2. 添加条件2: field="priority", op="gt", value="5"
3. 测试消息: type="sensor", priority="10" → 应通过
4. 测试消息: type="sensor", priority="3" → 应拒绝
5. 测试消息: type="event", priority="10" → 应拒绝

**预期结果**: 所有条件同时满足时通过
**优先级**: P0
**状态**: 待执行

---

#### TC-F-010: 条件管理 - 清除所有条件
**测试目的**: 验证clearConditions方法
**测试步骤**:
1. 添加多个条件
2. 调用clearConditions()
3. 验证getConditions()返回空列表
4. 测试任意消息应通过(或根据实现拒绝)

**预期结果**: 条件列表被清空
**优先级**: P1
**状态**: 待执行

---

#### TC-F-011: 边界测试 - 空字段值
**测试目的**: 验证空值处理
**测试步骤**:
1. 添加条件: field="name", op="eq", value=""
2. 测试消息: name="" → 应通过
3. 测试消息: name="test" → 应拒绝
4. 测试消息: 无name字段 → 行为定义

**预期结果**: 正确处理空字符串
**优先级**: P1
**状态**: 待执行

---

#### TC-F-012: 边界测试 - 缺失字段
**测试目的**: 验证消息中缺失字段的处理
**测试步骤**:
1. 添加条件: field="optional_field", op="eq", value="test"
2. 测试消息: 不包含optional_field → 应拒绝
3. 测试消息: optional_field="test" → 应通过

**预期结果**: 缺失字段视为不匹配
**优先级**: P1
**状态**: 待执行

---

#### TC-F-013: 性能测试 - 大量条件
**测试目的**: 验证100+条件的性能
**测试步骤**:
1. 添加100个不同条件
2. 执行1000次过滤操作
3. 测量平均响应时间

**预期结果**: 平均响应时间 < 1ms
**优先级**: P2
**状态**: 待执行

---

### 1.3 过滤器测试汇总

| 测试类别 | 用例数 | 优先级分布 | 状态 |
|----------|--------|------------|------|
| 基础操作 | 6 | P0: 6 | 待执行 |
| 字符串匹配 | 2 | P0: 1, P1: 1 | 待执行 |
| 多条件组合 | 1 | P0: 1 | 待执行 |
| 条件管理 | 2 | P1: 2 | 待执行 |
| 边界测试 | 2 | P1: 2 | 待执行 |
| 性能测试 | 1 | P2: 1 | 待执行 |
| **总计** | **14** | **P0: 8, P1: 5, P2: 1** | **待执行** |

---

## 2️⃣ 转换器(Transformer)插件接口测试

### 2.1 接口规范

```cpp
class ITransformerPlugin : public IPlugin {
public:
    struct TransformRule {
        std::string source_field;    // 源字段
        std::string target_field;    // 目标字段
        std::string transform_type;  // map, format, extract, compute
        std::string expression;      // 转换表达式
    };
    
    virtual void addRule(const TransformRule& rule) = 0;
    virtual void clearRules() = 0;
    virtual std::vector<TransformRule> getRules() const = 0;
    virtual bus::Message transform(const bus::Message& input) = 0;
};
```

### 2.2 测试用例集

#### TC-T-001: 字段映射 - 基本映射
**测试目的**: 验证字段映射功能
**测试步骤**:
1. 添加规则: source="old_name", target="new_name", type="map"
2. 输入消息: old_name="value123", other="data"
3. 执行转换
4. 验证输出包含new_name="value123"
5. 验证other字段保持不变

**预期结果**:
```cpp
TEST(TransformerTest, BasicMapping) {
    auto transformer = createTransformerPlugin();
    transformer->addRule({"old_name", "new_name", "map", ""});
    
    auto input = createMessage({{"old_name", "value123"}, {"other", "data"}});
    auto output = transformer->transform(input);
    
    EXPECT_EQ(output.get_field("new_name"), "value123");
    EXPECT_EQ(output.get_field("other"), "data");
}
```
**优先级**: P0
**状态**: 待执行

---

#### TC-T-002: 字段映射 - 多字段映射
**测试目的**: 验证多个字段同时映射
**测试步骤**:
1. 添加规则1: source="field_a", target="output_a", type="map"
2. 添加规则2: source="field_b", target="output_b", type="map"
3. 输入消息包含field_a和field_b
4. 验证两个字段都被正确映射

**预期结果**: 多字段同时转换成功
**优先级**: P0
**状态**: 待执行

---

#### TC-T-003: 格式化转换 - 时间戳格式化
**测试目的**: 验证时间戳格式化功能
**测试步骤**:
1. 添加规则: source="timestamp", target="datetime", type="format", expression="%Y-%m-%d %H:%M:%S"
2. 输入: timestamp="1711000000"
3. 执行转换
4. 验证输出: datetime="2024-03-21 12:00:00"

**预期结果**: Unix时间戳正确格式化为可读时间
**优先级**: P0
**状态**: 待执行

---

#### TC-T-004: 格式化转换 - 数值格式化
**测试目的**: 验证数值格式化功能
**测试步骤**:
1. 添加规则: source="value", target="formatted", type="format", expression="{:.2f}"
2. 输入: value="3.14159"
3. 执行转换
4. 验证输出: formatted="3.14"

**预期结果**: 数值按指定格式格式化
**优先级**: P0
**状态**: 待执行

---

#### TC-T-005: 提取转换 - 正则提取
**测试目的**: 验证正则表达式提取功能
**测试步骤**:
1. 添加规则: source="