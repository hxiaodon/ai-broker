# H5 WebView vs Flutter Native — 架构决策记录

**决策日期**: 2026-04-01  
**状态**: ✅ 已确认（PM 批准）  
**适用版本**: Flutter 3.41.4 / Dart 3.11.1

---

## 决策结论

**95% Native + 5% H5**：绝大多数页面用 Flutter Native 实现；仅对内容主导、无交互安全要求的少数页面使用 H5 WebView。

---

## 决策框架

### 必须 Native 的条件（满足任意一条）

| 条件 | 原因 |
|------|------|
| 需要摄像头/生物识别 | 平台 API，H5 无法安全访问 Secure Enclave / Android Keystore |
| 需要 HMAC-SHA256 请求签名 | 密钥不能暴露在 WebView JS 环境中 |
| 包含交易、下单、资金操作 | SEC/SFC 合规：需要原生 HMAC 签名 + 幂等键 |
| 需要实时行情 / WebSocket | 性能敏感，Native 渲染更流畅 |
| 包含账户余额、持仓展示 | 安全敏感，不能通过 H5 泄露 |
| 包含 KYC 文件上传、OCR | 依赖 `image_picker` + Method Channel |
| 需要 SecureStorage 读写 | Keychain/EncryptedSharedPrefs 不能被 JS 直接访问 |

### 适合 H5 的条件（须全部满足）

| 条件 | 原因 |
|------|------|
| 以阅读内容为主 | 无性能瓶颈 |
| 无原生硬件依赖 | 不需要摄像头、生物识别、安全存储 |
| 需要频繁更新（不发版） | 法律文本、帮助中心内容随监管要求随时变更 |
| 身份上下文由 JSBridge 注入 | `setAuthContext` 传入 token，页面本身不持有凭证 |

---

## H5 页面清单（约 5 页）

| 页面 | 所属 PRD | 原因 |
|------|---------|------|
| Help Center / FAQ | PRD-08 Settings | 内容频繁更新，无硬件依赖 |
| Privacy Policy | PRD-01 Auth | 法律文本，随合规要求变更，无交互 |
| Terms of Service | PRD-01 Auth | 同上 |
| KYC Step 7 — 风险披露书阅读 | PRD-02 KYC | 长篇 PDF/HTML 内容展示 + 滚动确认 |
| KYC Step 8 — 开户协议文本 | PRD-02 KYC | 协议纯阅读展示，签名由 Native 完成 |

> **注意**：KYC Step 8 仅用于协议文本展示。用户的手写签名/电子签名动作仍在 Native 完成，H5 通过 `window.JSBridge.closeWebView({ signed: true })` 回调结果。

---

## Native 页面清单（约 95%）

| 模块 | 关键原因 |
|------|---------|
| **Auth** — 登录、注册、OTP、生物识别设置 | `local_auth`、SecureStorage、HMAC 签名 |
| **KYC Steps 1-6** — 个人信息、证件上传、活体检测、SSN/HKID 采集、开户协议签名 | 摄像头 OCR、生物识别、HMAC、合规签名 |
| **Market** — 行情列表、股票详情、K 线图、搜索 | WebSocket 实时数据、Syncfusion 图表渲染 |
| **Trading** — 下单、订单列表、持仓 | HMAC-SHA256 请求签名、幂等键、SEC/SFC 合规 |
| **Portfolio** — 持仓、P&L、交易历史 | 持仓数据安全性，Decimal 精确计算展示 |
| **Funding** — 出入金、银行卡绑定、资金记录 | AML 合规、SecureStorage、银行账号加密 |
| **Settings** — 安全设置、个人资料、通知设置 | 生物识别管理、SecureStorage |

---

## KYC 流程细粒度拆分

```
Step 1: 个人信息填写          → Native（输入表单，含 SSN 加密）
Step 2: 证件类型选择          → Native（选择控件）
Step 3: 证件拍照/上传         → Native（image_picker + Method Channel）
Step 4: 活体检测              → Native（摄像头 + 平台 SDK）
Step 5: 税务信息填写          → Native（SSN/ITIN 加密写入 SecureStorage）
Step 6: W-8/W-9 表格          → Native（需要 HMAC 签名提交）
Step 7: 风险披露书阅读        → H5（setAuthContext + 滚动确认回调）
Step 8: 开户协议文本展示      → H5（阅读展示，签名动作回 Native）
```

---

## JSBridge 充足性评估

现有 `docs/specs/10-jsbridge-spec.md` 定义的接口已完全覆盖上述 H5 页面需求：

| 接口 | 用途 |
|------|------|
| `setAuthContext(token, userId)` | Flutter 向 H5 注入身份 |
| `getAuthToken()` → `Promise<string>` | H5 主动获取最新 token（token 刷新后） |
| `closeWebView(result?)` | H5 关闭并回传结果（如 `{ signed: true }`） |
| `navigateTo(route)` | H5 触发原生路由跳转（如 KYC Step 8 完成后跳首页） |

**结论：无需新增 JSBridge 接口**，当前 spec 已完整。

---

## 实现指南

### Flutter 侧（WebView 宿主）

```dart
// 在 WebView 加载完成后注入 auth context
controller.runJavaScript(
  'window.JSBridge?.setAuthContext("${token}", "${userId}")',
);

// 监听 closeWebView 回调
JavascriptChannel(
  name: 'FlutterBridge',
  onMessageReceived: (msg) {
    final result = jsonDecode(msg.message);
    if (result['signed'] == true) {
      // 推进 KYC 步骤
    }
  },
)
```

### H5 侧（React）

```typescript
// 读取身份上下文
const token = await window.JSBridge.getAuthToken();

// 完成后通知 Flutter
window.FlutterBridge.postMessage(JSON.stringify({ signed: true }));
```

---

## 变更历史

| 日期 | 变更 | 作者 |
|------|------|------|
| 2026-04-01 | 初版决策记录，PM 确认 | mobile-engineer |
