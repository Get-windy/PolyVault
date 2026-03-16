# PolyVault 浏览器扩展开发指南

**版本**: v1.0  
**创建时间**: 2026-03-15  
**适用对象**: 浏览器扩展开发者、前端工程师

---

## 📖 目录

1. [概述](#概述)
2. [快速开始](#快速开始)
3. [Manifest V3 架构](#manifest-v3-架构)
4. [核心功能实现](#核心功能实现)
5. [Native Messaging](#native-messaging)
6. [自动填充](#自动填充)
7. [安全机制](#安全机制)
8. [调试与测试](#调试与测试)
9. [发布指南](#发布指南)

---

## 🎯 概述

### PolyVault 浏览器扩展

PolyVault 浏览器扩展是一个基于 Manifest V3 的密码管理扩展，支持：

- 🔐 **安全存储**: 加密存储网站凭证
- 🔄 **自动填充**: 自动填充登录表单
- 🔑 **密码生成**: 生成高强度随机密码
- 🌐 **多端同步**: 与移动端/桌面端同步
- 🛡️ **钓鱼防护**: 检测钓鱼网站

### 支持浏览器

| 浏览器 | 版本 | 状态 |
|--------|------|------|
| **Chrome** | 110+ | ✅ 完全支持 |
| **Edge** | 110+ | ✅ 完全支持 |
| **Firefox** | 115+ | ✅ 完全支持 (MV3) |
| **Brave** | 1.60+ | ✅ 完全支持 |
| **Opera** | 95+ | ✅ 完全支持 |

---

## 🚀 快速开始

### 1. 环境准备

#### 安装 Node.js

```bash
# 安装 Node.js 20+
nvm install 20
nvm use 20

# 验证安装
node --version  # v20.x.x
npm --version   # 10.x.x
```

---

### 2. 创建项目

#### 使用模板

```bash
# 克隆 PolyVault 扩展模板
git clone https://github.com/polyvault/browser-extension-template.git polyvault-extension
cd polyvault-extension

# 安装依赖
npm install

# 开发模式
npm run dev

# 构建生产版本
npm run build
```

#### 手动创建

```bash
# 创建项目目录
mkdir polyvault-extension
cd polyvault-extension

# 初始化 npm
npm init -y

# 安装依赖
npm install webextension-polyfill crypto-js

# 安装开发依赖
npm install --save-dev \
  webpack \
  webpack-cli \
  copy-webpack-plugin \
  typescript \
  @types/chrome \
  @types/webextension-polyfill
```

---

### 3. 项目结构

```
polyvault-extension/
├── manifest.json              # 扩展清单 (MV3)
├── package.json
├── tsconfig.json
├── webpack.config.js
│
├── src/                       # 源代码
│   ├── background/           # Service Worker
│   │   ├── index.ts          # 入口文件
│   │   ├── vault.ts          # 密码箱管理
│   │   ├── sync.ts           # 同步服务
│   │   └── context-menu.ts   # 右键菜单
│   │
│   ├── content/              # Content Scripts
│   │   ├── index.ts          # 入口文件
│   │   ├── detector.ts       # 表单检测
│   │   ├── filler.ts         # 自动填充
│   │   └── observer.ts       # DOM 观察器
│   │
│   ├── popup/                # Popup UI
│   │   ├── index.html
│   │   ├── index.tsx
│   │   ├── App.tsx
│   │   └── components/
│   │       ├── VaultList.tsx
│   │       ├── CredentialForm.tsx
│   │       └── Settings.tsx
│   │
│   └── shared/               # 共享代码
│       ├── crypto.ts         # 加密工具
│       ├── storage.ts        # 存储工具
│       └── types.ts          # 类型定义
│
├── public/                    # 静态资源
│   ├── icons/
│   │   ├── icon-16.png
│   │   ├── icon-48.png
│   │   └── icon-128.png
│   └── styles.css
│
└── dist/                      # 构建输出
    ├── manifest.json
    ├── background.js
    ├── content.js
    ├── popup.html
    └── popup.js
```

---

## 📋 Manifest V3 架构

### 1. manifest.json

```json
{
  "manifest_version": 3,
  "name": "PolyVault Password Manager",
  "version": "1.0.0",
  "description": "安全、去中心化的密码管理器",
  "author": "PolyVault Team",
  "homepage_url": "https://polyvault.io",
  
  "icons": {
    "16": "icons/icon-16.png",
    "48": "icons/icon-48.png",
    "128": "icons/icon-128.png"
  },
  
  "action": {
    "default_popup": "popup.html",
    "default_icon": {
      "16": "icons/icon-16.png",
      "48": "icons/icon-48.png",
      "128": "icons/icon-128.png"
    },
    "default_title": "PolyVault"
  },
  
  "background": {
    "service_worker": "background.js",
    "type": "module"
  },
  
  "content_scripts": [
    {
      "matches": ["http://*/*", "https://*/*"],
      "js": ["content.js"],
      "css": ["styles.css"],
      "run_at": "document_idle",
      "all_frames": true
    }
  ],
  
  "permissions": [
    "storage",
    "tabs",
    "contextMenus",
    "clipboardWrite",
    "nativeMessaging"
  ],
  
  "host_permissions": [
    "http://*/*",
    "https://*/*"
  ],
  
  "optional_permissions": [
    "bookmarks",
    "history"
  ],
  
  "web_accessible_resources": [
    {
      "resources": ["icons/*", "styles.css"],
      "matches": ["<all_urls>"]
    }
  ],
  
  "content_security_policy": {
    "extension_pages": "script-src 'self'; object-src 'self'"
  },
  
  "externally_connectable": {
    "matches": ["https://polyvault.io/*"]
  },
  
  "commands": {
    "_execute_action": {
      "suggested_key": {
        "default": "Ctrl+Shift+P",
        "mac": "Command+Shift+P"
      }
    },
    "autofill": {
      "suggested_key": {
        "default": "Ctrl+Shift+L",
        "mac": "Command+Shift+L"
      },
      "description": "自动填充凭证"
    }
  },
  
  "native_messaging_hosts": [
    "io.polyvault.native_messaging"
  ]
}
```

---

### 2. Service Worker (Background)

```typescript
// src/background/index.ts
import { VaultService } from './vault';
import { SyncService } from './sync';
import { setupContextMenu } from './context-menu';

// 全局状态
let vaultService: VaultService | null = null;
let syncService: SyncService | null = null;

// 扩展安装/更新
chrome.runtime.onInstalled.addListener(async (details) => {
  console.log('PolyVault installed:', details.reason);
  
  // 初始化服务
  vaultService = new VaultService();
  syncService = new SyncService();
  
  // 设置右键菜单
  setupContextMenu();
  
  // 初始化存储
  await initializeStorage();
});

// 监听扩展图标点击
chrome.action.onClicked.addListener(async (tab) => {
  if (tab.id) {
    chrome.tabs.sendMessage(tab.id, { type: 'OPEN_POPUP' });
  }
});

// 监听来自 Content Script 的消息
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  handleMessage(message, sender, sendResponse);
  return true; // 保持消息通道开放
});

// 消息处理
async function handleMessage(
  message: any,
  sender: chrome.runtime.MessageSender,
  sendResponse: (response: any) => void
) {
  try {
    switch (message.type) {
      case 'GET_CREDENTIAL':
        const credential = await vaultService?.getCredential(message.url);
        sendResponse({ success: true, data: credential });
        break;
      
      case 'SAVE_CREDENTIAL':
        await vaultService?.saveCredential(message.credential);
        sendResponse({ success: true });
        break;
      
      case 'GENERATE_PASSWORD':
        const password = await vaultService?.generatePassword(message.options);
        sendResponse({ success: true, data: password });
        break;
      
      case 'SYNC_NOW':
        await syncService?.sync();
        sendResponse({ success: true });
        break;
      
      default:
        sendResponse({ success: false, error: 'Unknown message type' });
    }
  } catch (error) {
    console.error('Message handling error:', error);
    sendResponse({ 
      success: false, 
      error: error instanceof Error ? error.message : 'Unknown error' 
    });
  }
}

// 初始化存储
async function initializeStorage() {
  // 设置默认配置
  const config = await chrome.storage.sync.get(null);
  
  if (Object.keys(config).length === 0) {
    await chrome.storage.sync.set({
      autoFill: true,
      autoSave: true,
      passwordLength: 16,
      includeSymbols: true,
      syncInterval: 3600, // 1 hour
    });
  }
}

// 清理资源
chrome.runtime.onSuspend.addListener(() => {
  vaultService = null;
  syncService = null;
});
```

---

### 3. Content Script

```typescript
// src/content/index.ts
import { FormDetector } from './detector';
import { FormFiller } from './filler';
import { DOMObserver } from './observer';

class ContentScript {
  private detector: FormDetector;
  private filler: FormFiller;
  private observer: DOMObserver;
  
  constructor() {
    this.detector = new FormDetector();
    this.filler = new FormFiller();
    this.observer = new DOMObserver();
    
    this.initialize();
  }
  
  private async initialize() {
    console.log('[PolyVault] Content script initialized');
    
    // 监听来自 Background 的消息
    chrome.runtime.onMessage.addListener(this.handleMessage.bind(this));
    
    // 检测当前页面的表单
    await this.detectForms();
    
    // 监听 DOM 变化
    this.observer.observe(document.body, this.onDOMChange.bind(this));
    
    // 添加键盘快捷键监听
    this.setupKeyboardShortcuts();
  }
  
  private async detectForms() {
    const forms = this.detector.detectForms();
    
    for (const form of forms) {
      console.log('[PolyVault] Form detected:', form);
      
      // 检查是否有保存的凭证
      const credential = await this.requestCredential(form.url);
      
      if (credential) {
        // 显示填充提示
        this.showFillPrompt(form, credential);
      }
    }
  }
  
  private onDOMChange(mutations: MutationRecord[]) {
    for (const mutation of mutations) {
      if (mutation.addedNodes.length > 0) {
        // 检查新添加的节点是否包含表单
        this.detectForms();
      }
    }
  }
  
  private handleMessage(
    message: any,
    sender: chrome.runtime.MessageSender,
    sendResponse: (response: any) => void
  ) {
    switch (message.type) {
      case 'FILL_CREDENTIAL':
        this.filler.fillForm(message.credential);
        sendResponse({ success: true });
        break;
      
      case 'CLEAR_FORMS':
        this.filler.clearForms();
        sendResponse({ success: true });
        break;
      
      case 'DETECT_FORMS':
        const forms = this.detector.detectForms();
        sendResponse({ forms });
        break;
    }
    
    return true;
  }
  
  private async requestCredential(url: string) {
    return new Promise((resolve) => {
      chrome.runtime.sendMessage(
        { type: 'GET_CREDENTIAL', url },
        (response) => {
          if (response?.success) {
            resolve(response.data);
          } else {
            resolve(null);
          }
        }
      );
    });
  }
  
  private showFillPrompt(form: any, credential: any) {
    // 创建填充提示 UI
    const prompt = document.createElement('div');
    prompt.className = 'polyvault-fill-prompt';
    prompt.innerHTML = `
      <div class="polyvault-prompt-content">
        <p>找到凭证：<strong>${credential.username}</strong></p>
        <button class="polyvault-fill-btn">填充</button>
        <button class="polyvault-dismiss-btn">忽略</button>
      </div>
    `;
    
    // 添加事件监听
    prompt.querySelector('.polyvault-fill-btn')?.addEventListener('click', () => {
      this.filler.fillForm(credential);
      prompt.remove();
    });
    
    prompt.querySelector('.polyvault-dismiss-btn')?.addEventListener('click', () => {
      prompt.remove();
    });
    
    // 添加到页面
    document.body.appendChild(prompt);
  }
  
  private setupKeyboardShortcuts() {
    document.addEventListener('keydown', (e) => {
      // Ctrl+Shift+L 或 Cmd+Shift+L
      if ((e.ctrlKey || e.metaKey) && e.shiftKey && e.key === 'L') {
        e.preventDefault();
        this.triggerAutoFill();
      }
    });
  }
  
  private async triggerAutoFill() {
    const forms = this.detector.detectForms();
    if (forms.length > 0) {
      const credential = await this.requestCredential(forms[0].url);
      if (credential) {
        this.filler.fillForm(credential);
      }
    }
  }
}

// 启动 Content Script
new ContentScript();
```

---

## 🔌 核心功能实现

### 1. 表单检测

```typescript
// src/content/detector.ts
export interface FormInfo {
  form: HTMLFormElement;
  url: string;
  usernameField?: HTMLInputElement;
  passwordField?: HTMLInputElement;
  totpField?: HTMLInputElement;
}

export class FormDetector {
  /**
   * 检测页面上的所有登录表单
   */
  detectForms(): FormInfo[] {
    const forms: FormInfo[] = [];
    const formElements = document.querySelectorAll('form');
    
    for (const formElement of formElements) {
      const form = formElement as HTMLFormElement;
      const formInfo = this.analyzeForm(form);
      
      if (formInfo) {
        forms.push(formInfo);
      }
    }
    
    // 也检测没有 form 标签的输入框组合
    const orphanFields = this.detectOrphanFields();
    if (orphanFields) {
      forms.push(orphanFields);
    }
    
    return forms;
  }
  
  /**
   * 分析单个表单
   */
  private analyzeForm(form: HTMLFormElement): FormInfo | null {
    const inputs = form.querySelectorAll('input');
    
    let usernameField: HTMLInputElement | undefined;
    let passwordField: HTMLInputElement | undefined;
    let totpField: HTMLInputElement | undefined;
    
    for (const input of inputs) {
      const inputEl = input as HTMLInputElement;
      const type = inputEl.type.toLowerCase();
      const name = inputEl.name.toLowerCase();
      const id = inputEl.id.toLowerCase();
      const placeholder = inputEl.placeholder.toLowerCase();
      
      // 检测用户名
      if (this.isUsernameField(type, name, id, placeholder)) {
        usernameField = inputEl;
      }
      
      // 检测密码
      if (type === 'password' && !totpField) {
        if (this.isTotpField(name, id, placeholder)) {
          totpField = inputEl;
        } else {
          passwordField = inputEl;
        }
      }
    }
    
    // 只有同时有用户名和密码字段才认为是登录表单
    if (usernameField && passwordField) {
      return {
        form,
        url: this.extractFormUrl(form),
        usernameField,
        passwordField,
        totpField,
      };
    }
    
    return null;
  }
  
  /**
   * 检测孤立的输入框（不在 form 标签内）
   */
  private detectOrphanFields(): FormInfo | null {
    const passwordInputs = Array.from(
      document.querySelectorAll('input[type="password"]')
    ) as HTMLInputElement[];
    
    for (const passwordField of passwordInputs) {
      // 查找附近的用户名输入框
      const usernameField = this.findNearbyUsernameField(passwordField);
      
      if (usernameField) {
        return {
          form: document.createElement('form'), // 虚拟 form
          url: window.location.href,
          usernameField,
          passwordField,
        };
      }
    }
    
    return null;
  }
  
  /**
   * 判断是否为用户名输入框
   */
  private isUsernameField(
    type: string,
    name: string,
    id: string,
    placeholder: string
  ): boolean {
    const usernameKeywords = [
      'username', 'user', 'email', 'login', 'account', 'userid', 'user_id'
    ];
    
    const textTypes = ['text', 'email', 'tel'];
    
    if (!textTypes.includes(type)) return false;
    
    return (
      usernameKeywords.some(k => name.includes(k)) ||
      usernameKeywords.some(k => id.includes(k)) ||
      usernameKeywords.some(k => placeholder.includes(k))
    );
  }
  
  /**
   * 判断是否为 TOTP 输入框
   */
  private isTotpField(name: string, id: string, placeholder: string): boolean {
    const totpKeywords = [
      'totp', '2fa', 'otp', 'verification', 'auth_code', 'security_code'
    ];
    
    return (
      totpKeywords.some(k => name.includes(k)) ||
      totpKeywords.some(k => id.includes(k)) ||
      totpKeywords.some(k => placeholder.includes(k))
    );
  }
  
  /**
   * 在密码框附近查找用户名输入框
   */
  private findNearbyUsernameField(passwordField: HTMLInputElement): HTMLInputElement | null {
    // 检查同一个容器
    const container = passwordField.closest('div, section, .form-group');
    if (container) {
      const usernameField = container.querySelector(
        'input[type="text"], input[type="email"]'
      ) as HTMLInputElement | null;
      
      if (usernameField && this.isUsernameField(
        usernameField.type,
        usernameField.name,
        usernameField.id,
        usernameField.placeholder
      )) {
        return usernameField;
      }
    }
    
    // 检查前一个输入框
    let prev = passwordField.previousElementSibling;
    while (prev) {
      if (prev.tagName === 'INPUT') {
        const input = prev as HTMLInputElement;
        if (this.isUsernameField(input.type, input.name, input.id, input.placeholder)) {
          return input;
        }
      }
      prev = prev.previousElementSibling;
    }
    
    return null;
  }
  
  /**
   * 提取表单的目标 URL
   */
  private extractFormUrl(form: HTMLFormElement): string {
    const action = form.getAttribute('action');
    
    if (action) {
      try {
        return new URL(action, window.location.href).href;
      } catch {
        return window.location.href;
      }
    }
    
    return window.location.href;
  }
}
```

---

### 2. 自动填充

```typescript
// src/content/filler.ts
import { Credential } from '../shared/types';

export class FormFiller {
  /**
   * 填充表单
   */
  fillForm(credential: Credential): void {
    // 查找表单字段
    const fields = this.findFormFields();
    
    // 填充用户名
    if (fields.username && credential.username) {
      this.fillField(fields.username, credential.username);
    }
    
    // 填充密码
    if (fields.password && credential.password) {
      this.fillField(fields.password, credential.password);
    }
    
    // 填充 TOTP
    if (fields.totp && credential.totp) {
      this.fillField(fields.totp, credential.totp);
    }
    
    // 触发输入事件
    this.triggerInputEvents(fields);
    
    // 可选：自动提交
    if (credential.autoSubmit) {
      setTimeout(() => {
        fields.form?.submit();
      }, 500);
    }
  }
  
  /**
   * 清空表单
   */
  clearForms(): void {
    const forms = document.querySelectorAll('form');
    
    for (const form of forms) {
      const inputs = form.querySelectorAll('input');
      for (const input of inputs) {
        const inputEl = input as HTMLInputElement;
        if (['text', 'password', 'email'].includes(inputEl.type)) {
          inputEl.value = '';
        }
      }
    }
  }
  
  /**
   * 查找表单字段
   */
  private findFormFields(): {
    form?: HTMLFormElement;
    username?: HTMLInputElement;
    password?: HTMLInputElement;
    totp?: HTMLInputElement;
  } {
    const forms = document.querySelectorAll('form');
    
    for (const form of forms) {
      const formEl = form as HTMLFormElement;
      const inputs = formEl.querySelectorAll('input');
      
      const fields: any = { form: formEl };
      
      for (const input of inputs) {
        const inputEl = input as HTMLInputElement;
        const type = inputEl.type.toLowerCase();
        
        if (type === 'text' || type === 'email') {
          fields.username = inputEl;
        } else if (type === 'password') {
          if (!fields.password) {
            fields.password = inputEl;
          } else {
            fields.totp = inputEl;
          }
        }
      }
      
      if (fields.username && fields.password) {
        return fields;
      }
    }
    
    return {};
  }
  
  /**
   * 填充单个字段
   */
  private fillField(field: HTMLInputElement, value: string): void {
    // 设置值
    field.value = value;
    
    // 触发事件（绕过 React 等框架的检测）
    const events = [
      new Event('input', { bubbles: true }),
      new Event('change', { bubbles: true }),
      new KeyboardEvent('keydown', { bubbles: true }),
      new KeyboardEvent('keypress', { bubbles: true }),
      new KeyboardEvent('keyup', { bubbles: true }),
    ];
    
    for (const event of events) {
      field.dispatchEvent(event);
    }
  }
  
  /**
   * 触发输入事件
   */
  private triggerInputEvents(fields: any): void {
    if (fields.username) {
      fields.username.dispatchEvent(new Event('input', { bubbles: true }));
    }
    if (fields.password) {
      fields.password.dispatchEvent(new Event('input', { bubbles: true }));
    }
    if (fields.totp) {
      fields.totp.dispatchEvent(new Event('input', { bubbles: true }));
    }
  }
}
```

---

## 🔗 Native Messaging

### 1. Native Host 配置

#### Windows

```json
// io.polyvault.native_messaging.json (Windows)
{
  "name": "io.polyvault.native_messaging",
  "description": "PolyVault Native Messaging Host",
  "path": "C:\\Program Files\\PolyVault\\native-messaging-host.exe",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://YOUR_EXTENSION_ID/"
  ]
}
```

注册表位置：
```
HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\io.polyvault.native_messaging
```

#### macOS

```json
// io.polyvault.native_messaging.json (macOS)
{
  "name": "io.polyvault.native_messaging",
  "description": "PolyVault Native Messaging Host",
  "path": "/Applications/PolyVault.app/Contents/MacOS/native-messaging-host",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://YOUR_EXTENSION_ID/"
  ]
}
```

文件位置：
```
~/Library/Application Support/Google/Chrome/NativeMessagingHosts/io.polyvault.native_messaging.json
```

#### Linux

```json
// io.polyvault.native_messaging.json (Linux)
{
  "name": "io.polyvault.native_messaging",
  "description": "PolyVault Native Messaging Host",
  "path": "/opt/polyvault/native-messaging-host",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://YOUR_EXTENSION_ID/"
  ]
}
```

文件位置：
```
~/.config/google-chrome/NativeMessagingHosts/io.polyvault.native_messaging.json
```

---

### 2. Native Host 实现

```typescript
// native-host/src/main.ts
import * as readline from 'readline';

class NativeMessagingHost {
  private messageBuffer = Buffer.alloc(0);
  
  constructor() {
    this.start();
  }
  
  private start() {
    // 读取 stdin
    const rl = readline.createInterface({
      input: process.stdin,
      crlfDelay: Infinity,
    });
    
    rl.on('line', (line) => {
      this.handleMessage(line);
    });
  }
  
  private handleMessage(line: string) {
    try {
      // 解析消息
      const message = JSON.parse(line);
      
      // 处理消息
      this.processMessage(message);
    } catch (error) {
      this.sendError('Invalid message format');
    }
  }
  
  private async processMessage(message: any) {
    switch (message.type) {
      case 'GET_CREDENTIAL':
        await this.handleGetCredential(message);
        break;
      
      case 'STORE_CREDENTIAL':
        await this.handleStoreCredential(message);
        break;
      
      case 'UNLOCK_VAULT':
        await this.handleUnlockVault(message);
        break;
      
      default:
        this.sendError('Unknown message type');
    }
  }
  
  private async handleGetCredential(message: any) {
    try {
      // 从密码箱获取凭证
      const credential = await this.vaultGet(message.url);
      
      // 发送响应
      this.sendResponse({
        type: 'GET_CREDENTIAL_RESPONSE',
        success: true,
        data: credential,
      });
    } catch (error) {
      this.sendResponse({
        type: 'GET_CREDENTIAL_RESPONSE',
        success: false,
        error: error.message,
      });
    }
  }
  
  private async handleStoreCredential(message: any) {
    try {
      // 存储凭证到密码箱
      await this.vaultStore(message.credential);
      
      this.sendResponse({
        type: 'STORE_CREDENTIAL_RESPONSE',
        success: true,
      });
    } catch (error) {
      this.sendResponse({
        type: 'STORE_CREDENTIAL_RESPONSE',
        success: false,
        error: error.message,
      });
    }
  }
  
  private async handleUnlockVault(message: any) {
    try {
      // 解锁密码箱
      await this.vaultUnlock(message.masterPassword);
      
      this.sendResponse({
        type: 'UNLOCK_VAULT_RESPONSE',
        success: true,
      });
    } catch (error) {
      this.sendResponse({
        type: 'UNLOCK_VAULT_RESPONSE',
        success: false,
        error: error.message,
      });
    }
  }
  
  private sendResponse(response: any) {
    const message = JSON.stringify(response);
    const length = Buffer.byteLength(message);
    
    // 写入长度（4 字节，小端序）
    const lengthBuffer = Buffer.alloc(4);
    lengthBuffer.writeUInt32LE(length, 0);
    
    // 写入消息
    process.stdout.write(lengthBuffer);
    process.stdout.write(message);
  }
  
  private sendError(error: string) {
    this.sendResponse({
      type: 'ERROR',
      error: error,
    });
  }
  
  // 密码箱操作方法（需要实现）
  private async vaultGet(url: string) { return null; }
  private async vaultStore(credential: any) { }
  private async vaultUnlock(password: string) { }
}

// 启动 Native Host
new NativeMessagingHost();
```

---

### 3. Extension 端调用

```typescript
// src/background/native-messaging.ts
export class NativeMessagingClient {
  private port: chrome.runtime.Port | null = null;
  
  /**
   * 连接到 Native Host
   */
  connect(): chrome.runtime.Port {
    this.port = chrome.runtime.connectNative('io.polyvault.native_messaging');
    
    this.port.onMessage.addListener((response) => {
      this.handleResponse(response);
    });
    
    this.port.onDisconnect.addListener(() => {
      console.log('[Native] Disconnected');
      this.port = null;
    });
    
    return this.port;
  }
  
  /**
   * 发送消息
   */
  send(message: any): Promise<any> {
    return new Promise((resolve, reject) => {
      if (!this.port) {
        this.connect();
      }
      
      const messageId = `msg_${Date.now()}`;
      
      // 设置一次性监听器
      const listener = (response: any) => {
        if (response.id === messageId) {
          this.port!.onMessage.removeListener(listener);
          
          if (response.success) {
            resolve(response.data);
          } else {
            reject(new Error(response.error));
          }
        }
      };
      
      this.port!.onMessage.addListener(listener);
      
      // 发送消息
      this.port!.postMessage({
        id: messageId,
        ...message,
      });
      
      // 超时处理
      setTimeout(() => {
        this.port!.onMessage.removeListener(listener);
        reject(new Error('Native messaging timeout'));
      }, 30000);
    });
  }
  
  /**
   * 获取凭证
   */
  async getCredential(url: string) {
    return this.send({
      type: 'GET_CREDENTIAL',
      url: url,
    });
  }
  
  /**
   * 存储凭证
   */
  async storeCredential(credential: any) {
    return this.send({
      type: 'STORE_CREDENTIAL',
      credential: credential,
    });
  }
  
  /**
   * 解锁密码箱
   */
  async unlockVault(masterPassword: string) {
    return this.send({
      type: 'UNLOCK_VAULT',
      masterPassword: masterPassword,
    });
  }
  
  private handleResponse(response: any) {
    console.log('[Native] Response:', response);
  }
}
```

---

## 🛡️ 安全机制

### 1. 内容安全策略 (CSP)

```json
{
  "content_security_policy": {
    "extension_pages": "script-src 'self'; object-src 'self'; style-src 'self' 'unsafe-inline'",
    "sandbox": "sandbox allow-scripts allow-forms allow-popups allow-modals; script-src 'self' 'unsafe-inline' 'unsafe-eval'; child-src 'self'"
  }
}
```

### 2. 权限最小化

```json
{
  "permissions": [
    "storage",
    "tabs",
    "contextMenus"
  ],
  "optional_permissions": [
    "bookmarks",
    "history"
  ],
  "host_permissions": [
    "https://*/*"
  ]
}
```

### 3. 通信加密

```typescript
// src/shared/crypto.ts
import { AES, enc } from 'crypto-js';

export class CryptoService {
  /**
   * 加密消息
   */
  encrypt(message: string, key: string): string {
    return AES.encrypt(message, key).toString();
  }
  
  /**
   * 解密消息
   */
  decrypt(encrypted: string, key: string): string {
    const bytes = AES.decrypt(encrypted, key);
    return bytes.toString(enc.Utf8);
  }
  
  /**
   * 生成安全随机数
   */
  generateRandomBytes(length: number): Uint8Array {
    const array = new Uint8Array(length);
    crypto.getRandomValues(array);
    return array;
  }
  
  /**
   * 派生密钥
   */
  async deriveKey(password: string, salt: Uint8Array): Promise<CryptoKey> {
    const encoder = new TextEncoder();
    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      encoder.encode(password),
      'PBKDF2',
      false,
      ['deriveKey']
    );
    
    return crypto.subtle.deriveKey(
      {
        name: 'PBKDF2',
        salt: salt,
        iterations: 100000,
        hash: 'SHA-256',
      },
      keyMaterial,
      { name: 'AES-GCM', length: 256 },
      false,
      ['encrypt', 'decrypt']
    );
  }
}
```

---

## 🧪 调试与测试

### 1. 加载未打包的扩展

1. 打开 Chrome，访问 `chrome://extensions/`
2. 启用右上角的"开发者模式"
3. 点击"加载已解压的扩展程序"
4. 选择 `dist/` 目录

### 2. 调试 Service Worker

1. 访问 `chrome://extensions/`
2. 找到 PolyVault 扩展
3. 点击"service worker"链接
4. 打开 DevTools 进行调试

### 3. 调试 Content Script

1. 打开任意网页
2. 按 F12 打开 DevTools
3. 在 Console 中可以看到 Content Script 日志
4. 在 Sources 中可以设置断点

### 4. 单元测试

```typescript
// tests/form-detector.test.ts
import { FormDetector } from '../src/content/detector';

describe('FormDetector', () => {
  let detector: FormDetector;
  
  beforeEach(() => {
    detector = new FormDetector();
    
    // 设置测试 DOM
    document.body.innerHTML = `
      <form action="/login">
        <input type="text" name="username" id="username">
        <input type="password" name="password" id="password">
      </form>
    `;
  });
  
  test('should detect login form', () => {
    const forms = detector.detectForms();
    
    expect(forms.length).toBe(1);
    expect(forms[0].usernameField).toBeDefined();
    expect(forms[0].passwordField).toBeDefined();
  });
  
  test('should extract form URL', () => {
    const forms = detector.detectForms();
    
    expect(forms[0].url).toContain('/login');
  });
});
```

---

## 📦 发布指南

### 1. Chrome Web Store

```bash
# 构建生产版本
npm run build

# 打包为 ZIP
cd dist
zip -r ../polyvault-extension.zip .

# 上传到 Chrome Web Store
# https://chrome.google.com/webstore/devconsole
```

### 2. Edge Add-ons

```bash
# 使用相同的 ZIP 文件
# 上传到 Edge Add-ons
# https://microsoftedge.microsoft.com/addons/Microsoft-Edge-Extensions-Home
```

### 3. Firefox Add-ons

```bash
# 需要调整 manifest.json 以支持 Firefox
npm run build:firefox

# 使用 web-ext 工具
web-ext sign --api-key $AMO_API_KEY --api-secret $AMO_API_SECRET
```

---

## 📞 支持与反馈

- **文档**: https://docs.polyvault.io/extension
- **GitHub**: https://github.com/polyvault/browser-extension
- **Discord**: https://discord.gg/polyvault

---

**文档维护**: PolyVault Core Team  
**反馈邮箱**: dev@polyvault.io  
**最后更新**: 2026-03-15
