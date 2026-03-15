# PolyVault 测试指南

**版本**: v1.1  
**创建时间**: 2026-03-14  
**更新时间**: 2026-03-15  
**适用对象**: 测试工程师、开发人员、插件开发者

---

## 📖 目录

1. [测试策略](#测试策略)
2. [单元测试](#单元测试)
3. [集成测试](#集成测试)
4. [E2E 测试](#e2e-测试)
5. [性能测试](#性能测试)
6. [安全测试](#安全测试)
7. [FFI Binding 测试](#ffi-binding-测试)
8. [插件测试](#插件测试)
9. [测试覆盖率](#测试覆盖率)
10. [持续集成](#持续集成)

---

## 🎯 测试策略

### 测试金字塔

```
           /\
          /  \
         / E2E \        端到端测试 (10%)
        /--------\
       /          \
      /  集成测试   \    集成测试 (20%)
     /--------------\
    /                \
   /    单元测试       \  单元测试 (70%)
  /--------------------\
```

### 测试类型分布

| 测试类型 | 占比 | 执行频率 | 执行时间 |
|---------|------|---------|---------|
| **单元测试** | 70% | 每次提交 | < 5 分钟 |
| **集成测试** | 20% | 每日构建 | < 30 分钟 |
| **E2E 测试** | 10% | 每周/发布前 | < 2 小时 |

---

### 测试环境

#### 环境配置

**测试环境层次**:
```
开发环境 → 测试环境 → 预发布环境 → 生产环境
   (dev)      (test)      (staging)    (prod)
```

**环境隔离**:
- 独立数据库
- 独立 API 密钥
- 独立 eCAL 网络
- 模拟外部服务

---

## 🧪 单元测试

### C++ Agent 单元测试

#### 测试框架

**使用 Google Test**:

**CMakeLists.txt**:
```cmake
# 启用测试
enable_testing()

# 添加 Google Test
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/release-1.13.0.zip
)
FetchContent_MakeAvailable(googletest)

# 测试可执行文件
add_executable(agent_tests
    tests/main.cpp
    tests/test_message_handler.cpp
    tests/test_vault.cpp
    # ... 其他测试文件
)

# 链接库
target_link_libraries(agent_tests
    polyvault-agent
    GTest::gtest_main
)

# 包含测试
include(GoogleTest)
gtest_discover_tests(agent_tests)
```

---

#### 测试示例

**测试消息处理** (`tests/test_message_handler.cpp`):
```cpp
#include <gtest/gtest.h>
#include "message_handler.h"
#include "generated/auth.pb.h"

class MessageHandlerTest : public ::testing::Test {
protected:
    void SetUp() override {
        handler = std::make_unique<MessageHandler>();
    }
    
    void TearDown() override {
        handler.reset();
    }
    
    std::unique_ptr<MessageHandler> handler;
};

TEST_F(MessageHandlerTest, HandleLoginRequest_Success) {
    // 准备测试数据
    LoginRequest request;
    request.set_username("testuser");
    request.set_password("testpass123");
    
    // 序列化消息
    std::string serialized;
    request.SerializeToString(&serialized);
    
    // 执行测试
    Message response = handler->HandleMessage("auth.login", serialized);
    
    // 验证结果
    EXPECT_EQ(response.type(), "auth.login_response");
    
    LoginResponse login_response;
    login_response.ParseFromString(response.data());
    
    EXPECT_TRUE(login_response.success());
    EXPECT_FALSE(login_response.token().empty());
}

TEST_F(MessageHandlerTest, HandleLoginRequest_InvalidCredentials) {
    // 准备测试数据 - 错误密码
    LoginRequest request;
    request.set_username("testuser");
    request.set_password("wrongpassword");
    
    // 序列化消息
    std::string serialized;
    request.SerializeToString(&serialized);
    
    // 执行测试
    Message response = handler->HandleMessage("auth.login", serialized);
    
    // 验证结果
    EXPECT_EQ(response.type(), "auth.login_response");
    
    LoginResponse login_response;
    login_response.ParseFromString(response.data());
    
    EXPECT_FALSE(login_response.success());
    EXPECT_EQ(login_response.error_code(), ErrorCode::INVALID_CREDENTIALS);
}

TEST_F(MessageHandlerTest, HandleVaultCreate_Success) {
    // 准备测试数据
    CreateVaultRequest request;
    request.set_name("My Vault");
    request.set_description("Test vault");
    request.set_encryption_type(EncryptionType::AES256);
    
    // 序列化消息
    std::string serialized;
    request.SerializeToString(&serialized);
    
    // 执行测试
    Message response = handler->HandleMessage("vault.create", serialized);
    
    // 验证结果
    EXPECT_EQ(response.type(), "vault.create_response");
    
    CreateVaultResponse vault_response;
    vault_response.ParseFromString(response.data());
    
    EXPECT_TRUE(vault_response.success());
    EXPECT_FALSE(vault_response.vault_id().empty());
}
```

---

#### 测试 eCAL 通信

**测试 eCAL 发布/订阅** (`tests/test_ecal_communication.cpp`):
```cpp
#include <gtest/gtest.h>
#include <ecal/ecal.h>
#include "ecal_communication.h"

class EcalCommunicationTest : public ::testing::Test {
protected:
    void SetUp() override {
        eCAL::Initialize();
        comm = std::make_unique<EcalCommunication>();
    }
    
    void TearDown() override {
        comm.reset();
        eCAL::Finalize();
    }
    
    std::unique_ptr<EcalCommunication> comm;
};

TEST_F(EcalCommunicationTest, PublishMessage_Success) {
    // 准备测试数据
    std::string topic = "polyvault.test";
    std::string message_data = "test message";
    
    // 创建订阅者接收消息
    eCAL::CSubscriber subscriber(topic);
    std::string received_data;
    
    subscriber.AddReceiveCallback([&received_data](const char* topic_name, 
                                                    const std::shared_ptr<eCAL::CMessage>& msg) {
        received_data = std::string(msg->data(), msg->size());
    });
    
    // 执行测试
    bool result = comm->Publish(topic, message_data);
    
    // 等待消息传递
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    
    // 验证结果
    EXPECT_TRUE(result);
    EXPECT_EQ(received_data, message_data);
}

TEST_F(EcalCommunicationTest, Subscribe_Success) {
    // 准备测试数据
    std::string topic = "polyvault.test.subscribe";
    std::vector<std::string> received_messages;
    
    // 创建订阅者
    bool subscribe_result = comm->Subscribe(topic, 
        [&received_messages](const std::string& data) {
            received_messages.push_back(data);
        });
    
    // 创建发布者发送消息
    eCAL::CPublisher publisher(topic);
    
    for (int i = 0; i < 5; ++i) {
        std::string msg = "message_" + std::to_string(i);
        publisher.Send(msg.c_str(), msg.size());
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    
    // 验证结果
    EXPECT_TRUE(subscribe_result);
    EXPECT_EQ(received_messages.size(), 5);
}
```

---

### Flutter 客户端单元测试

#### 测试框架

**使用 Flutter 内置测试**:

**pubspec.yaml**:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  fake_async: ^1.3.1
```

---

#### 测试示例

**测试认证服务** (`test/services/auth_service_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:polyvault/services/auth_service.dart';
import 'package:polyvault/models/user.dart';
import 'mocks.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockApiClient mockApiClient;
    late MockSecureStorage mockSecureStorage;
    
    setUp(() {
      mockApiClient = MockApiClient();
      mockSecureStorage = MockSecureStorage();
      authService = AuthService(
        apiClient: mockApiClient,
        secureStorage: mockSecureStorage,
      );
    });
    
    test('login with valid credentials returns user', () async {
      // 准备测试数据
      final testUser = User(
        id: 'user_123',
        username: 'testuser',
        email: 'test@example.com',
      );
      
      when(mockApiClient.post('/auth/login', any))
          .thenAnswer((_) async => {
                'code': 200,
                'data': {
                  'user': testUser.toJson(),
                  'token': 'test_token',
                },
              });
      
      // 执行测试
      final result = await authService.login('testuser', 'password123');
      
      // 验证结果
      expect(result.isSuccess, true);
      expect(result.user, equals(testUser));
      expect(result.token, equals('test_token'));
      verify(mockApiClient.post('/auth/login', any)).called(1);
    });
    
    test('login with invalid credentials returns error', () async {
      // 准备测试数据
      when(mockApiClient.post('/auth/login', any))
          .thenAnswer((_) async => {
                'code': 401,
                'message': 'Invalid credentials',
              });
      
      // 执行测试
      final result = await authService.login('testuser', 'wrongpassword');
      
      // 验证结果
      expect(result.isSuccess, false);
      expect(result.errorCode, equals(401));
      expect(result.errorMessage, equals('Invalid credentials'));
    });
    
    test('logout clears token', () async {
      // 准备测试数据
      when(mockSecureStorage.delete('auth_token'))
          .thenAnswer((_) async => true);
      
      // 执行测试
      final result = await authService.logout();
      
      // 验证结果
      expect(result, true);
      verify(mockSecureStorage.delete('auth_token')).called(1);
    });
  });
}
```

---

**测试 UI 组件** (`test/widgets/post_card_test.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyvault/widgets/post_card.dart';
import 'package:polyvault/models/post.dart';

void main() {
  group('PostCard Widget Tests', () {
    final testPost = Post(
      id: 'post_123',
      title: 'Test Post',
      content: 'This is a test post content',
      author: Author(id: 'user_1', username: 'testuser'),
      createdAt: DateTime(2026, 3, 14, 10, 30),
      upvotes: 10,
      downvotes: 2,
      commentCount: 5,
    );
    
    testWidgets('displays post title and content', (WidgetTester tester) async {
      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostCard(post: testPost),
          ),
        ),
      );
      
      // 验证标题
      expect(find.text('Test Post'), findsOneWidget);
      
      // 验证内容
      expect(find.text('This is a test post content'), findsOneWidget);
      
      // 验证作者
      expect(find.text('@testuser'), findsOneWidget);
    });
    
    testWidgets('displays vote counts', (WidgetTester tester) async {
      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostCard(post: testPost),
          ),
        ),
      );
      
      // 验证点赞数
      expect(find.text('10'), findsOneWidget);
      
      // 验证点踩数
      expect(find.text('2'), findsOneWidget);
      
      // 验证评论数
      expect(find.text('5'), findsOneWidget);
    });
    
    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      
      // 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostCard(
              post: testPost,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      
      // 点击组件
      await tester.tap(find.byType(PostCard));
      await tester.pump();
      
      // 验证回调
      expect(tapped, true);
    });
  });
}
```

---

## 🔗 集成测试

### API 集成测试

#### 测试配置

**测试数据库配置**:
```yaml
# config/test.yaml
database:
  host: localhost
  port: 5432
  name: polyvault_test
  user: test_user
  password: test_password

openclaw:
  base_url: https://test-api.openclaw.ai
  api_key: ${OPENCLAW_TEST_API_KEY}
  timeout: 10000
```

---

#### 测试示例

**测试认证流程** (`tests/integration/test_auth_flow.cpp`):
```cpp
#include <gtest/gtest.h>
#include "api_client.h"
#include "auth_service.h"

class AuthIntegrationTest : public ::testing::Test {
protected:
    void SetUp() override {
        config = Config::load("config/test.yaml");
        apiClient = std::make_unique<ApiClient>(config->openclawBaseUrl);
        authService = std::make_unique<AuthService>(apiClient.get());
    }
    
    void TearDown() override {
        authService.reset();
        apiClient.reset();
    }
    
    std::unique_ptr<Config> config;
    std::unique_ptr<ApiClient> apiClient;
    std::unique_ptr<AuthService> authService;
};

TEST_F(AuthIntegrationTest, RegisterAndLogin_FullFlow) {
    // 1. 注册新用户
    std::string username = "test_user_" + std::to_string(time(nullptr));
    std::string email = username + "@test.com";
    std::string password = "TestPass123!";
    
    RegisterResponse registerResp = authService->Register(username, email, password);
    
    EXPECT_TRUE(registerResp.success());
    EXPECT_FALSE(registerResp.userId().empty());
    
    // 2. 登录
    LoginResponse loginResp = authService->Login(username, password);
    
    EXPECT_TRUE(loginResp.success());
    EXPECT_FALSE(loginResp.token().empty());
    EXPECT_EQ(loginResp.user().username(), username);
    
    // 3. 使用 token 获取用户信息
    ApiClient authenticatedClient(config->openclawBaseUrl);
    authenticatedClient.setAuthToken(loginResp.token());
    
    auto userInfo = authenticatedClient.get("/api/auth/me");
    
    EXPECT_EQ(userInfo["code"].asInt(), 200);
    EXPECT_EQ(userInfo["data"]["username"].asString(), username);
}

TEST_F(AuthIntegrationTest, RefreshToken_Success) {
    // 1. 登录获取 token
    LoginResponse loginResp = authService->Login("testuser", "password123");
    ASSERT_TRUE(loginResp.success());
    
    std::string accessToken = loginResp.token();
    std::string refreshToken = loginResp.refreshToken();
    
    // 2. 刷新 token
    RefreshTokenResponse refreshResp = authService->RefreshToken(refreshToken);
    
    EXPECT_TRUE(refreshResp.success());
    EXPECT_FALSE(refreshResp.token().empty());
    EXPECT_NE(refreshResp.token(), accessToken);
}
```

---

### eCAL 集成测试

**测试端到端通信** (`tests/integration/test_ecal_e2e.cpp`):
```cpp
#include <gtest/gtest.h>
#include <ecal/ecal.h>
#include "publisher_service.h"
#include "subscriber_service.h"

class EcalE2ETest : public ::testing::Test {
protected:
    void SetUp() override {
        eCAL::Initialize();
        
        publisher = std::make_unique<PublisherService>();
        subscriber = std::make_unique<SubscriberService>();
        
        receivedMessages.clear();
    }
    
    void TearDown() override {
        publisher.reset();
        subscriber.reset();
        eCAL::Finalize();
    }
    
    std::unique_ptr<PublisherService> publisher;
    std::unique_ptr<SubscriberService> subscriber;
    std::vector<std::string> receivedMessages;
};

TEST_F(EcalE2ETest, PublishSubscribe_EndToEnd) {
    // 1. 订阅主题
    subscriber->Subscribe("polyvault.test.e2e", 
        [this](const std::string& data) {
            receivedMessages.push_back(data);
        });
    
    // 2. 等待订阅者就绪
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // 3. 发布消息
    std::vector<std::string> testMessages = {
        "message_1",
        "message_2",
        "message_3",
    };
    
    for (const auto& msg : testMessages) {
        publisher->Publish("polyvault.test.e2e", msg);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    // 4. 等待消息传递
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // 5. 验证结果
    EXPECT_EQ(receivedMessages.size(), testMessages.size());
    
    for (size_t i = 0; i < testMessages.size(); ++i) {
        EXPECT_EQ(receivedMessages[i], testMessages[i]);
    }
}
```

---

## 🎬 E2E 测试

### Flutter 集成测试

#### 测试配置

**pubspec.yaml**:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  patrol: ^2.0.0  # E2E 测试框架
```

---

#### 测试示例

**测试登录流程** (`integration_test/login_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';
import 'package:polyvault/main.dart' as app;

void main() {
  patrolTest('Complete login flow', ($) async {
    // 启动应用
    await $.pumpWidgetAndSettle(app.main());
    
    // 1. 点击登录按钮
    await $.tap(find.byKey(Key('login_button')));
    await $.pumpAndSettle();
    
    // 2. 输入用户名
    await $.enterText(
      find.byKey(Key('username_field')),
      'testuser',
    );
    
    // 3. 输入密码
    await $.enterText(
      find.byKey(Key('password_field')),
      'password123',
    );
    
    // 4. 点击提交
    await $.tap(find.byKey(Key('submit_button')));
    await $.pumpAndSettle();
    
    // 5. 验证登录成功
    expect(find.byKey(Key('home_screen')), findsOneWidget);
    expect(find.text('欢迎回来，testuser'), findsOneWidget);
  });
  
  patrolTest('Login with invalid credentials shows error', ($) async {
    // 启动应用
    await $.pumpWidgetAndSettle(app.main());
    
    // 1. 进入登录页面
    await $.tap(find.byKey(Key('login_button')));
    await $.pumpAndSettle();
    
    // 2. 输入错误凭据
    await $.enterText(
      find.byKey(Key('username_field')),
      'wronguser',
    );
    await $.enterText(
      find.byKey(Key('password_field')),
      'wrongpassword',
    );
    
    // 3. 提交
    await $.tap(find.byKey(Key('submit_button')));
    await $.pumpAndSettle();
    
    // 4. 验证错误提示
    expect(find.text('用户名或密码错误'), findsOneWidget);
  });
}
```

---

**测试发帖流程** (`integration_test/create_post_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('Create a new post', ($) async {
    // 启动应用并登录
    await $.pumpWidgetAndSettle(app.main());
    await login($);
    
    // 1. 点击发帖按钮
    await $.tap(find.byKey(Key('create_post_button')));
    await $.pumpAndSettle();
    
    // 2. 输入标题
    await $.enterText(
      find.byKey(Key('post_title_field')),
      'Test Post Title',
    );
    
    // 3. 输入内容
    await $.enterText(
      find.byKey(Key('post_content_field')),
      'This is a test post content for E2E testing.',
    );
    
    // 4. 选择分类
    await $.tap(find.byKey(Key('category_dropdown')));
    await $.pumpAndSettle();
    await $.tap(find.text('科技数码').last);
    await $.pumpAndSettle();
    
    // 5. 添加话题
    await $.enterText(
      find.byKey(Key('topic_input')),
      '#测试',
    );
    
    // 6. 提交
    await $.tap(find.byKey(Key('submit_post_button')));
    await $.pumpAndSettle();
    
    // 7. 验证发帖成功
    expect(find.text('发布成功'), findsOneWidget);
    expect(find.text('Test Post Title'), findsOneWidget);
  });
}

Future<void> login(PatrolIntegrationTester $) async {
  await $.tap(find.byKey(Key('login_button')));
  await $.pumpAndSettle();
  
  await $.enterText(find.byKey(Key('username_field')), 'testuser');
  await $.enterText(find.byKey(Key('password_field')), 'password123');
  
  await $.tap(find.byKey(Key('submit_button')));
  await $.pumpAndSettle();
}
```

---

## ⚡ 性能测试

### 负载测试

#### 使用 k6 进行 API 负载测试

**测试脚本** (`tests/performance/api_load_test.js`):
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// 自定义指标
const errorRate = new Rate('errors');
const loginTime = new Trend('login_time');

// 测试配置
export const options = {
  stages: [
    { duration: '2m', target: 100 },   //  ramp up to 100 users
    { duration: '5m', target: 100 },   //  stay at 100 users
    { duration: '2m', target: 200 },   //  ramp up to 200 users
    { duration: '5m', target: 200 },   //  stay at 200 users
    { duration: '2m', target: 0 },     //  ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests should be below 500ms
    errors: ['rate<0.1'],              // error rate should be less than 10%
    login_time: ['p(95)<1000'],        // 95% of logins should be below 1s
  },
};

const BASE_URL = 'https://api.openclaw.ai';
const TEST_USERNAME = 'testuser';
const TEST_PASSWORD = 'password123';

export default function () {
  // 1. 登录
  const loginStart = Date.now();
  const loginRes = http.post(`${BASE_URL}/api/auth/login`, 
    JSON.stringify({
      username: TEST_USERNAME,
      password: TEST_PASSWORD,
    }),
    {
      headers: { 'Content-Type': 'application/json' },
    }
  );
  
  const loginDuration = Date.now() - loginStart;
  loginTime.add(loginDuration);
  
  check(loginRes, {
    'login status is 200': (r) => r.status === 200,
    'login returns token': (r) => JSON.parse(r.body).data.token !== undefined,
  });
  
  errorRate.add(loginRes.status !== 200);
  
  const token = JSON.parse(loginRes.body).data.token;
  
  sleep(1);
  
  // 2. 获取帖子列表
  const postsRes = http.get(`${BASE_URL}/api/posts?limit=20`, {
    headers: {
      'Authorization': `Bearer ${token}`,
    },
  });
  
  check(postsRes, {
    'get posts status is 200': (r) => r.status === 200,
  });
  
  errorRate.add(postsRes.status !== 200);
  
  sleep(1);
  
  // 3. 创建帖子
  const createPostRes = http.post(`${BASE_URL}/api/posts`,
    JSON.stringify({
      title: 'Performance Test Post',
      content: 'This is a test post created during performance testing.',
      category_id: 1,
    }),
    {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    }
  );
  
  check(createPostRes, {
    'create post status is 201': (r) => r.status === 201,
  });
  
  errorRate.add(createPostRes.status !== 201);
  
  sleep(2);
}
```

**运行测试**:
```bash
# 运行负载测试
k6 run tests/performance/api_load_test.js

# 运行并生成 HTML 报告
k6 run --out json=results.json tests/performance/api_load_test.js
k6-to-junit results.json > results.xml
```

---

### eCAL 性能测试

**测试消息吞吐量** (`tests/performance/test_ecal_throughput.cpp`):
```cpp
#include <iostream>
#include <chrono>
#include <atomic>
#include <ecal/ecal.h>
#include "publisher.h"
#include "subscriber.h"

class EcalPerformanceTest {
public:
    void RunThroughputTest() {
        eCAL::Initialize();
        
        const int MESSAGE_COUNT = 10000;
        const int MESSAGE_SIZE = 1024; // 1KB
        
        std::atomic<int> receivedCount(0);
        
        // 创建订阅者
        eCAL::CSubscriber subscriber("polyvault.performance.test");
        subscriber.AddReceiveCallback([&receivedCount](const char* topic_name, 
                                                        const std::shared_ptr<eCAL::CMessage>& msg) {
            receivedCount++;
        });
        
        // 创建发布者
        eCAL::CPublisher publisher("polyvault.performance.test");
        
        // 等待订阅者就绪
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        
        // 准备消息数据
        std::string messageData(MESSAGE_SIZE, 'x');
        
        // 开始测试
        auto startTime = std::chrono::high_resolution_clock::now();
        
        for (int i = 0; i < MESSAGE_COUNT; ++i) {
            publisher.Send(messageData.c_str(), messageData.size());
        }
        
        // 等待所有消息接收完成
        while (receivedCount < MESSAGE_COUNT) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
        
        auto endTime = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - startTime);
        
        // 计算性能指标
        double throughput = (MESSAGE_COUNT * MESSAGE_SIZE) / (duration.count() / 1000.0) / 1024.0 / 1024.0; // MB/s
        double messagesPerSecond = MESSAGE_COUNT / (duration.count() / 1000.0);
        
        std::cout << "Performance Test Results:" << std::endl;
        std::cout << "  Messages sent: " << MESSAGE_COUNT << std::endl;
        std::cout << "  Message size: " << MESSAGE_SIZE << " bytes" << std::endl;
        std::cout << "  Total time: " << duration.count() << " ms" << std::endl;
        std::cout << "  Throughput: " << throughput << " MB/s" << std::endl;
        std::cout << "  Messages/sec: " << messagesPerSecond << std::endl;
        
        eCAL::Finalize();
    }
};

int main() {
    EcalPerformanceTest test;
    test.RunThroughputTest();
    return 0;
}
```

---

## 🔒 安全测试

### 渗透测试

#### OWASP Top 10 测试清单

**1. 注入攻击测试**:
```bash
# SQL 注入测试
sqlmap -u "https://api.openclaw.ai/api/posts?id=1" \
       --headers="Authorization: Bearer <token>" \
       --dbs

# XSS 测试
curl -X POST https://api.openclaw.ai/api/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"title":"<script>alert(1)</script>","content":"test"}'
```

**2. 认证测试**:
```bash
# 暴力破解测试
hydra -l testuser -P /usr/share/wordlists/rockyou.txt \
      https-post-form "/api/auth/login:username=^USER^&password=^PASS^:F=Invalid" \
      api.openclaw.ai
```

**3. 敏感数据泄露测试**:
```bash
# 检查响应头
curl -I https://api.openclaw.ai/api/auth/me \
  -H "Authorization: Bearer <token>"

# 检查是否泄露敏感信息
curl https://api.openclaw.ai/api/users/1 \
  -H "Authorization: Bearer <token>"
```

---

### 安全扫描

#### 使用 OWASP ZAP

**自动化扫描脚本**:
```bash
# 启动 ZAP 容器
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t https://api.openclaw.ai \
  -r zap_report.html

# 完整扫描
docker run -t owasp/zap2docker-stable zap-full-scan.py \
  -t https://api.openclaw.ai \
  -r zap_full_report.html
```

---

## 🔌 FFI Binding 测试

### Rust FFI Binding 测试

#### 测试 FFI 初始化

```rust
// tests/test_ffi_initialization.rs
use polyvault_rust::ecal::{Publisher, Subscriber};
use polyvault_rust::ffi;

#[test]
fn test_ecal_initialization() {
    unsafe {
        let result = ffi::ecal_initialize(
            std::ptr::null(),
            b"Test App\0".as_ptr() as *const _
        );
        assert_eq!(result, 0, "eCAL initialization failed");
        
        ffi::ecal_finalize();
    }
}

#[test]
fn test_publisher_creation() {
    unsafe {
        ffi::ecal_initialize(std::ptr::null(), b"Test\0".as_ptr() as *const _);
        
        let publisher = Publisher::new("test/topic");
        assert!(publisher.is_ok(), "Failed to create publisher");
        
        ffi::ecal_finalize();
    }
}

#[test]
fn test_publish_subscribe() {
    use std::sync::{Arc, Mutex};
    use std::thread;
    use std::time::Duration;
    
    unsafe {
        ffi::ecal_initialize(std::ptr::null(), b"Test\0".as_ptr() as *const _);
    }
    
    let received = Arc::new(Mutex::new(Vec::new()));
    let received_clone = Arc::clone(&received);
    
    // 创建订阅者
    let _subscriber = Subscriber::new("test/topic", move |_topic, data, _ts| {
        let mut guard = received_clone.lock().unwrap();
        guard.push(String::from_utf8_lossy(data).to_string());
    }).unwrap();
    
    // 等待订阅者就绪
    thread::sleep(Duration::from_millis(500));
    
    // 创建发布者并发送消息
    let publisher = Publisher::new("test/topic").unwrap();
    publisher.write_string("Hello, FFI!").unwrap();
    
    // 等待消息传递
    thread::sleep(Duration::from_millis(500));
    
    // 验证
    let guard = received.lock().unwrap();
    assert_eq!(guard.len(), 1);
    assert_eq!(guard[0], "Hello, FFI!");
    
    unsafe {
        ffi::ecal_finalize();
    }
}
```

---

### Python FFI Binding 测试

```python
# tests/test_python_ffi.py
import unittest
import time
from polyvault.ecal import Publisher, initialize, finalize

class TestPythonFFI(unittest.TestCase):
    def setUp(self):
        initialize("Python FFI Test")
    
    def tearDown(self):
        finalize()
    
    def test_publisher_creation(self):
        """测试发布者创建"""
        publisher = Publisher("test/topic")
        self.assertIsNotNone(publisher)
    
    def test_publish_message(self):
        """测试发布消息"""
        publisher = Publisher("test/topic")
        publisher.write_string("Test message")
        # 验证不抛出异常
    
    def test_publish_multiple_messages(self):
        """测试批量发布"""
        publisher = Publisher("test/topic")
        
        for i in range(10):
            publisher.write_string(f"Message {i}")
            time.sleep(0.1)
        
        # 验证所有消息发送成功

if __name__ == '__main__':
    unittest.main()
```

---

## 🔌 插件测试

### C++ 插件测试

#### 测试插件生命周期

```cpp
// tests/test_plugin_lifecycle.cpp
#include <gtest/gtest.h>
#include <polyvault/test.h>
#include "../src/plugin.h"

class PluginLifecycleTest : public ::testing::Test {
protected:
    void SetUp() override {
        test_env = polyvault::test::createTestEnvironment();
        test_env->start();
    }
    
    void TearDown() override {
        test_env->stop();
    }
    
    std::unique_ptr<polyvault::test::TestEnvironment> test_env;
};

TEST_F(PluginLifecycleTest, LoadPlugin_Success) {
    // 加载插件
    auto plugin = test_env->loadPlugin("com.example.test-plugin");
    
    // 验证加载成功
    ASSERT_NE(plugin, nullptr);
}

TEST_F(PluginLifecycleTest, StartPlugin_Success) {
    // 加载并启动插件
    auto plugin = test_env->loadPlugin("com.example.test-plugin");
    ASSERT_NE(plugin, nullptr);
    
    auto result = test_env->startPlugin(plugin);
    EXPECT_TRUE(result.isSuccess());
}

TEST_F(PluginLifecycleTest, StopPlugin_Success) {
    // 加载、启动并停止插件
    auto plugin = test_env->loadPlugin("com.example.test-plugin");
    test_env->startPlugin(plugin);
    
    auto result = test_env->stopPlugin(plugin);
    EXPECT_TRUE(result.isSuccess());
}

TEST_F(PluginLifecycleTest, UnloadPlugin_Success) {
    // 完整生命周期测试
    auto plugin = test_env->loadPlugin("com.example.test-plugin");
    test_env->startPlugin(plugin);
    test_env->stopPlugin(plugin);
    
    auto result = test_env->unloadPlugin(plugin);
    EXPECT_TRUE(result.isSuccess());
}
```

---

### 插件能力测试

```cpp
// tests/test_plugin_capabilities.cpp
#include <gtest/gtest.h>
#include <polyvault/test.h>

class PluginCapabilitiesTest : public ::testing::Test {
protected:
    void SetUp() override {
        test_env = polyvault::test::createTestEnvironment();
        test_env->start();
        
        // 加载并启动插件
        plugin = test_env->loadPlugin("com.example.credential-provider");
        test_env->startPlugin(plugin);
    }
    
    void TearDown() override {
        test_env->stop();
    }
    
    std::unique_ptr<polyvault::test::TestEnvironment> test_env;
    std::shared_ptr<polyvault::IPlugin> plugin;
};

TEST_F(PluginCapabilitiesTest, RegisterCapability_Success) {
    // 验证插件注册了能力
    auto capabilities = test_env->listCapabilities();
    
    bool found = std::any_of(capabilities.begin(), capabilities.end(),
        [](const auto& cap) {
            return cap.name == "credential_provider";
        });
    
    EXPECT_TRUE(found);
}

TEST_F(PluginCapabilitiesTest, HandleCredentialRequest_Success) {
    // 发送凭证请求事件
    polyvault::Event request("credential/request");
    request.setData(polyvault::CredentialRequest{
        .service_url = "https://example.com",
    });
    
    // 发布事件
    test_env->eventBus().publish("credential/request", request);
    
    // 等待处理
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // 验证响应
    auto responses = test_env->eventBus().getPublishedEvents("credential/response");
    EXPECT_GT(responses.size(), 0);
}
```

---

### Flutter 插件测试

```dart
// tests/test_flutter_plugin.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:polyvault_sdk/polyvault_sdk.dart';
import 'package:mockito/mockito.dart';
import 'mocks.dart';

void main() {
  group('Flutter Plugin Tests', () {
    late MyPlugin plugin;
    late MockContext mockContext;
    
    setUp(() {
      mockContext = MockContext();
      plugin = MyPlugin();
    });
    
    test('metadata returns correct info', () {
      final metadata = plugin.metadata;
      
      expect(metadata.id, 'com.example.my-plugin');
      expect(metadata.name, 'My Plugin');
      expect(metadata.version, '1.0.0');
    });
    
    test('onLoad initializes correctly', () async {
      when(mockContext.config).thenReturn(MockConfig());
      
      final result = await plugin.onLoad(mockContext);
      
      expect(result.isSuccess, true);
    });
    
    test('onStart subscribes to events', () async {
      await plugin.onLoad(mockContext);
      
      final result = await plugin.onStart();
      
      expect(result.isSuccess, true);
      verify(mockContext.eventBus.subscribe('credential/request', any)).called(1);
    });
    
    test('handleEvent processes credential request', () async {
      await plugin.onLoad(mockContext);
      await plugin.onStart();
      
      final event = Event(
        type: 'credential/request',
        data: CredentialRequest(serviceUrl: 'https://example.com'),
      );
      
      final result = await plugin.handleEvent(event);
      
      expect(result.isSuccess, true);
    });
  });
}
```

---

### 插件集成测试

```cpp
// tests/plugin_integration_test.cpp
#include <gtest/gtest.h>
#include <polyvault/test.h>

class PluginIntegrationTest : public ::testing::Test {
protected:
    void SetUp() override {
        test_env = polyvault::test::createTestEnvironment();
        test_env->start();
    }
    
    void TearDown() override {
        test_env->stop();
    }
    
    std::unique_ptr<polyvault::test::TestEnvironment> test_env;
};

TEST_F(PluginIntegrationTest, FullPluginWorkflow) {
    // 1. 加载插件
    auto plugin = test_env->loadPlugin("com.example.full-plugin");
    ASSERT_NE(plugin, nullptr);
    
    // 2. 启动插件
    auto start_result = test_env->startPlugin(plugin);
    EXPECT_TRUE(start_result.isSuccess());
    
    // 3. 验证能力注册
    auto capabilities = test_env->listCapabilities();
    EXPECT_GT(capabilities.size(), 0);
    
    // 4. 发送测试事件
    polyvault::Event test_event("test/event");
    test_env->eventBus().publish("test/event", test_event);
    
    // 5. 验证事件处理
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    auto events = test_env->eventBus().getPublishedEvents("test/response");
    EXPECT_GT(events.size(), 0);
    
    // 6. 停止插件
    auto stop_result = test_env->stopPlugin(plugin);
    EXPECT_TRUE(stop_result.isSuccess());
    
    // 7. 卸载插件
    auto unload_result = test_env->unloadPlugin(plugin);
    EXPECT_TRUE(unload_result.isSuccess());
}
```

---

## 📊 测试覆盖率

### C++ 代码覆盖率

**使用 gcov/lcov**:

```bash
# 编译时启用覆盖率
cmake .. -DCMAKE_BUILD_TYPE=Debug -DCODE_COVERAGE=ON

# 运行测试
ctest

# 生成覆盖率报告
lcov --capture --directory . --output-file coverage.info
lcov --remove coverage.info '/usr/*' '*/tests/*' --output-file coverage.info
genhtml coverage.info --output-directory coverage_report

# 查看报告
# 打开 coverage_report/index.html
```

**覆盖率目标**:
- 行覆盖率：≥ 80%
- 分支覆盖率：≥ 70%
- 函数覆盖率：≥ 90%

---

### Dart/Flutter 代码覆盖率

```bash
# 运行测试并生成覆盖率
flutter test --coverage

# 生成 HTML 报告
genhtml coverage/lcov.info --output-directory coverage/html

# 查看报告
# 打开 coverage/html/index.html

# 生成覆盖率徽章
lcov-summary coverage/lcov.info
```

**覆盖率目标**:
- 行覆盖率：≥ 80%
- 分支覆盖率：≥ 70%

---

## 🔄 持续集成

### GitHub Actions CI/CD

**.github/workflows/ci.yml**:
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  # C++ Agent 测试
  agent-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y \
          build-essential \
          cmake \
          libprotobuf-dev \
          protobuf-compiler \
          libecal5
    
    - name: Configure CMake
      run: cmake -B build -DCMAKE_BUILD_TYPE=Debug
    
    - name: Build
      run: cmake --build build
    
    - name: Run tests
      run: ctest --test-dir build --output-on-failure
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./build/coverage.info
        flags: agent

  # Flutter 客户端测试
  flutter-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    
    - name: Install dependencies
      run: flutter pub get
      working-directory: client
    
    - name: Run tests
      run: flutter test --coverage
      working-directory: client
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./client/coverage/lcov.info
        flags: client

  # 构建测试
  build-test:
    runs-on: ubuntu-latest
    needs: [agent-tests, flutter-tests]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: docker build -t polyvault-agent:latest .
    
    - name: Test Docker image
      run: docker run --rm polyvault-agent:latest --version

  # 部署（仅 main 分支）
  deploy:
    runs-on: ubuntu-latest
    needs: build-test
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to production
      run: |
        # 部署脚本
        echo "Deploying to production..."
```

---

## 📋 测试报告模板

### 测试执行报告

**测试报告示例**:
```markdown
# PolyVault 测试报告

**测试周期**: 2026-03-14  
**测试版本**: v1.0.0  
**测试人员**: QA Team

---

## 测试概况

| 指标 | 数量 | 通过率 |
|------|------|--------|
| **总测试用例** | 250 | - |
| **通过** | 245 | 98% |
| **失败** | 3 | 1.2% |
| **跳过** | 2 | 0.8% |

---

## 测试覆盖率

| 模块 | 行覆盖率 | 分支覆盖率 | 函数覆盖率 |
|------|---------|-----------|-----------|
| **C++ Agent** | 85% | 78% | 92% |
| **Flutter 客户端** | 82% | 75% | 90% |
| **总体** | 83.5% | 76.5% | 91% |

---

## 缺陷统计

| 严重程度 | 新增 | 已修复 | 遗留 |
|---------|------|--------|------|
| **严重** | 2 | 2 | 0 |
| **一般** | 8 | 7 | 1 |
| **轻微** | 15 | 12 | 3 |

---

## 性能测试结果

| 指标 | 目标值 | 实测值 | 状态 |
|------|--------|--------|------|
| **API P95 延迟** | < 500ms | 320ms | ✅ |
| **eCAL 吞吐量** | > 10MB/s | 15.2MB/s | ✅ |
| **并发用户数** | > 200 | 200 | ✅ |
| **错误率** | < 0.1% | 0.05% | ✅ |

---

## 风险评估

### 高风险问题
- 无

### 中风险问题
- 遗留 1 个一般缺陷（ID: BUG-123）

### 低风险问题
- 遗留 3 个轻微缺陷

---

## 测试结论

✅ **测试通过**

所有关键测试用例通过，代码覆盖率达标，性能指标满足要求。
建议修复遗留缺陷后发布。

---

**测试负责人**: QA Lead  
**批准人**: Project Manager  
**日期**: 2026-03-14
```

---

## 📞 联系方式

**测试问题咨询**:
- 邮箱：`qa@polyvault.io`
- 内部频道：PolyVault QA 群组

**缺陷报告**:
- 系统：GitHub Issues
- 标签：`bug`, `test-failure`

---

**文档维护**: PolyVault QA 团队  
**反馈邮箱**: qa@polyvault.io  
**最后更新**: 2026-03-14
