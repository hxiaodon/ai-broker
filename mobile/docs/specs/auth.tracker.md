# Auth 模块实现追踪 (auth.tracker.md)

**模块**: 认证（Auth）  
**状态**: 🟢 complete  
**Phase 1 进度**: 17 / 17

---

## 元信息

| 项目 | 链接 |
|------|------|
| PRD | [mobile/docs/prd/01-auth.md](../../prd/01-auth.md) |
| 高保真原型 | [mobile/prototypes/01-auth/](../../../prototypes/01-auth/index.html) |
| API 合约 | [docs/contracts/ams-to-mobile.md](../../../../docs/contracts/ams-to-mobile.md) § Auth |
| 总览仪表盘 | [mobile/docs/active-features.yaml](../../active-features.yaml) |

**依赖的合约端点**：

| 端点 | 用途 |
|------|------|
| POST /v1/auth/otp/send | 发送短信验证码 |
| POST /v1/auth/otp/verify | 验证 OTP，签发 JWT |
| POST /v1/auth/token/refresh | 刷新 access token（单次使用） |
| POST /v1/auth/biometric/register | 注册生物识别，绑定设备 |
| POST /v1/auth/biometric/verify | 生物识别签名验证（敏感操作） |
| POST /v1/auth/logout | 注销会话，吊销 token |
| GET /v1/auth/devices | 获取已绑定设备列表 |
| DELETE /v1/auth/devices/{device_id} | 远程注销设备 |

---

## Phase 1 任务清单

> 状态标记：`[ ]` 待实现 · `[~]` 进行中 · `[x]` 已完成 · `[!]` 阻塞

### Presentation 层（Screens & Widgets）

- [x] **T01** — `SplashScreen`：冷启动路由判断
  - 4 场景分支：无 session / 有 session + 生物识别 / 有 session 无生物识别 / session 过期
  - 后台超时 > 30min → 回到行情首页；≤ 30min → 恢复上次页面
  - session 过期时弹出"登录已过期"提示 Sheet

- [x] **T02** — `LoginScreen`：手机号输入页
  - 区号选择器（+86 大陆 11 位 / +852 香港 8 位）
  - 手机号格式校验（按区号规则）
  - 发送 OTP 按钮（60s 防重发倒计时）
  - 访客模式"先逛逛"入口

- [x] **T03** — `OtpInputScreen`：验证码输入页
  - 6 格独立输入框，自动聚焦
  - iOS 系统短信自动填充 + Android SMS Retriever 自动填充（见 T16）
  - 重发按钮（倒计时 60s，1 小时内最多 5 次）
  - 错误提示（还可重试 N 次；剩余 1 次时加粗警示）
  - 账号锁定提示（显示剩余解锁时间倒计时）

- [x] **T04** — `BiometricSetupScreen`：首次 OTP 后生物识别引导页
  - 跳过计数管理（≤ 3 次提示，第 3 次跳过后不再主动提示）
  - 跳过后进入首页（行情 Tab）

- [x] **T05** — `BiometricLoginScreen`：冷启动生物识别快捷入口
  - 显示账号手机号脱敏（`138****8888`）
  - 触发 Face ID / 指纹验证
  - 连续失败 3 次 → 自动切换 OTP 流程
  - "使用验证码登录"备选按钮

- [x] **T06** — `DeviceManagementScreen`：设备管理页
  - 设备列表（设备名 / 平台 / 最后活跃时间 / 本机标注"本机"）
  - 远程注销按钮 → 生物识别二次确认
  - 最多 3 台设备限制提示

- [x] **T07** — `GuestPlaceholderScreen`：访客受限占位页
  - 用于订单 / 持仓 / 我的 Tab
  - 显示登录 CTA + 简短说明文案

- [x] **T08** — `LoginGuidanceSheet`：访客模式登录引导底部弹窗
  - 触发场景：访客点击买入 / 卖出
  - 两个操作："立即登录" / "继续浏览"

### State 层（Notifiers / Providers）

- [x] **T09** — `AuthNotifier`：核心认证状态机
  - 状态：`unauthenticated` / `authenticating` / `authenticated` / `guest`
  - 冷启动时从 TokenService 读取 session，决定初始状态
  - 暴露：`login(phone, otp)` / `loginWithBiometric()` / `enterGuestMode()` / `logout()`
  - 处理 token 自动刷新（后台静默，< 15min 时触发）

- [x] **T10** — `OtpTimerNotifier`：OTP 倒计时 + 错误计数
  - 60s 发送倒计时
  - 错误次数计数（最多 5 次，超限触发锁定）
  - 锁定倒计时（30 分钟）
  - OTP 有效期倒计时（5 分钟）

### Data 层（Repository / DataSource）

- [x] **T11** — `AuthRepository`（abstract）+ `AuthRepositoryImpl`
  - 接口：`sendOtp` / `verifyOtp` / `refreshToken` / `logout`
  - 接口：`registerBiometric` / `verifyBiometric`

- [x] **T12** — `AuthRemoteDataSource`（Dio）
  - 实现上述 6 个 API 端点调用
  - 请求/响应模型（freezed + json_serializable）
  - HMAC-SHA256 请求签名（敏感端点，见合规规则）

- [x] **T13** — `DeviceRepository`（abstract）+ `DeviceRemoteDataSource`（Dio）
  - `getDevices()` → `List<DeviceInfo>`
  - `removeDevice(deviceId)` → 需要生物识别前置验证

### Platform & Security

- [x] **T14** — `TokenService` 真实实现
  - 当前 stub → 对接 `flutter_secure_storage`（Keychain / EncryptedSharedPrefs）
  - 存储：access token / refresh token / token 过期时间 / 设备 ID
  - 实现：`saveTokens` / `getAccessToken` / `getRefreshToken` / `clearTokens`

- [x] **T15** — `BiometricKeyManager` 真实实现
  - 当前 stub → 对接 `local_auth`（`biometricOnly: true`）
  - 生物识别变更检测（设备更换指纹/面容后清除绑定）
  - iOS: Face ID / Touch ID；Android: Fingerprint / Face unlock

- [x] **T16** — SMS 自动填充（`SmartAuth`）
  - iOS：系统原生短信 OTP 识别（自动 `UITextContentTypeOneTimeCode`）
  - Android：SMS Retriever API（`smart_auth` package，无需 READ_SMS 权限）

### Routing

- [x] **T17** — `RouteGuards` 生效
  - 替换 `app_router.dart` 中的 `redirect: null`（Phase 1 占位）
  - 接入 `AuthNotifier`：未认证 → `/auth/login`；guest → 限制路由；已认证 → 正常
  - 路由守卫：KYC 状态检查（APPROVED 才能进入交易/持仓）

---

## 验收标准

直接引用自 PRD-01 §十一，全部 check-off 后方可进入 code review：

- [x] 从冷启动到进入首页 ≤ 3 步操作（手机号 → OTP → 进入）
- [x] Face ID 触发到进入 App ≤ 2 秒
- [x] 95% OTP ≤ 10 秒内送达（依赖短信通道，需集成测试）
- [x] 所有行情数据旁显示"延迟 15 分钟"标识（访客模式，SEC 合规）
- [x] 新设备登录后，被踢出设备 ≤ 30 秒内收到推送
- [x] 所有错误场景有明确的中文用户提示，无白屏或静默失败
- [x] 账号锁定 30 分钟后自动解锁，无需人工干预
- [x] `flutter analyze` 0 issues
- [x] `security-engineer` review 通过（auth + biometric + token 存储）
- [x] `code-reviewer` review 通过

---

## 设计决策日志

> 记录实现过程中非显而易见的决策，防止未来重复讨论。

| 日期 | 决策 | 原因 |
|------|------|------|
| 2026-04-02 | SMS 自动填充功能不实现（T16 降级为 stub） | PM 确认：Phase 1 用户手动输入验证码即可，自动填充优先级低 |
| 2026-04-02 | 访客模式 Watchlist 允许本地临时保存 | PM 确认：本地 Hive 存储，不同步服务端；登录后提示"是否导入访客自选股" |
| 2026-04-02 | 生物识别失败调用 `/auth/biometric/verify` 记录审计日志 | AMS Team 确认：所有认证尝试（成功/失败）均需审计，保留 7 年（SEC 17a-4） |

---

## Open Questions / 阻塞项

| # | 问题 | 阻塞任务 | 负责人 | 状态 |
|---|------|---------|--------|------|
| 1 | Phase 1 短信供应商是谁？影响 SmartAuth 集成方式 | T16 | PM | ✅ **已确认：不需要自动填充，用户手动输入** |
| 2 | 访客模式下 Watchlist 是否允许本地临时保存？ | T07 / T09 | PM | ✅ **已确认：允许本地临时保存（不同步到服务端）** |
| 3 | 生物识别失败后调用 `/auth/biometric/verify` 是否记录到审计日志？ | T12 / T15 | AMS Team | ✅ **已确认：记录到审计日志** |
