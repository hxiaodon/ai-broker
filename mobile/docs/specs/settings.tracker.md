# Settings Module — Phase 1 Tracker

> 关联 PRD: `mobile/docs/prd/08-settings-profile.md`
> 关联原型: `mobile/prototypes/08-settings-profile/hifi/`
> 关联契约: `docs/contracts/ams-to-mobile.md` (§ Profile, § Notifications, § Auth/devices)
> Tracker 创建: 2026-05-01

---

## 验收标准

- [ ] `flutter analyze` 0 issues
- [ ] `flutter test integration_test/settings/` 全绿
- [ ] 所有 PRD Phase 1 功能点实现完毕
- [ ] 安全设置页：profile_screen + security_settings_screen 添加 ScreenProtectionMixin
- [ ] 个人资料页：PII 字段按 PRD §5.1 脱敏规则渲染
- [ ] 出金生物识别开关不可关闭（disabled + opacity 0.5）
- [ ] 安全通知不可关闭（NotificationCategory.security 无 toggle）
- [ ] 换手机号：旧号 OTP → 新号 OTP → 后台更新 → 所有设备强制登出
- [ ] 注销账户：前置条件检查 → 警告弹窗 → OTP 验证 → 最终确认弹窗
- [ ] code-reviewer + security-engineer 审核通过

---

## Phase 1 任务清单

### Domain 层
- [x] T01 `domain/entities/user_profile.dart` — UserProfile freezed 实体（含 PII 脱敏 getters）
- [x] T02 `domain/entities/account_status.dart` — AccountStatus freezed 实体（KYC/AML/W-8BEN 状态）
- [x] T03 `domain/entities/notification_preferences.dart` — NotificationPreferences freezed 实体
- [x] T04 `domain/entities/device_info.dart` — DeviceInfo freezed 实体
- [x] T05 `domain/entities/trade_settings.dart` — TradeSettings freezed 实体（6 个交易偏好）
- [x] T06 `domain/entities/display_settings.dart` — DisplaySettings（涨跌色方案，本地）
- [x] T07 `domain/repositories/settings_repository.dart` — 抽象接口

### Data 层
- [x] T08 `data/remote/models/user_profile_model.dart` — freezed + json_serializable
- [x] T09 `data/remote/models/account_status_model.dart` — freezed + json_serializable
- [x] T10 `data/remote/models/notification_preferences_model.dart` — freezed + json_serializable
- [x] T11 `data/remote/models/device_info_model.dart` — freezed + json_serializable
- [x] T12 `data/remote/settings_mappers.dart` — Model → Domain mapper
- [x] T13 `data/remote/settings_remote_data_source.dart` — Dio HTTP 实现
- [x] T14 `data/settings_repository_impl.dart` — Repository 实现 + Riverpod provider

### Application 层
- [x] T15 `application/user_profile_notifier.dart` — FutureProvider，autoDispose
- [x] T16 `application/account_status_notifier.dart` — FutureProvider，autoDispose
- [x] T17 `application/notification_preferences_notifier.dart` — Notifier（远程读写）
- [x] T18 `application/device_list_notifier.dart` — Notifier（列表 + 远程注销设备）
- [x] T19 `application/display_settings_notifier.dart` — Notifier（SharedPreferences 本地）
- [x] T20 `application/trade_settings_notifier.dart` — Notifier（SharedPreferences 本地）
- [x] T21 `application/change_phone_notifier.dart` — Notifier（三步换号流程状态机）

### Presentation 层
- [x] T22 `presentation/screens/settings_home_screen.dart` — 我的主页（用户卡片 + 资产摘要 + 菜单）
- [x] T23 `presentation/screens/profile_screen.dart` — 个人资料（只读 + PII 脱敏 + W-8BEN + ScreenProtectionMixin）
- [x] T24 `presentation/screens/security_settings_screen.dart` — 安全设置（生物识别 + 设备列表 + 换手机 + 锁定 + 注销）
- [x] T25 `presentation/screens/general_settings_screen.dart` — 通用设置（涨跌色 + 推送通知 + 语言占位）
- [x] T26 `presentation/screens/trade_settings_screen.dart` — 交易设置（6 个偏好项）
- [x] T27 `presentation/screens/help_screen.dart` — 帮助（WebView 帮助中心 + 关于 + 联系客服）
- [x] T28 `presentation/screens/change_phone_screen.dart` — 换手机号（旧号 OTP + 新号 OTP 两步流程）
- [x] T29 `presentation/screens/account_deactivation_screen.dart` — 注销账户（前置检查 + OTP 确认流程）

### 路由接入
- [x] T30 `core/routing/route_names.dart` — 补全 settings 子路由常量
- [x] T31 `core/routing/app_router.dart` — 替换所有 settings placeholder，接入真实 Screen

- [x] T32 `integration_test/settings/settings_state_management_test.dart` — 18 个测试（App 状态 2、Notifier 状态机 6、NotificationPrefs 业务规则 3、AccountStatus 计算属性 3、PII 脱敏 4）
- [x] T33 `integration_test/settings/settings_api_integration_test.dart` — 8 个测试（Profile、AccountStatus、Notifications CRUD、Devices、Lock、Deactivation eligibility）
- [x] T34 `integration_test/settings/settings_e2e_app_test.dart` — 9 个 E2E 测试（Tab 渲染、Screen 导航、Logout 弹窗、安全设置 Toggles、通用设置色彩方案、交易设置订单类型、稳定性）

---

## Open Questions

| 编号 | 问题 | 状态 |
|------|------|------|
| OQ-01 | 注销账户后是否允许同一手机号重新注册？（PRD §6.4 标注"待法务确认"）| 待确认，Phase 1 按不允许实现 |
| OQ-02 | W-8BEN 续签入口跳转到 KYC 哪个步骤？ | 待确认，Phase 1 占位"联系客服" |
| OQ-03 | TradeSettings 是否需要同步到后端，还是仅本地偏好？ | 按本地实现（SharedPreferences） |
