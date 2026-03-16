# PolyVault Agent 端开发指南

**版本**: v1.0  
**创建时间**: 2026-03-15  
**适用对象**: Agent 开发者、OpenClaw 集成工程师

---

## 📖 目录

1. [概述](#概述)
2. [Agent 架构](#agent-架构)
3. [OpenClaw 集成](#openclaw-集成)
4. [消息处理](#消息处理)
5. [密码箱操作](#密码箱操作)
6. [ACP 通信](#acp-通信)
7. [Subagents 集成](#subagents-集成)
8. [错误处理](#错误处理)
9. [测试与调试](#测试与调试)
10. [部署指南](#部署指南)

---

## 🎯 概述

### PolyVault Agent 角色

PolyVault Agent 是运行在 OpenClaw 平台上的智能代理，负责：

- 🔐 **密码箱管理**: 安全存储和检索凭证
- 🔄 **消息处理**: 处理用户请求和系统事件
- 🤖 **自动化**: 自动填充、自动登录、凭证轮换
- 🔗 **集成**: 与浏览器扩展、Flutter 客户端、第三方服务集成

### Agent 类型

| 类型 | 用途 | 运行位置 |
|------|------|----------|
| **Vault Agent** | 密码箱核心管理 | OpenClaw 主节点 |
| **Sync Agent** | 多设备同步 | OpenClaw 边缘节点 |
| **Monitor Agent** | 安全监控与告警 | OpenClaw 监控节点 |
| **Integration Agent** | 第三方服务集成 | OpenClaw 集成节点 |

---

## 🏗️ Agent 架构

### 系统架构图

```
┌─────────────────────────────────────────────────────────┐
│                    OpenClaw Platform                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              PolyVault Agent                     │   │
│  ├─────────────────────────────────────────────────┤   │
│  │                                                  │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐      │   │
│  │  │ Message  │  │  Vault   │  │  Plugin  │      │   │
│  │  │ Handler  │  │ Manager  │  │ Manager  │      │   │
│  │  └──────────┘  └──────────┘  └──────────┘      │   │
│  │       │              │              │           │   │
│  │       └──────────────┴──────────────┘           │   │
│  │                      │                          │   │
│  │               ┌──────┴──────┐                   │   │
│  │               │   Core API  │                   │   │
│  │               │  (eCAL)     │                   │   │
│  │               └─────────────┘                   │   │
│  │                                                  │   │
│  └─────────────────────────────────────────────────┘   │
│                         │                               │
│  ┌──────────────────────┼──────────────────────┐       │
│  │                      │                      │       │
│  ▼                      ▼                      ▼       │
│ ┌──────────┐     ┌──────────┐     ┌──────────┐        │
│ │ Browser  │     Flutter   │     3rd Party   │        │
│ │Extension │     │ Client   │     │  Services │        │
│ └──────────┘     └──────────┘     └──────────┘        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 核心组件

```typescript
// src/agent/polyvault-agent.ts
import { Agent, Context, Message } from '@openclaw/core';
import { VaultManager } from './vault/manager';
import { MessageHandler } from './messages/handler';
import { PluginManager } from './plugins/manager';
import { EcalClient } from './ecal/client';

export class PolyVaultAgent extends Agent {
  private vaultManager: VaultManager;
  private messageHandler: MessageHandler;
  private pluginManager: PluginManager;
  private ecalClient: EcalClient;
  
  constructor(context: Context) {
    super(context);
    
    // 初始化组件
    this.vaultManager = new VaultManager();
    this.messageHandler = new MessageHandler();
    this.pluginManager = new PluginManager();
    this.ecalClient = new EcalClient();
  }
  
  /**
   * Agent 启动
   */
  async onStart(): Promise<void> {
    this.logger.info('🚀 PolyVault Agent starting...');
    
    // 1. 初始化 eCAL 客户端
    await this.ecalClient.initialize({
      appName: 'PolyVault-Agent',
      configPath: this.config.ecalConfigPath,
    });
    
    // 2. 加载密码箱
    await this.vaultManager.load({
      storagePath: this.config.vaultStoragePath,
      encryptionKey: this.config.masterKey,
    });
    
    // 3. 加载插件
    await this.pluginManager.loadPlugins();
    
    // 4. 注册消息处理器
    this.registerMessageHandlers();
    
    this.logger.info('✅ PolyVault Agent started successfully');
  }
  
  /**
   * Agent 停止
   */
  async onStop(): Promise<void> {
    this.logger.info('🛑 PolyVault Agent stopping...');
    
    // 1. 保存密码箱
    await this.vaultManager.save();
    
    // 2. 卸载插件
    await this.pluginManager.unloadPlugins();
    
    // 3. 关闭 eCAL
    await this.ecalClient.shutdown();
    
    this.logger.info('✅ PolyVault Agent stopped');
  }
  
  /**
   * 处理消息
   */
  async onMessage(message: Message): Promise<void> {
    await this.messageHandler.handle(message, {
      vault: this.vaultManager,
      ecal: this.ecalClient,
      plugins: this.pluginManager,
    });
  }
  
  /**
   * 注册消息处理器
   */
  private registerMessageHandlers(): void {
    // 凭证相关
    this.messageHandler.register('vault/get', this.handleGetCredential.bind(this));
    this.messageHandler.register('vault/store', this.handleStoreCredential.bind(this));
    this.messageHandler.register('vault/delete', this.handleDeleteCredential.bind(this));
    this.messageHandler.register('vault/list', this.handleListCredentials.bind(this));
    
    // 同步相关
    this.messageHandler.register('sync/request', this.handleSyncRequest.bind(this));
    this.messageHandler.register('sync/apply', this.handleSyncApply.bind(this));
    
    // 插件相关
    this.messageHandler.register('plugin/load', this.handleLoadPlugin.bind(this));
    this.messageHandler.register('plugin/unload', this.handleUnloadPlugin.bind(this));
    this.messageHandler.register('plugin/invoke', this.handleInvokePlugin.bind(this));
  }
  
  // ... 消息处理方法
}
```

---

## 🔌 OpenClaw 集成

### 1. Agent 配置

```yaml
# config/polyvault-agent.yaml
agent:
  id: polyvault-vault-agent
  name: PolyVault Vault Agent
  version: 1.0.0
  description: PolyVault password vault management agent
  
# eCAL 配置
ecal:
  config_path: /etc/polyvault/ecal.ini
  topics:
    vault_request: polyvault.vault.request
    vault_response: polyvault.vault.response
    sync_events: polyvault.sync.events
  
# 密码箱配置
vault:
  storage_path: /var/lib/polyvault/vault.db
  encryption:
    algorithm: aes-256-gcm
    key_derivation: argon2id
    iterations: 3
  
# 插件配置
plugins:
  enabled:
    - auto-fill
    - password-generator
    - breach-monitor
  config:
    auto-fill:
      delay_ms: 100
      match_threshold: 0.8
    password-generator:
      default_length: 16
      include_symbols: true
    breach-monitor:
      check_interval_hours: 24
      api_endpoint: https://haveibeenpwned.com/api

# 日志配置
logging:
  level: info
  format: json
  output:
    - file:/var/log/polyvault/agent.log
    - stdout
  
# 监控配置
monitoring:
  enabled: true
  metrics_port: 9090
  health_check_port: 8080
```

---

### 2. 消息系统

#### 消息格式

```typescript
// src/messages/types.ts
export interface Message {
  id: string;
  type: string;
  timestamp: number;
  sender: string;
  recipient?: string;
  data: any;
  metadata?: {
    priority?: 'low' | 'normal' | 'high' | 'urgent';
    timeout?: number;
    correlationId?: string;
    replyTo?: string;
  };
}

export interface CredentialRequest {
  serviceUrl: string;
  fields?: string[];
  autoFill?: boolean;
}

export interface CredentialResponse {
  success: boolean;
  credential?: Credential;
  error?: string;
}

export interface Credential {
  id: string;
  serviceUrl: string;
  username: string;
  password: string;
  totp?: string;
  notes?: string;
  tags?: string[];
  createdAt: number;
  updatedAt: number;
}
```

---

#### 消息处理器

```typescript
// src/messages/handler.ts
import { Message, MessageContext } from './types';
import { VaultManager } from '../vault/manager';
import { EcalClient } from '../ecal/client';

type MessageHandlerFn = (
  message: Message,
  context: MessageContext
) => Promise<any>;

export class MessageHandler {
  private handlers: Map<string, MessageHandlerFn> = new Map();
  
  /**
   * 注册消息处理器
   */
  register(type: string, handler: MessageHandlerFn): void {
    this.handlers.set(type, handler);
  }
  
  /**
   * 处理消息
   */
  async handle(message: Message, context: MessageContext): Promise<any> {
    const handler = this.handlers.get(message.type);
    
    if (!handler) {
      throw new Error(`Unknown message type: ${message.type}`);
    }
    
    try {
      const result = await handler(message, context);
      
      // 发送响应
      if (message.metadata?.replyTo) {
        await this.sendResponse(message, result);
      }
      
      return result;
    } catch (error) {
      // 发送错误响应
      if (message.metadata?.replyTo) {
        await this.sendError(message, error);
      }
      
      throw error;
    }
  }
  
  /**
   * 发送响应
   */
  private async sendResponse(originalMessage: Message, data: any): Promise<void> {
    const response: Message = {
      id: this.generateId(),
      type: `${originalMessage.type}/response`,
      timestamp: Date.now(),
      sender: 'polyvault-agent',
      recipient: originalMessage.sender,
      data: data,
      metadata: {
        correlationId: originalMessage.id,
        replyTo: originalMessage.id,
      },
    };
    
    // 通过 eCAL 发送
    await context.ecal.publish('polyvault.vault.response', response);
  }
  
  /**
   * 发送错误响应
   */
  private async sendError(originalMessage: Message, error: Error): Promise<void> {
    const response: Message = {
      id: this.generateId(),
      type: `${originalMessage.type}/error`,
      timestamp: Date.now(),
      sender: 'polyvault-agent',
      recipient: originalMessage.sender,
      data: {
        error: error.message,
        code: this.getErrorCode(error),
      },
      metadata: {
        correlationId: originalMessage.id,
        replyTo: originalMessage.id,
      },
    };
    
    await context.ecal.publish('polyvault.vault.response', response);
  }
  
  private generateId(): string {
    return `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  private getErrorCode(error: Error): string {
    // 映射错误码
    if (error.message.includes('not found')) return 'NOT_FOUND';
    if (error.message.includes('permission')) return 'FORBIDDEN';
    if (error.message.includes('timeout')) return 'TIMEOUT';
    return 'INTERNAL_ERROR';
  }
}
```

---

## 🔐 密码箱操作

### 1. 密码箱管理器

```typescript
// src/vault/manager.ts
import { Credential, VaultConfig } from './types';
import { CryptoService } from '../crypto/service';
import { StorageAdapter } from '../storage/adapter';

export class VaultManager {
  private credentials: Map<string, Credential> = new Map();
  private cryptoService: CryptoService;
  private storageAdapter: StorageAdapter;
  private isLocked: boolean = true;
  
  constructor() {
    this.cryptoService = new CryptoService();
    this.storageAdapter = new StorageAdapter();
  }
  
  /**
   * 加载密码箱
   */
  async load(config: VaultConfig): Promise<void> {
    // 读取加密的数据库
    const encryptedData = await this.storageAdapter.read(config.storagePath);
    
    // 使用主密钥解密
    const decryptedData = await this.cryptoService.decrypt(
      encryptedData,
      config.encryptionKey
    );
    
    // 解析凭证
    const credentials = JSON.parse(decryptedData);
    this.credentials = new Map(
      credentials.map((c: Credential) => [c.id, c])
    );
    
    this.isLocked = false;
  }
  
  /**
   * 保存密码箱
   */
  async save(): Promise<void> {
    if (this.isLocked) return;
    
    // 序列化凭证
    const data = JSON.stringify(Array.from(this.credentials.values()));
    
    // 加密
    const encryptedData = await this.cryptoService.encrypt(
      data,
      this.config.encryptionKey
    );
    
    // 写入存储
    await this.storageAdapter.write(this.config.storagePath, encryptedData);
  }
  
  /**
   * 获取凭证
   */
  async getCredential(serviceUrl: string): Promise<Credential | null> {
    // 模糊匹配服务 URL
    const credential = this.findCredentialByUrl(serviceUrl);
    
    if (!credential) return null;
    
    // 审计日志
    await this.auditLog('GET', credential.id);
    
    return credential;
  }
  
  /**
   * 存储凭证
   */
  async storeCredential(credential: Credential): Promise<void> {
    // 检查是否已存在
    const existing = this.findCredentialByUrl(credential.serviceUrl);
    
    if (existing) {
      // 更新现有凭证
      credential.id = existing.id;
      credential.createdAt = existing.createdAt;
      this.credentials.set(existing.id, credential);
    } else {
      // 创建新凭证
      credential.id = this.generateId();
      credential.createdAt = Date.now();
      credential.updatedAt = Date.now();
      this.credentials.set(credential.id, credential);
    }
    
    // 审计日志
    await this.auditLog(existing ? 'UPDATE' : 'CREATE', credential.id);
  }
  
  /**
   * 删除凭证
   */
  async deleteCredential(id: string): Promise<boolean> {
    const deleted = this.credentials.delete(id);
    
    if (deleted) {
      await this.auditLog('DELETE', id);
    }
    
    return deleted;
  }
  
  /**
   * 列出所有凭证
   */
  listCredentials(): Credential[] {
    return Array.from(this.credentials.values()).map(c => ({
      ...c,
      password: undefined, // 不返回密码
    }));
  }
  
  /**
   * 搜索凭证
   */
  searchCredentials(query: string): Credential[] {
    const lowerQuery = query.toLowerCase();
    
    return Array.from(this.credentials.values()).filter(c =>
      c.serviceUrl.toLowerCase().includes(lowerQuery) ||
      c.username.toLowerCase().includes(lowerQuery) ||
      c.tags?.some(tag => tag.toLowerCase().includes(lowerQuery))
    );
  }
  
  /**
   * 模糊匹配服务 URL
   */
  private findCredentialByUrl(url: string): Credential | null {
    const urlObj = new URL(url);
    const domain = urlObj.hostname;
    
    // 精确匹配
    for (const credential of this.credentials.values()) {
      const credUrl = new URL(credential.serviceUrl);
      if (credUrl.hostname === domain) {
        return credential;
      }
    }
    
    // 通配符匹配（*.example.com）
    for (const credential of this.credentials.values()) {
      if (this.domainMatches(domain, credential.serviceUrl)) {
        return credential;
      }
    }
    
    return null;
  }
  
  private domainMatches(domain: string, pattern: string): boolean {
    // 实现域名匹配逻辑
    return false;
  }
  
  private generateId(): string {
    return `cred_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  private async auditLog(action: string, credentialId: string): Promise<void> {
    // 记录审计日志
    console.log(`[AUDIT] ${action} credential ${credentialId} at ${new Date().toISOString()}`);
  }
}
```

---

## 🔄 ACP 通信

### 1. ACP 客户端

```typescript
// src/acp/client.ts
import { AcpMessage, AcpResponse } from './types';

export class AcpClient {
  private sessionId: string | null = null;
  private messageQueue: AcpMessage[] = [];
  private pendingRequests: Map<string, {
    resolve: (response: AcpResponse) => void;
    reject: (error: Error) => void;
    timeout: NodeJS.Timeout;
  }> = new Map();
  
  /**
   * 建立 ACP 连接
   */
  async connect(config: {
    host: string;
    port: number;
    agentId: string;
  }): Promise<void> {
    // 实现 ACP 连接逻辑
    this.sessionId = `session_${Date.now()}`;
    
    // 启动消息循环
    this.startMessageLoop();
  }
  
  /**
   * 发送请求
   */
  async request(message: AcpMessage): Promise<AcpResponse> {
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.pendingRequests.delete(message.id);
        reject(new Error('Request timeout'));
      }, message.metadata?.timeout || 30000);
      
      this.pendingRequests.set(message.id, { resolve, reject, timeout });
      this.messageQueue.push(message);
      this.flushQueue();
    });
  }
  
  /**
   * 发布事件
   */
  async publish(topic: string, data: any): Promise<void> {
    const message: AcpMessage = {
      id: this.generateId(),
      type: 'event',
      topic: topic,
      data: data,
      timestamp: Date.now(),
    };
    
    this.messageQueue.push(message);
    this.flushQueue();
  }
  
  /**
   * 订阅主题
   */
  async subscribe(topic: string, callback: (data: any) => void): Promise<void> {
    // 实现订阅逻辑
  }
  
  /**
   * 取消订阅
   */
  async unsubscribe(topic: string): Promise<void> {
    // 实现取消订阅逻辑
  }
  
  private startMessageLoop(): void {
    // 实现消息循环
  }
  
  private flushQueue(): void {
    // 刷新消息队列
  }
  
  private generateId(): string {
    return `acp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}
```

---

## 🤖 Subagents 集成

### 1. Subagent 管理

```typescript
// src/subagents/manager.ts
import { SubagentConfig, SubagentStatus } from './types';

export class SubagentManager {
  private subagents: Map<string, SubagentInstance> = new Map();
  
  /**
   * 生成 Subagent
   */
  async spawn(config: SubagentConfig): Promise<string> {
    const subagentId = `subagent_${Date.now()}`;
    
    // 创建子进程
    const process = spawn('node', [
      '--loader=ts-node/esm',
      'src/subagents/worker.ts',
      `--id=${subagentId}`,
      `--config=${JSON.stringify(config)}`,
    ]);
    
    // 保存实例
    this.subagents.set(subagentId, {
      id: subagentId,
      config: config,
      process: process,
      status: 'starting',
    });
    
    // 监听进程事件
    process.on('message', (msg) => this.handleSubagentMessage(subagentId, msg));
    process.on('exit', (code) => this.handleSubagentExit(subagentId, code));
    
    return subagentId;
  }
  
  /**
   * 停止 Subagent
   */
  async kill(subagentId: string): Promise<void> {
    const subagent = this.subagents.get(subagentId);
    
    if (!subagent) {
      throw new Error(`Subagent not found: ${subagentId}`);
    }
    
    // 发送停止信号
    subagent.process.send({ type: 'stop' });
    
    // 等待优雅关闭
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // 强制终止
    if (subagent.process.exitCode === null) {
      subagent.process.kill('SIGKILL');
    }
    
    this.subagents.delete(subagentId);
  }
  
  /**
   * 向 Subagent 发送消息
   */
  async send(subagentId: string, message: any): Promise<void> {
    const subagent = this.subagents.get(subagentId);
    
    if (!subagent) {
      throw new Error(`Subagent not found: ${subagentId}`);
    }
    
    subagent.process.send(message);
  }
  
  /**
   * 获取 Subagent 状态
   */
  getStatus(subagentId: string): SubagentStatus {
    const subagent = this.subagents.get(subagentId);
    
    if (!subagent) {
      throw new Error(`Subagent not found: ${subagentId}`);
    }
    
    return {
      id: subagent.id,
      status: subagent.status,
      uptime: process.uptime(),
      memory: process.memoryUsage(),
    };
  }
  
  /**
   * 列出所有 Subagent
   */
  listSubagents(): SubagentStatus[] {
    return Array.from(this.subagents.values()).map(sa => this.getStatus(sa.id));
  }
  
  private handleSubagentMessage(subagentId: string, message: any): void {
    // 处理 Subagent 消息
    console.log(`[Subagent ${subagentId}]`, message);
  }
  
  private handleSubagentExit(subagentId: string, code: number | null): void {
    console.log(`[Subagent ${subagentId}] exited with code ${code}`);
    this.subagents.delete(subagentId);
  }
}

interface SubagentInstance {
  id: string;
  config: SubagentConfig;
  process: any;
  status: 'starting' | 'running' | 'stopping' | 'stopped';
}
```

---

### 2. Subagent Worker

```typescript
// src/subagents/worker.ts
import { parentPort } from 'worker_threads';

class SubagentWorker {
  private id: string;
  private config: any;
  
  constructor() {
    // 解析命令行参数
    const args = process.argv.slice(2);
    this.id = args.find(a => a.startsWith('--id='))?.split('=')[1] || '';
    const configStr = args.find(a => a.startsWith('--config='))?.split('=')[1] || '{}';
    this.config = JSON.parse(configStr);
    
    // 监听父进程消息
    parentPort?.on('message', (msg) => this.handleMessage(msg));
    
    // 启动 worker
    this.start();
  }
  
  private async start(): Promise<void> {
    console.log(`[Worker ${this.id}] starting...`);
    
    // 初始化
    await this.initialize();
    
    // 通知父进程已就绪
    parentPort?.postMessage({ type: 'ready' });
    
    console.log(`[Worker ${this.id}] ready`);
  }
  
  private async initialize(): Promise<void> {
    // 初始化逻辑
  }
  
  private async handleMessage(message: any): Promise<void> {
    switch (message.type) {
      case 'task':
        await this.executeTask(message.data);
        break;
      case 'stop':
        await this.stop();
        break;
    }
  }
  
  private async executeTask(task: any): Promise<void> {
    try {
      // 执行任务
      const result = await this.runTask(task);
      
      // 返回结果
      parentPort?.postMessage({
        type: 'result',
        taskId: task.id,
        success: true,
        data: result,
      });
    } catch (error) {
      // 返回错误
      parentPort?.postMessage({
        type: 'result',
        taskId: task.id,
        success: false,
        error: error.message,
      });
    }
  }
  
  private async runTask(task: any): Promise<any> {
    // 实现任务执行逻辑
    return {};
  }
  
  private async stop(): Promise<void> {
    console.log(`[Worker ${this.id}] stopping...`);
    
    // 清理资源
    // ...
    
    // 退出
    process.exit(0);
  }
}

// 启动 worker
new SubagentWorker();
```

---

## 🐛 错误处理

### 1. 错误分类

```typescript
// src/errors/types.ts
export enum ErrorCode {
  // 通用错误
  INTERNAL_ERROR = 'INTERNAL_ERROR',
  INVALID_ARGUMENT = 'INVALID_ARGUMENT',
  TIMEOUT = 'TIMEOUT',
  
  // 认证错误
  AUTH_FAILED = 'AUTH_FAILED',
  PERMISSION_DENIED = 'PERMISSION_DENIED',
  SESSION_EXPIRED = 'SESSION_EXPIRED',
  
  // 密码箱错误
  VAULT_LOCKED = 'VAULT_LOCKED',
  CREDENTIAL_NOT_FOUND = 'CREDENTIAL_NOT_FOUND',
  DECRYPTION_FAILED = 'DECRYPTION_FAILED',
  
  // eCAL 错误
  ECAL_NOT_INITIALIZED = 'ECAL_NOT_INITIALIZED',
  PUBLISH_FAILED = 'PUBLISH_FAILED',
  SUBSCRIBE_FAILED = 'SUBSCRIBE_FAILED',
  
  // 插件错误
  PLUGIN_NOT_FOUND = 'PLUGIN_NOT_FOUND',
  PLUGIN_LOAD_FAILED = 'PLUGIN_LOAD_FAILED',
  PLUGIN_EXECUTION_FAILED = 'PLUGIN_EXECUTION_FAILED',
}

export class PolyVaultError extends Error {
  constructor(
    public code: ErrorCode,
    message: string,
    public details?: any
  ) {
    super(message);
    this.name = 'PolyVaultError';
  }
}
```

---

### 2. 错误处理中间件

```typescript
// src/middleware/error-handler.ts
import { Message, MessageContext } from '../messages/types';
import { PolyVaultError, ErrorCode } from '../errors/types';

export class ErrorHandler {
  /**
   * 处理错误
   */
  async handle(error: Error, context: {
    message?: Message;
    agentId: string;
  }): Promise<void> {
    // 记录错误
    this.logError(error, context);
    
    // 发送错误响应
    if (context.message) {
      await this.sendErrorResponse(context.message, error);
    }
    
    // 如果是严重错误，重启 Agent
    if (this.isCriticalError(error)) {
      await this.restartAgent();
    }
  }
  
  /**
   * 记录错误
   */
  private logError(error: Error, context: any): void {
    const errorRecord = {
      timestamp: new Date().toISOString(),
      agentId: context.agentId,
      messageId: context.message?.id,
      error: {
        name: error.name,
        message: error.message,
        stack: error.stack,
        code: (error as PolyVaultError).code,
      },
    };
    
    // 写入日志
    console.error('[ERROR]', JSON.stringify(errorRecord));
  }
  
  /**
   * 发送错误响应
   */
  private async sendErrorResponse(originalMessage: Message, error: Error): Promise<void> {
    // 实现错误响应发送
  }
  
  /**
   * 判断是否为严重错误
   */
  private isCriticalError(error: Error): boolean {
    const criticalCodes = [
      ErrorCode.DECRYPTION_FAILED,
      ErrorCode.ECAL_NOT_INITIALIZED,
    ];
    
    return criticalCodes.includes((error as PolyVaultError).code);
  }
  
  /**
   * 重启 Agent
   */
  private async restartAgent(): Promise<void> {
    // 实现重启逻辑
    process.exit(1);
  }
}
```

---

## 🧪 测试与调试

### 1. 单元测试

```typescript
// tests/vault-manager.test.ts
import { VaultManager } from '../src/vault/manager';
import { Credential } from '../src/vault/types';

describe('VaultManager', () => {
  let vaultManager: VaultManager;
  
  beforeEach(async () => {
    vaultManager = new VaultManager();
    await vaultManager.load({
      storagePath: '/tmp/test-vault.db',
      encryptionKey: 'test-key',
    });
  });
  
  afterEach(async () => {
    await vaultManager.save();
  });
  
  test('should store and retrieve credential', async () => {
    const credential: Credential = {
      id: 'test-1',
      serviceUrl: 'https://example.com',
      username: 'testuser',
      password: 'testpass',
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };
    
    // 存储凭证
    await vaultManager.storeCredential(credential);
    
    // 获取凭证
    const retrieved = await vaultManager.getCredential('https://example.com');
    
    expect(retrieved).toBeDefined();
    expect(retrieved?.username).toBe('testuser');
  });
  
  test('should return null for non-existent credential', async () => {
    const retrieved = await vaultManager.getCredential('https://nonexistent.com');
    expect(retrieved).toBeNull();
  });
  
  test('should delete credential', async () => {
    const credential: Credential = {
      id: 'test-2',
      serviceUrl: 'https://test.com',
      username: 'testuser',
      password: 'testpass',
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };
    
    await vaultManager.storeCredential(credential);
    const deleted = await vaultManager.deleteCredential(credential.id);
    
    expect(deleted).toBe(true);
    
    const retrieved = await vaultManager.getCredential('https://test.com');
    expect(retrieved).toBeNull();
  });
});
```

---

### 2. 集成测试

```typescript
// tests/integration/acp-communication.test.ts
import { AcpClient } from '../../src/acp/client';
import { PolyVaultAgent } from '../../src/agent/polyvault-agent';

describe('ACP Communication', () => {
  let acpClient: AcpClient;
  let agent: PolyVaultAgent;
  
  beforeAll(async () => {
    // 启动 Agent
    agent = new PolyVaultAgent(createTestContext());
    await agent.onStart();
    
    // 连接 ACP
    acpClient = new AcpClient();
    await acpClient.connect({
      host: 'localhost',
      port: 9000,
      agentId: 'polyvault-agent',
    });
  });
  
  afterAll(async () => {
    await agent.onStop();
    await acpClient.disconnect();
  });
  
  test('should get credential via ACP', async () => {
    const response = await acpClient.request({
      id: 'test-1',
      type: 'vault/get',
      data: {
        serviceUrl: 'https://example.com',
      },
    });
    
    expect(response.data.success).toBe(true);
    expect(response.data.credential).toBeDefined();
  });
  
  test('should store credential via ACP', async () => {
    const response = await acpClient.request({
      id: 'test-2',
      type: 'vault/store',
      data: {
        credential: {
          serviceUrl: 'https://test.com',
          username: 'testuser',
          password: 'testpass',
        },
      },
    });
    
    expect(response.data.success).toBe(true);
  });
});
```

---

## 📦 部署指南

### 1. Docker 部署

```dockerfile
# Dockerfile
FROM node:20-alpine

# 安装依赖
RUN apk add --no-cache \
    git \
    python3 \
    make \
    g++

# 设置工作目录
WORKDIR /app

# 复制 package.json
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制源代码
COPY . .

# 构建
RUN npm run build

# 暴露端口
EXPOSE 8080 9090

# 启动命令
CMD ["node", "dist/agent/main.js"]
```

```yaml
# docker-compose.yaml
version: '3.8'

services:
  polyvault-agent:
    build: .
    container_name: polyvault-agent
    restart: unless-stopped
    ports:
      - "8080:8080"   # Health check
      - "9090:9090"   # Metrics
    volumes:
      - ./config:/app/config:ro
      - vault-data:/var/lib/polyvault
      - ./logs:/var/log/polyvault
    environment:
      - NODE_ENV=production
      - VAULT_MASTER_KEY=${VAULT_MASTER_KEY}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  vault-data:
```

---

## 📞 支持与反馈

- **文档**: https://docs.polyvault.io/agent
- **GitHub**: https://github.com/polyvault/agent
- **Discord**: https://discord.gg/polyvault

---

**文档维护**: PolyVault Core Team  
**反馈邮箱**: dev@polyvault.io  
**最后更新**: 2026-03-15
