# PolyVault FFI Binding 开发指南

**版本**: v1.0  
**创建时间**: 2026-03-15  
**适用对象**: 系统开发人员、FFI 开发者

---

## 📖 目录

1. [FFI 概述](#ffi-概述)
2. [eCAL C API 调用方式](#ecal-c-api-调用方式)
3. [Rust FFI Binding](#rust-ffi-binding)
4. [Python FFI Binding](#python-ffi-binding)
5. [最佳实践](#最佳实践)
6. [故障排除](#故障排除)

---

## 🔍 FFI 概述

### 什么是 FFI？

**FFI (Foreign Function Interface)** 允许不同编程语言之间相互调用函数和共享数据。

### PolyVault FFI 架构

```
┌─────────────────────────────────────────────────────────┐
│                    PolyVault 核心 (C++)                  │
│  ┌─────────────┬─────────────┬─────────────┐           │
│  │ eCAL C API  │  数据总线   │  密码箱     │           │
│  └─────────────┴─────────────┴─────────────┘           │
│                        │                                │
│                  FFI Layer                              │
│                        │                                │
├────────────────────────┼────────────────────────────────┤
│                        │                                │
│  ┌─────────────────────┼─────────────────────┐         │
│  │                     │                     │         │
│  ▼                     ▼                     ▼         │
│ ┌──────────┐     ┌──────────┐     ┌──────────┐        │
│ │   Rust   │     │  Python  │     │   Node   │        │
│ │ Binding  │     │ Binding  │     │ Binding  │        │
│ └──────────┘     └──────────┘     └──────────┘        │
│                                                        │
│                    多语言生态                           │
└─────────────────────────────────────────────────────────┘
```

### 支持的绑定

| 语言 | 状态 | 版本 | 维护者 |
|------|------|------|--------|
| **C++ (原生)** | ✅ 稳定 | v1.0 | Core Team |
| **Rust** | 🟢 开发中 | v0.1 | Rust Team |
| **Python** | 🟢 开发中 | v0.1 | Python Team |
| **Node.js** | ⏳ 计划中 | - | - |

---

## 🔌 eCAL C API 调用方式

### eCAL C API 概述

eCAL 提供 C API 用于跨语言集成，避免 C++ ABI 兼容性问题。

### 安装 eCAL C API

#### Windows

```powershell
# 使用 Chocolatey
choco install ecal

# 或下载 MSI 安装包
# https://github.com/eclipse-ecal/ecal/releases
```

#### Linux

```bash
# Ubuntu/Debian
sudo add-apt-repository ppa:ecal/ecal-5.13
sudo apt-get update
sudo apt-get install libecal5 libecal-c-dev

# Fedora
sudo dnf install ecal ecal-c-devel
```

#### macOS

```bash
# 使用 Homebrew
brew install ecal
```

---

### eCAL C API 初始化

```c
#include <ecal/ecal_c.h>
#include <stdio.h>

int main() {
    // 1. 初始化 eCAL
    if (ecal_initialize(NULL, "PolyVault FFI Example") != 0) {
        fprintf(stderr, "Failed to initialize eCAL\n");
        return 1;
    }
    
    printf("eCAL initialized successfully\n");
    
    // 2. 设置运行状态
    ecal_set_run_state(1); // 1 = running
    
    // 3. 主循环
    while (ecal_ok() == 0) {
        // 等待消息
        ecal_sleep_ms(100);
    }
    
    // 4. 清理
    ecal_finalize();
    printf("eCAL finalized\n");
    
    return 0;
}
```

**编译**:
```bash
gcc -o ecal_example ecal_example.c -lecal_c
```

---

### 发布消息 (Publisher)

```c
#include <ecal/ecal_c.h>
#include <stdio.h>
#include <string.h>

int main() {
    // 初始化
    ecal_initialize(NULL, "PolyVault Publisher");
    ecal_set_run_state(1);
    
    // 创建发布者
    ecal_publisher_t pub = ecal_publisher_create("polyvault/credentials");
    
    if (pub == NULL) {
        fprintf(stderr, "Failed to create publisher\n");
        return 1;
    }
    
    printf("Publisher created, waiting for subscribers...\n");
    
    // 等待订阅者
    ecal_sleep_ms(1000);
    
    // 发布消息
    const char* message = "{\"type\":\"credential_request\",\"id\":\"req_001\"}";
    
    for (int i = 0; i < 10; i++) {
        ecal_write(pub, message, strlen(message), 0);
        printf("Published message %d\n", i + 1);
        ecal_sleep_ms(1000);
    }
    
    // 清理
    ecal_publisher_destroy(pub);
    ecal_finalize();
    
    return 0;
}
```

---

### 订阅消息 (Subscriber)

```c
#include <ecal/ecal_c.h>
#include <stdio.h>
#include <string.h>

// 消息回调函数
void on_message(const char* topic_name, 
                const void* msg, 
                size_t size, 
                long long timestamp,
                void* userdata) {
    printf("Received message on topic '%s':\n", topic_name);
    printf("Size: %zu bytes\n", size);
    printf("Data: %.*s\n", (int)size, (const char*)msg);
    printf("Timestamp: %lld\n", timestamp);
}

int main() {
    // 初始化
    ecal_initialize(NULL, "PolyVault Subscriber");
    ecal_set_run_state(1);
    
    // 创建订阅者
    ecal_subscriber_t sub = ecal_subscriber_create(
        "polyvault/credentials",
        on_message,
        NULL  // userdata
    );
    
    if (sub == NULL) {
        fprintf(stderr, "Failed to create subscriber\n");
        return 1;
    }
    
    printf("Subscriber created, waiting for messages...\n");
    
    // 主循环
    while (ecal_ok() == 0) {
        ecal_sleep_ms(100);
    }
    
    // 清理
    ecal_subscriber_destroy(sub);
    ecal_finalize();
    
    return 0;
}
```

---

### RPC 服务 (Server)

```c
#include <ecal/ecal_c.h>
#include <stdio.h>
#include <string.h>

// RPC 方法回调
const char* on_get_credential(const char* request, 
                               size_t request_size,
                               size_t* response_size,
                               void* userdata) {
    printf("Received RPC request: %.*s\n", 
           (int)request_size, request);
    
    // 处理请求并生成响应
    const char* response = "{\"status\":\"approved\",\"credential\":\"encrypted_token\"}";
    *response_size = strlen(response);
    
    return response;
}

int main() {
    // 初始化
    ecal_initialize(NULL, "PolyVault RPC Server");
    ecal_set_run_state(1);
    
    // 创建 RPC 服务器
    ecal_server_t server = ecal_server_create("polyvault_credential_service");
    
    // 注册方法
    ecal_server_add_method(server, "GetCredential", on_get_credential, NULL);
    
    printf("RPC server started\n");
    
    // 主循环
    while (ecal_ok() == 0) {
        ecal_sleep_ms(100);
    }
    
    // 清理
    ecal_server_destroy(server);
    ecal_finalize();
    
    return 0;
}
```

---

### RPC 客户端 (Client)

```c
#include <ecal/ecal_c.h>
#include <stdio.h>
#include <string.h>

int main() {
    // 初始化
    ecal_initialize(NULL, "PolyVault RPC Client");
    ecal_set_run_state(1);
    
    // 创建 RPC 客户端
    ecal_client_t client = ecal_client_create("polyvault_credential_service");
    
    if (client == NULL) {
        fprintf(stderr, "Failed to create client\n");
        return 1;
    }
    
    // 等待服务
    printf("Waiting for service...\n");
    while (!ecal_client_connected(client)) {
        ecal_sleep_ms(100);
    }
    printf("Service connected\n");
    
    // 调用方法
    const char* request = "{\"request_id\":\"req_001\",\"service_url\":\"https://github.com\"}";
    size_t response_size = 0;
    
    char* response = ecal_client_call_method(
        client,
        "GetCredential",
        request,
        strlen(request),
        &response_size,
        5000  // timeout in ms
    );
    
    if (response != NULL) {
        printf("Response: %.*s\n", (int)response_size, response);
        ecal_free(response);
    } else {
        fprintf(stderr, "RPC call failed\n");
    }
    
    // 清理
    ecal_client_destroy(client);
    ecal_finalize();
    
    return 0;
}
```

---

## 🦀 Rust FFI Binding

### 项目结构

```
polyvault-rust/
├── Cargo.toml
├── src/
│   ├── lib.rs
│   ├── ecal/
│   │   ├── mod.rs
│   │   ├── publisher.rs
│   │   ├── subscriber.rs
│   │   └── ffi.rs
│   └── vault/
│       ├── mod.rs
│       └── ffi.rs
├── bindings/
│   └── polyvault.h
└── examples/
    ├── publisher.rs
    └── subscriber.rs
```

---

### Cargo.toml

```toml
[package]
name = "polyvault-rust"
version = "0.1.0"
edition = "2021"

[dependencies]
libc = "0.2"
thiserror = "1.0"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

[build-dependencies]
bindgen = "0.69"
cc = "1.0"

[dev-dependencies]
tokio = { version = "1", features = ["full"] }
```

---

### build.rs

```rust
use std::env;
use std::path::PathBuf;

fn main() {
    // 链接 eCAL C 库
    println!("cargo:rustc-link-lib=ecal_c");
    
    // 查找 eCAL 库路径
    let lib_paths = [
        "/usr/lib",
        "/usr/local/lib",
        "C:\\Program Files\\eCAL\\lib",
    ];
    
    for path in &lib_paths {
        if std::path::Path::new(path).exists() {
            println!("cargo:rustc-link-search=native={}", path);
        }
    }
    
    // 生成 FFI 绑定
    let bindings = bindgen::Builder::default()
        .header("bindings/polyvault.h")
        .allowlist_function("ecal_.*")
        .allowlist_type("ecal_.*")
        .generate()
        .expect("Unable to generate bindings");
    
    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("ecal_bindings.rs"))
        .expect("Couldn't write bindings!");
}
```

---

### src/ecal/ffi.rs

```rust
#![allow(non_upper_case_globals)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]
#![allow(dead_code)]

include!(concat!(env!("OUT_DIR"), "/ecal_bindings.rs"));

// 安全包装
pub type EcalPublisher = *mut ecal_publisher_t;
pub type EcalSubscriber = *mut ecal_subscriber_t;
pub type EcalServer = *mut ecal_server_t;
pub type EcalClient = *mut ecal_client_t;

#[derive(Debug)]
pub enum EcalError {
    InitializationFailed,
    PublisherCreationFailed,
    SubscriberCreationFailed,
    WriteFailed,
    NotConnected,
}

impl std::fmt::Display for EcalError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            EcalError::InitializationFailed => write!(f, "eCAL initialization failed"),
            EcalError::PublisherCreationFailed => write!(f, "Failed to create publisher"),
            EcalError::SubscriberCreationFailed => write!(f, "Failed to create subscriber"),
            EcalError::WriteFailed => write!(f, "Failed to write message"),
            EcalError::NotConnected => write!(f, "Not connected"),
        }
    }
}

impl std::error::Error for EcalError {}

pub type Result<T> = std::result::Result<T, EcalError>;
```

---

### src/ecal/publisher.rs

```rust
use super::ffi::*;
use std::ffi::CString;
use std::ptr;

pub struct Publisher {
    handle: EcalPublisher,
}

impl Publisher {
    pub fn new(topic: &str) -> Result<Self> {
        let topic_c = CString::new(topic).map_err(|_| EcalError::PublisherCreationFailed)?;
        
        unsafe {
            let handle = ecal_publisher_create(topic_c.as_ptr());
            if handle.is_null() {
                return Err(EcalError::PublisherCreationFailed);
            }
            
            Ok(Publisher { handle })
        }
    }
    
    pub fn write(&self, data: &[u8]) -> Result<()> {
        unsafe {
            let result = ecal_write(self.handle, data.as_ptr() as *const _, data.len(), 0);
            if result != 0 {
                return Err(EcalError::WriteFailed);
            }
            Ok(())
        }
    }
    
    pub fn write_string(&self, text: &str) -> Result<()> {
        self.write(text.as_bytes())
    }
}

impl Drop for Publisher {
    fn drop(&mut self) {
        unsafe {
            ecal_publisher_destroy(self.handle);
        }
    }
}
```

---

### src/ecal/subscriber.rs

```rust
use super::ffi::*;
use std::ffi::CString;
use std::os::raw::c_void;

type MessageCallback = Box<dyn Fn(&str, &[u8], i64) + Send>;

struct SubscriberContext {
    callback: MessageCallback,
}

unsafe extern "C" fn message_callback(
    topic_name: *const i8,
    msg: *const c_void,
    size: usize,
    timestamp: i64,
    userdata: *mut c_void,
) {
    let context = &*(userdata as *const SubscriberContext);
    
    let topic = std::ffi::CStr::from_ptr(topic_name)
        .to_string_lossy()
        .into_owned();
    
    let data = std::slice::from_raw_parts(msg as *const u8, size);
    
    (context.callback)(&topic, data, timestamp);
}

pub struct Subscriber {
    handle: EcalSubscriber,
    _context: Box<SubscriberContext>,
}

impl Subscriber {
    pub fn new<F>(topic: &str, callback: F) -> Result<Self>
    where
        F: Fn(&str, &[u8], i64) + Send + 'static,
    {
        let topic_c = CString::new(topic).map_err(|_| EcalError::SubscriberCreationFailed)?;
        
        let context = Box::new(SubscriberContext {
            callback: Box::new(callback),
        });
        
        unsafe {
            let handle = ecal_subscriber_create(
                topic_c.as_ptr(),
                Some(message_callback),
                &*context as *const _ as *mut c_void,
            );
            
            if handle.is_null() {
                return Err(EcalError::SubscriberCreationFailed);
            }
            
            // 防止 context 被释放
            std::mem::forget(context.clone());
            
            Ok(Subscriber {
                handle,
                _context: context,
            })
        }
    }
}

impl Drop for Subscriber {
    fn drop(&mut self) {
        unsafe {
            ecal_subscriber_destroy(self.handle);
        }
    }
}
```

---

### src/lib.rs

```rust
pub mod ecal;
pub mod vault;

pub use ecal::{Publisher, Subscriber};
```

---

### examples/publisher.rs

```rust
use polyvault_rust::Publisher;
use std::thread;
use std::time::Duration;

fn main() {
    // 初始化 eCAL
    unsafe {
        ecal::ffi::ecal_initialize(std::ptr::null(), b"Rust Publisher\0".as_ptr() as *const _);
        ecal::ffi::ecal_set_run_state(1);
    }
    
    // 创建发布者
    let publisher = Publisher::new("polyvault/rust/test").expect("Failed to create publisher");
    
    println!("Publisher created, sending messages...");
    
    // 发送消息
    for i in 0..10 {
        let message = format!("Message {}", i);
        publisher.write_string(&message).expect("Failed to write");
        println!("Sent: {}", message);
        thread::sleep(Duration::from_secs(1));
    }
    
    // 清理
    unsafe {
        ecal::ffi::ecal_finalize();
    }
}
```

---

### examples/subscriber.rs

```rust
use polyvault_rust::Subscriber;
use std::thread;
use std::time::Duration;

fn main() {
    // 初始化 eCAL
    unsafe {
        ecal::ffi::ecal_initialize(std::ptr::null(), b"Rust Subscriber\0".as_ptr() as *const _);
        ecal::ffi::ecal_set_run_state(1);
    }
    
    // 创建订阅者
    let _subscriber = Subscriber::new(
        "polyvault/rust/test",
        |topic, data, timestamp| {
            let message = String::from_utf8_lossy(data);
            println!(
                "Received on '{}': {} (timestamp: {})",
                topic, message, timestamp
            );
        },
    ).expect("Failed to create subscriber");
    
    println!("Subscriber created, waiting for messages...");
    
    // 等待消息
    loop {
        thread::sleep(Duration::from_secs(1));
    }
}
```

---

## 🐍 Python FFI Binding

### 项目结构

```
polyvault-python/
├── setup.py
├── polyvault/
│   ├── __init__.py
│   ├── ecal.py
│   └── vault.py
├── src/
│   └── _polyvault.c
└── examples/
    ├── publisher.py
    └── subscriber.py
```

---

### setup.py

```python
from setuptools import setup, Extension
import sys

module = Extension(
    'polyvault._polyvault',
    sources=['src/_polyvault.c'],
    libraries=['ecal_c'],
    library_dirs=[
        '/usr/lib',
        '/usr/local/lib',
        'C:\\Program Files\\eCAL\\lib',
    ],
    include_dirs=[
        '/usr/include',
        '/usr/local/include',
        'C:\\Program Files\\eCAL\\include',
    ],
)

setup(
    name='polyvault',
    version='0.1.0',
    description='PolyVault Python Bindings',
    packages=['polyvault'],
    ext_modules=[module],
    python_requires='>=3.8',
)
```

---

### src/_polyvault.c

```c
#define PY_SSIZE_T_CLEAN
#include <Python.h>
#include <ecal/ecal_c.h>

typedef struct {
    PyObject_HEAD
    ecal_publisher_t publisher;
} PublisherObject;

static PyObject*
publisher_new(PyTypeObject *type, PyObject *args, PyObject *kwds) {
    PublisherObject *self;
    self = (PublisherObject *)type->tp_alloc(type, 0);
    if (self != NULL) {
        self->publisher = NULL;
    }
    return (PyObject *)self;
}

static int
publisher_init(PublisherObject *self, PyObject *args, PyObject *kwds) {
    static char *kwlist[] = {"topic", NULL};
    char *topic;
    
    if (!PyArg_ParseTupleAndKeywords(args, kwds, "s", kwlist, &topic)) {
        return -1;
    }
    
    self->publisher = ecal_publisher_create(topic);
    if (self->publisher == NULL) {
        PyErr_SetString(PyExc_RuntimeError, "Failed to create publisher");
        return -1;
    }
    
    return 0;
}

static PyObject*
publisher_write(PublisherObject *self, PyObject *args) {
    const char* data;
    Py_ssize_t size;
    
    if (!PyArg_ParseTuple(args, "y#", &data, &size)) {
        return NULL;
    }
    
    int result = ecal_write(self->publisher, data, size, 0);
    if (result != 0) {
        PyErr_SetString(PyExc_RuntimeError, "Failed to write message");
        return NULL;
    }
    
    Py_RETURN_NONE;
}

static void
publisher_dealloc(PublisherObject *self) {
    if (self->publisher != NULL) {
        ecal_publisher_destroy(self->publisher);
    }
    Py_TYPE(self)->tp_free((PyObject *)self);
}

static PyMethodDef Publisher_methods[] = {
    {"write", (PyCFunction)publisher_write, METH_VARARGS, "Write message"},
    {NULL}
};

static PyTypeObject PublisherType = {
    PyVarObject_HEAD_INIT(NULL, 0)
    .tp_name = "polyvault.Publisher",
    .tp_basicsize = sizeof(PublisherObject),
    .tp_dealloc = (destructor)publisher_dealloc,
    .tp_flags = Py_TPFLAGS_DEFAULT,
    .tp_doc = "eCAL Publisher",
    .tp_methods = Publisher_methods,
    .tp_init = (initfunc)publisher_init,
    .tp_new = publisher_new,
};

static PyMethodDef module_methods[] = {
    {NULL}
};

static struct PyModuleDef moduledef = {
    PyModuleDef_HEAD_INIT,
    "_polyvault",
    "PolyVault C Extension",
    -1,
    module_methods,
    NULL,
    NULL,
    NULL,
    NULL
};

PyMODINIT_FUNC
PyInit__polyvault(void) {
    PyObject *m;
    
    if (PyType_Ready(&PublisherType) < 0) {
        return NULL;
    }
    
    m = PyModule_Create(&moduledef);
    if (m == NULL) {
        return NULL;
    }
    
    Py_INCREF(&PublisherType);
    if (PyModule_AddObject(m, "Publisher", (PyObject *)&PublisherType) < 0) {
        Py_DECREF(&PublisherType);
        Py_DECREF(m);
        return NULL;
    }
    
    return m;
}
```

---

### polyvault/ecal.py

```python
"""
PolyVault eCAL Python Bindings
"""

from . import _polyvault

class Publisher:
    """eCAL Publisher"""
    
    def __init__(self, topic: str):
        self._publisher = _polyvault.Publisher(topic)
    
    def write(self, data: bytes) -> None:
        """Write message to topic"""
        self._publisher.write(data)
    
    def write_string(self, text: str) -> None:
        """Write string message"""
        self.write(text.encode('utf-8'))


def initialize(app_name: str = "PolyVault") -> None:
    """Initialize eCAL"""
    _polyvault.initialize(app_name.encode('utf-8'))
    _polyvault.set_run_state(1)


def finalize() -> None:
    """Finalize eCAL"""
    _polyvault.finalize()
```

---

### examples/publisher.py

```python
#!/usr/bin/env python3

import time
from polyvault.ecal import Publisher, initialize, finalize

def main():
    # 初始化
    initialize("Python Publisher")
    
    try:
        # 创建发布者
        publisher = Publisher("polyvault/python/test")
        
        print("Publisher created, sending messages...")
        
        # 发送消息
        for i in range(10):
            message = f"Message {i}"
            publisher.write_string(message)
            print(f"Sent: {message}")
            time.sleep(1)
    
    finally:
        # 清理
        finalize()

if __name__ == "__main__":
    main()
```

---

### examples/subscriber.py

```python
#!/usr/bin/env python3

import time
import signal
from polyvault.ecal import initialize, finalize

# 简化的订阅者示例 (完整实现需要回调支持)
def main():
    initialize("Python Subscriber")
    
    try:
        print("Subscriber created, waiting for messages...")
        
        # 主循环
        while True:
            time.sleep(1)
    
    except KeyboardInterrupt:
        print("\nShutting down...")
    
    finally:
        finalize()

if __name__ == "__main__":
    main()
```

---

## ✅ 最佳实践

### 1. 内存安全

```rust
// ✅ 好：使用 Rust 的所有权系统
pub fn write_message(&self, data: &[u8]) -> Result<()> {
    unsafe {
        ecal_write(self.handle, data.as_ptr(), data.len(), 0)
    }
}

// ❌ 坏：裸指针可能导致悬垂指针
pub fn write_message_bad(&self, ptr: *const u8, len: usize) {
    unsafe {
        ecal_write(self.handle, ptr, len, 0)  // ptr 可能已失效
    }
}
```

### 2. 错误处理

```rust
// ✅ 好：使用 Result 类型
pub fn new(topic: &str) -> Result<Self> {
    let handle = unsafe { ecal_publisher_create(topic.as_ptr()) };
    if handle.is_null() {
        Err(EcalError::PublisherCreationFailed)
    } else {
        Ok(Publisher { handle })
    }
}

// ❌ 坏：panic 不是好的错误处理方式
pub fn new_panic(topic: &str) -> Self {
    let handle = unsafe { ecal_publisher_create(topic.as_ptr()) };
    assert!(!handle.is_null(), "Failed to create publisher");  // 可能 panic
    Publisher { handle }
}
```

### 3. 线程安全

```rust
// ✅ 好：实现 Send + Sync
unsafe impl Send for Publisher {}
unsafe impl Sync for Publisher {}

// ❌ 坏：未标记线程安全
pub struct Publisher {
    handle: *mut ecal_publisher_t,  // 默认不是 Send/Sync
}
```

### 4. 资源管理

```rust
// ✅ 好：使用 Drop trait
impl Drop for Publisher {
    fn drop(&mut self) {
        unsafe {
            ecal_publisher_destroy(self.handle);
        }
    }
}

// ❌ 坏：手动清理容易遗漏
pub fn cleanup(publisher: &Publisher) {
    unsafe {
        ecal_publisher_destroy(publisher.handle);  // 需要手动调用
    }
}
```

---

## 🔧 故障排除

### 问题 1: eCAL 初始化失败

**错误**:
```
[ERROR] Failed to initialize eCAL
```

**解决方案**:
1. 检查 eCAL 是否正确安装
2. 确认库文件在系统路径中
3. 检查 eCAL 配置文件 (`ecal.ini`)

---

### 问题 2: 链接错误

**错误**:
```
undefined reference to `ecal_publisher_create'
```

**解决方案**:
```bash
# 确认库文件存在
ldconfig -p | grep ecal

# 添加库路径
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# 重新编译
cargo clean && cargo build
```

---

### 问题 3: 段错误 (Segmentation Fault)

**原因**: 访问已释放的内存

**调试**:
```bash
# 使用 valgrind (Linux)
valgrind --leak-check=full ./target/debug/example

# 使用 AddressSanitizer
export RUSTFLAGS="-Z sanitizer=address"
cargo run
```

---

**文档维护**: PolyVault Core Team  
**反馈邮箱**: dev@polyvault.io  
**最后更新**: 2026-03-15
