# JSBridge 规格文档：H5 ↔ Flutter 通信接口

> **文档状态**: Phase 1 正式版
> **版本**: v1.0
> **日期**: 2026-03-13
> **适用范围**: Flutter App 内嵌 WebView（H5 页面） ↔ Flutter Native 双向通信

---

## 一、概述

### 1.1 使用场景

App 内部分功能页面以 H5 形式内嵌在 Flutter WebView 中（如协议文档、公告页、部分活动页），需要与 Flutter Native 进行双向通信：

| 方向 | 场景 |
|------|------|
| H5 → Native | 打开邮件客户端、分享文件、关闭 WebView、获取 Auth Token |
| Native → H5 | 主题变更通知、用户认证状态更新、网络状态通知 |

### 1.2 技术方案

Flutter 使用 `webview_flutter ^4.10.0` 实现 WebView，通过以下机制通信：

- **H5 → Native**：JavaScript 调用 `window.FlutterBridge.postMessage(message)` → Native 通过 `JavaScriptChannel` 接收
- **Native → H5**：`webViewController.runJavaScript("window.onNativeMessage(JSON.stringify({event, data}))")`

### 1.3 安全要求

- **白名单校验**：WebView 只加载白名单域名（`*.brokerage.com`），外部域名不注入 Bridge
- **Token 按需返回**：H5 请求 `getAuthToken` 时，Native 校验当前页面域名后才返回
- **方法白名单**：Bridge 只处理本文档定义的 method，未知 method 一律静默忽略并记录日志

---

## 二、消息格式

### 2.1 H5 → Native 消息格式

```typescript
interface H5ToNativeMessage {
  method: string;         // 方法名（见 Section 3）
  params?: object;        // 可选参数
  callbackId?: string;    // 可选：UUID，用于关联异步响应
}

```typescript
// 调用示例
window.FlutterBridge.postMessage(JSON.stringify({
  method: "openEmailClient",
  params: { email: "support@brokerage.com", subject: "账户问题" },
  callbackId: "cb-1234"
}));
```

### 2.2 Native → H5 响应格式（异步回调）

```typescript
interface NativeCallbackMessage {
  callbackId: string;     // 与请求中的 callbackId 对应
  success: boolean;
  data?: object;
  error?: { code: string; message: string };
}

// H5 接收回调
window.onNativeCallback = function(jsonStr) {
  const msg = JSON.parse(jsonStr);  // NativeCallbackMessage
  // 根据 msg.callbackId 路由到对应的 Promise resolver
};
```

### 2.3 Native → H5 主动推送格式

```typescript
interface NativeEventMessage {
  event: string;          // 事件名（见 Section 4）
  data?: object;
}

// H5 监听事件
window.onNativeEvent = function(jsonStr) {
  const msg = JSON.parse(jsonStr);  // NativeEventMessage
  // 根据 msg.event 分发处理
};
```

---

## 三、H5 → Native 方法定义

### 3.1 openEmailClient（打开邮件客户端）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | ✅ | 收件人邮箱 |
| subject | string | ❌ | 邮件主题（预填） |
| body | string | ❌ | 邮件正文（预填） |

```json
// 请求
{ "method": "openEmailClient", "params": { "email": "support@brokerage.com", "subject": "反馈" }, "callbackId": "cb-001" }

// 响应（成功）
{ "callbackId": "cb-001", "success": true }

// 响应（失败：设备无邮件客户端）
{ "callbackId": "cb-001", "success": false, "error": { "code": "NO_EMAIL_CLIENT", "message": "未找到邮件应用" } }
```

**Flutter 实现**：
```dart
case "openEmailClient":
  final email = params["email"] as String;
  final subject = params["subject"] as String? ?? "";
  final uri = Uri(scheme: "mailto", path: email, query: "subject=$subject");
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
    _sendCallback(callbackId, success: true);
  } else {
    _sendCallback(callbackId, success: false, errorCode: "NO_EMAIL_CLIENT");
  }
```

### 3.2 shareFile（分享文件）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| url | string | ✅ | 文件下载 URL（必须为白名单域名） |
| filename | string | ✅ | 文件名（含扩展名，如 w8ben.pdf） |
| mimeType | string | ❌ | MIME 类型，默认 `application/octet-stream` |

```json
// 请求
{ "method": "shareFile", "params": { "url": "https://s3.../w8ben.pdf", "filename": "w8ben_2026.pdf", "mimeType": "application/pdf" }, "callbackId": "cb-002" }

// 响应
{ "callbackId": "cb-002", "success": true }
```

**安全校验**：URL 域名必须在白名单内（`*.brokerage.com`, `*.amazonaws.com/brokerage-docs/`），否则拒绝并返回 `UNSAFE_URL` 错误。

### 3.3 closeWebView（关闭 WebView）

```json
// 请求（无参数）
{ "method": "closeWebView" }
// 无需 callbackId，Native 直接弹出 WebView 页面
```

**注**：H5 主动触发关闭（如用户点击自定义"返回"按钮）。

### 3.4 getAuthToken（获取当前 Auth Token）

用于 H5 页面访问需要认证的 API（如用户专属内容）时，从 Native 获取当前有效的 Access Token，避免 H5 自行存储凭据。

```json
// 请求
{ "method": "getAuthToken", "callbackId": "cb-003" }

// 响应（成功）
{ "callbackId": "cb-003", "success": true, "data": { "access_token": "eyJ...", "expires_at": "2026-03-13T15:00:00Z" } }

// 响应（未登录）
{ "callbackId": "cb-003", "success": false, "error": { "code": "NOT_AUTHENTICATED" } }
```

**安全要求**：
- Native 校验当前 WebView URL 域名，只有白名单域名才返回 Token
- H5 收到 Token 后只在当前请求使用，不缓存（内存变量即可）
- Token 过期时 H5 重新调用 `getAuthToken` 获取新 Token（Native 自动处理 Refresh）

### 3.5 setAuthContext（H5 完成认证后通知 Native）

用于 H5 中完成某些认证流程后，将结果回传给 Native（如 H5 KYC 补件提交完成）。

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| action | string | ✅ | 完成的操作类型（见下表） |
| result | string | ✅ | `SUCCESS` \| `FAILED` \| `CANCELLED` |
| data | object | ❌ | 附加数据 |

**action 枚举**：

| action | 触发场景 | Native 响应动作 |
|--------|---------|--------------|
| `KYC_SUPPLEMENT_SUBMITTED` | H5 KYC 补件提交完成 | 关闭 WebView，刷新 KYC 状态 |
| `AGREEMENT_SIGNED` | H5 协议签署完成 | 关闭 WebView，通知相关模块 |
| `W8BEN_UPDATE_SUBMITTED` | W-8BEN 更新提交完成 | 关闭 WebView，刷新税务状态 |

```json
// 请求
{ "method": "setAuthContext", "params": { "action": "KYC_SUPPLEMENT_SUBMITTED", "result": "SUCCESS" } }
// Native 执行对应动作后弹出 WebView
```

### 3.6 getDeviceInfo（获取设备信息）

```json
// 请求
{ "method": "getDeviceInfo", "callbackId": "cb-004" }

// 响应
{
  "callbackId": "cb-004",
  "success": true,
  "data": {
    "platform": "ios",          // "ios" | "android"
    "os_version": "18.0",
    "app_version": "1.0.0",
    "language": "zh-CN",
    "theme": "dark"             // "light" | "dark"
  }
}
```

---

## 四、Native → H5 事件推送定义

### 4.1 onThemeChange（主题变更）

当用户在设置中切换颜色主题（浅色/深色）或涨跌颜色方案时，Native 主动通知 H5 刷新样式。

```json
// Native 推送
{ "event": "onThemeChange", "data": { "theme": "dark", "color_scheme": "RED_UP" } }
```

**H5 处理**：根据 `theme` 切换 CSS class（如 `.dark-mode`），根据 `color_scheme` 调整涨跌色显示。

### 4.2 onAuthStateChange（认证状态变更）

当用户在 Native 侧登出、token 过期或账户被强制下线时，通知 H5。

```json
{ "event": "onAuthStateChange", "data": { "state": "LOGGED_OUT" } }
// state: "LOGGED_IN" | "LOGGED_OUT" | "TOKEN_REFRESHED"
```

**H5 处理**：收到 `LOGGED_OUT` 时清除本地状态，停止 API 调用。

### 4.3 onNetworkStateChange（网络状态变更）

```json
{ "event": "onNetworkStateChange", "data": { "connected": false } }
```

**H5 处理**：断网时显示离线提示 Banner，恢复时自动刷新页面数据。

### 4.4 onLanguageChange（语言变更）

```json
{ "event": "onLanguageChange", "data": { "language": "zh-TW" } }
```

---

## 五、Flutter 实现参考

### 5.1 注册 Bridge（WebView 初始化）

```dart
// 使用 webview_flutter
late final WebViewController _controller;

_controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..addJavaScriptChannel(
    'FlutterBridge',
    onMessageReceived: (JavaScriptMessage message) {
      final msg = jsonDecode(message.message);
      _handleBridgeMessage(msg, _controller);
    },
  )
  ..loadRequest(Uri.parse(webViewUrl));

// Widget
WebViewWidget(controller: _controller)
```

### 5.2 处理 H5 消息

```dart
void _handleBridgeMessage(Map<String, dynamic> msg, WebViewController ctrl) {
  final method = msg["method"] as String;
  final params = msg["params"] as Map<String, dynamic>? ?? {};
  final callbackId = msg["callbackId"] as String?;

  switch (method) {
    case "openEmailClient":
      _openEmailClient(params, callbackId, ctrl);
    case "shareFile":
      _shareFile(params, callbackId, ctrl);
    case "closeWebView":
      Navigator.of(context).pop();
    case "getAuthToken":
      _getAuthToken(callbackId, ctrl);
    case "setAuthContext":
      _handleAuthContext(params);
    case "getDeviceInfo":
      _sendDeviceInfo(callbackId, ctrl);
    default:
      // 未知 method：静默忽略，记录日志
      logger.warn("Unknown JSBridge method: $method");
  }
}
```

### 5.3 Native 主动推送事件

```dart
void sendNativeEvent(String event, Map<String, dynamic> data) {
  final json = jsonEncode({"event": event, "data": data});
  webViewController.runJavaScript("window.onNativeEvent('$json')");
}

// 示例：主题变更时通知所有 WebView
sendNativeEvent("onThemeChange", {"theme": "dark", "color_scheme": "RED_UP"});
```

---

## 六、H5 端 SDK 参考

H5 页面应引入以下 Bridge SDK（由前端团队维护）：

```typescript
// bridge.ts
class FlutterBridge {
  private callbacks = new Map<string, (data: any) => void>();

  constructor() {
    window.onNativeCallback = (jsonStr: string) => {
      const msg = JSON.parse(jsonStr);
      const resolver = this.callbacks.get(msg.callbackId);
      if (resolver) {
        resolver(msg);
        this.callbacks.delete(msg.callbackId);
      }
    };
    window.onNativeEvent = (jsonStr: string) => {
      const msg = JSON.parse(jsonStr);
      this.dispatchEvent(msg.event, msg.data);
    };
  }

  call(method: string, params?: object): Promise<any> {
    return new Promise((resolve, reject) => {
      const callbackId = crypto.randomUUID();
      this.callbacks.set(callbackId, (msg) => {
        if (msg.success) resolve(msg.data);
        else reject(msg.error);
      });
      window.FlutterBridge?.postMessage(JSON.stringify({ method, params, callbackId }));
    });
  }

  // 使用示例
  async getToken(): Promise<string> {
    const result = await this.call("getAuthToken");
    return result.access_token;
  }
}

export const bridge = new FlutterBridge();
```

---

## 七、验收标准

| 场景 | 标准 |
|------|------|
| 白名单校验 | 非白名单域名内的 H5 调用 Bridge 方法一律静默忽略 |
| getAuthToken 安全 | 非白名单域名请求 Token 返回 NOT_AUTHORIZED 错误 |
| callbackId 路由 | 并发多个 Bridge 调用时，回调正确路由到对应 Promise |
| 主题同步 | 设置页切换主题 500ms 内 WebView 内容更新 |
| 认证状态同步 | 强制下线后 WebView 停止 API 调用，不再使用旧 Token |
| shareFile 安全 | 非白名单 URL 分享请求返回 UNSAFE_URL 错误 |
| Bridge 不可用时 | H5 需检测 `window.FlutterBridge` 是否存在，不可用时降级（如在浏览器中测试） |
