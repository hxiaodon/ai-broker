---
provider: mobile
consumer: mobile/h5-webview
protocol: JSBridge
spec_file: mobile/docs/specs/10-jsbridge-spec.md
status: DRAFT
version: 0
created: 2026-03-13
last_updated: 2026-03-13
last_reviewed: null
sync_strategy: provider-owns
---

# Mobile (Flutter) → H5 WebView 接口契约

## 契约范围

Flutter 宿主与 H5 WebView 页面之间的双向通信协议。本契约定义 JSBridge 调用接口，使嵌入在 Flutter WebView 中的 H5 页面能够访问原生能力（相机、生物识别、导航），同时 Flutter 宿主能够向 H5 页面注入运行时上下文（JWT token、主题、语言）。

> **详细 JSBridge 规范**: [mobile/docs/specs/10-jsbridge-spec.md](../../mobile/docs/specs/10-jsbridge-spec.md)

## 接口列表

### Flutter → H5（宿主向 WebView 注入）

| 方法 | 用途 | 触发时机 | 版本引入 |
|------|------|---------|---------|
| setToken | 传递 JWT access token | WebView 加载完成 + token 刷新时 | v1 |
| setTheme | 主题切换（light / dark / system） | WebView 加载完成 + 用户切换主题时 | v1 |
| setLocale | 语言设置（zh-CN / zh-HK / en-US） | WebView 加载完成 + 用户切换语言时 | v1 |
| goBack | 返回控制（通知 H5 执行返回逻辑或关闭） | 用户点击原生返回按钮时 | v1 |

### H5 → Flutter（WebView 请求原生能力）

| 方法 | 用途 | 返回值 | 版本引入 |
|------|------|--------|---------|
| getToken | 获取当前 JWT access token | `{token: string}` | v1 |
| navigate | 路由跳转到原生页面（如交易、持仓、设置） | `{success: boolean}` | v1 |
| showToast | 显示原生提示（success / error / warning） | void | v1 |
| openCamera | 调起相机（KYC 拍照：身份证正反面、自拍） | `{imageUri: string}` | v1 |
| getBiometricAuth | 请求生物识别认证（指纹/面容） | `{authenticated: boolean}` | v1 |
| closeWebView | 关闭当前 WebView 并返回原生页面 | void | v1 |

> **Note**: 接口列表为初始占位，待各域工程师在实现阶段填充具体参数与响应 schema。

## 数据流向

Flutter 宿主在 WebView 加载完成时注入 JWT token、主题配置和语言设置。H5 页面通过 JSBridge 回调获取原生能力：调起相机完成 KYC 拍照、请求生物识别认证、路由跳转到原生交易/持仓页面、显示原生 Toast 提示。所有调用均为异步，基于 Promise 机制返回结果。

## 通信协议

- **所有 JSBridge 调用必须包含 `callbackId`**（UUID），用于请求-响应匹配
- **消息格式**: JSON 序列化，通过 `postMessage` / `JavaScriptChannel` 传输
- **Token 注入时机**:
  - WebView 首次加载完成（`onPageFinished`）
  - AMS refresh token 成功后（主动推送新 token）
- **错误处理**: H5 调用超时 5 秒未响应视为失败，返回 `{error: "TIMEOUT"}`

## H5 页面使用场景

| 页面 | 路径 | 用途 | 需要的 JSBridge 能力 |
|------|------|------|---------------------|
| KYC 文档上传 | /h5/kyc/upload | 身份证件拍照上传 | openCamera, getBiometricAuth, getToken |
| 合规披露文件 | /h5/compliance/* | 风险揭示书、用户协议签署 | getToken, navigate, closeWebView |
| 营销活动页 | /h5/promo/* | 开户奖励、邀请返佣 | navigate, showToast, closeWebView |
| 帮助中心 | /h5/help/* | FAQ、客服入口 | navigate, closeWebView |

## 变更流程

1. 任何一方发起变更 → 在 `mobile/docs/threads/` 开 thread
2. Flutter 工程师与 H5 工程师共同评估影响
3. 达成一致后并行更新：JSBridge 实现代码 + 本契约文件 (version +1) + 详细规范文件
4. Thread 标记 RESOLVED

## Changelog

暂无变更记录。
