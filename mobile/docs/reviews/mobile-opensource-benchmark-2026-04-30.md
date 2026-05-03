# Mobile 开源项目对标 Review

日期：2026-04-30

## 1. 执行摘要

当前 Flutter mobile 项目按原始代码量看并不小。在本次 review 口径下，
`src/lib`、`src/test`、`src/integration_test`、`mock-server`、`docs/prd`、
`docs/specs` 合计 116,531 总行、74,314 代码行。更有参考价值的是去掉生成
代码后的 Flutter app/test 体量：排除 `.freezed.dart`、`.g.dart`、
`.drift.dart` 后，`src/lib + src/test + src/integration_test` 有 46,247
代码行。

所以，与成熟开源 Flutter 项目的差距不主要是“代码太少”。真正的差距是代码
构成：

- 业务 Dart 代码不少，但原生/platform 集成代码非常薄。
- 主业务流程覆盖面较宽，但若干生产边界仍是 Phase 2、stub、placeholder，或
  测试未跟上实现变化。
- 缺少成熟项目常见的 release、CI、生成式 API contract、国际化、打包、平台
  hardening 等工程重量。
- `flutter analyze` 当前并未通过。本次运行结果为 49 个 issues，主要集中在
  funding/search 测试代码漂移，以及 KYC warning/info。

结论：这是一个有业务广度的 Phase 1 产品实现，不是简单 demo。但它还没有长成
成熟生产 mobile codebase 的形态。下一阶段更应该做 release-readiness hardening，
而不是继续堆新页面。

## 2. 统计口径

### 当前项目

本次使用的命令：

```sh
tokei src/lib src/test src/integration_test mock-server docs/prd docs/specs
tokei src/lib src/test src/integration_test --exclude '*.freezed.dart' --exclude '*.g.dart' --exclude '*.drift.dart'
flutter analyze
```

本次 review 覆盖：

- 产品文档：`docs/prd`、`docs/specs`
- Flutter app：`src/lib`
- 测试：`src/test`、`src/integration_test`
- Mock backend：`mock-server`
- Android/iOS 壳工程：`src/android`、`src/ios`

### 对标项目

本地对标项目：

- `/Users/huoxd/Downloads/working/opensource_for_my_career/projects/aves`
- `/Users/huoxd/Downloads/working/opensource_for_my_career/projects/immich`
- `/Users/huoxd/Downloads/working/opensource_for_my_career/projects/spotube`
- `/Users/huoxd/Downloads/working/opensource_for_my_career/projects/flame`

金融/交易类 demo 项目刻意排除。它们通常更像 UI kit 或薄 demo，不能作为真实
生产工程成熟度的有效参照。

## 3. 代码量快照

### 当前项目

| 范围 | 文件数 | 总行数 | 代码行 | 解读 |
|---|---:|---:|---:|---|
| `src/lib + src/test + src/integration_test + mock-server + PRD/specs` | 509 | 116,531 | 74,314 | 完整 review 口径 |
| `src/lib + src/test + src/integration_test` | 430 | 94,735 | 65,835 | Flutter app/test，包含生成代码 |
| `src/lib + src/test + src/integration_test`，排除生成代码 | 311 | 58,314 | 46,247 | 更接近手写 Flutter 工作量 |
| `src/lib/features` | 275 | 62,298 | 41,098 | 主业务实现 |
| `src/lib/core` | 46 | 5,502 | 4,168 | 基础设施、安全、网络、路由 |
| `src/lib/shared` | 16 | 1,510 | 1,104 | 共享 UI/theme/widgets |
| `src/test + src/integration_test` | 91 | 25,294 | 19,363 | 测试体量不低，但当前 analyzer 不干净 |
| `src/android + src/ios` | 20 | 418 | 327 | 原生/platform 层非常薄 |

业务模块分布：

| 模块 | 文件数 | 总行数 | 代码行 | 解读 |
|---|---:|---:|---:|---|
| Market | 61 | 18,219 | 11,528 | 最大、最深的业务模块 |
| KYC | 62 | 12,416 | 7,984 | PRD 覆盖广，但 Phase 2 边界仍多 |
| Auth | 37 | 11,340 | 7,335 | 明显强于简单登录流 |
| Trading | 40 | 8,183 | 5,543 | 有订单和安全概念，但仍需生产闭环 |
| Funding + Settings | 44 | 7,705 | 5,459 | Funding 较活跃，Settings 深度不足 |
| Portfolio | 31 | 4,435 | 3,249 | 功能面相对小 |

### 开源项目对比

对比口径尽量选择与产品相关的目录，而不是无差别统计整个仓库；Flame 这类项目
本身是 package workspace，因此按 workspace 口径统计。

| 项目 | 统计范围 | 文件数 | 总行数 | 代码行 | 额外代码主要在哪里 |
|---|---|---:|---:|---:|---|
| 当前 mobile | App/test/mock/docs | 509 | 116,531 | 74,314 | 业务流、生成模型、测试、mock server、spec |
| Aves | `lib`、`test`、`android`、`fastlane`、`scripts` | 1,084 | 132,829 | 110,436 | 原生媒体/platform 集成、release 工具、成熟 app 工程 |
| Immich | Mobile + server + web + open-api + fastlane | 2,449 | 352,864 | 307,371 | 完整产品系统、OpenAPI、后端、web、native mobile、CI |
| Spotube | App + tests + 全平台壳工程 + scripts | 516 | 130,333 | 106,220 | 跨平台打包、桌面/mobile platform work |
| Flame | Packages + examples + docs + scripts | 2,114 | 207,685 | 148,899 | 引擎/package 生态、examples、docs、CI |

原始 LOC 只能作为起点。Immich 更大，是因为它包含后端、web、mobile 和 OpenAPI；
Flame 更大，是因为它是引擎/包生态。Aves 和 Spotube 更接近 mobile app 对标。

## 4. 成熟项目的额外代码长在哪里

### 4.1 Platform 与原生集成

Aves 在本次统计范围里有 119 个 Kotlin 文件和 2 个 Java 文件。Spotube 有 Android、
iOS、Linux、macOS、Windows 多平台目录。Immich mobile 有 Kotlin、Swift 和
Pigeon/platform API。

当前项目 `src/android + src/ios` 只有 327 代码行。对早期 Flutter app 来说这不
异常，但对于一个交易类 app，这意味着大量生产平台行为还没有真正落地：

- Secure Enclave / Android Keystore 里的生物识别密钥管理
- push token 生命周期和通知点击路由
- WebSocket TLS pinning，因为 Dart `web_socket_channel` 不能复用当前自定义
  pinned `HttpClient`
- release signing、真实 app id、entitlements、应用商店准备
- background、permission、deep link、OS 生命周期异常处理

### 4.2 Release 与 CI 工程

当前 mobile 根目录没有 `.github` workflow。对标项目都有较完整的工程门禁：

- Aves：quality check、release、dependency review、scorecards
- Immich：mobile build、static analysis、OpenAPI freshness、CodeQL、test、
  Docker、docs、release、translation
- Spotube：PR lint、binary publish、多平台 release binary workflow
- Flame：CI/CD、docs、release prepare/tag/publish、spell/title validation

这是当前项目最清晰的差距之一。生产 mobile 仓库需要可重复的验证和发布门禁，
不能只依赖本地命令。

### 4.3 API Contract 与生成客户端

Immich 有 `open-api` 包，并有 workflow 校验 generated API freshness。当前项目
有大量手写 remote model 和 Go mock server，这对本地开发很有价值，但还没有一个
repo 级的 contract source of truth 把 PRD/spec、mock server、mobile DTO 绑在
一起。

对 brokerage app 来说，这不是形式主义。API drift 会直接变成 money-moving
behavior drift：订单提交、入出金、KYC、portfolio value 都需要 schema 级别的
兼容性检查。

### 4.4 Offline、Cache 与数据生命周期

当前项目已经有 Drift，并在 `src/lib/core/storage/database.dart` 里定义了
`QuoteCaches`。这说明旧版对标报告里“SQL cache 缺失”的结论已经过期。但当前
持久化面仍较窄，主要是 quote snapshot。

成熟 app 通常会在这些地方自然增长更多代码：

- cache invalidation 和 freshness policy
- schema migration
- conflict / retry
- 不止一个表的 offline read model
- background sync 与 app lifecycle 集成
- data deletion/export/privacy workflow

对当前项目而言，下一批更自然的对象是 watchlist、recent search、order history
read-through cache、portfolio snapshot、KYC draft persistence，并且要明确保留、
过期、删除和加密策略。

### 4.5 测试与静态质量

当前项目测试体量不低：`src/test + src/integration_test` 有 19,363 代码行。问题
不是“没有测试”，而是测试和实现没有稳定同步，门禁不可靠。

本次 `flutter analyze` 结果：

- 共 49 个 issues。
- Funding 测试仍调用 `DepositFormNotifier.submit()`，但实现已经变成
  `authenticateAndSubmit()`。
- Funding 测试 mock `initiateDeposit` 时缺少当前生产方法要求的 biometric 参数。
- Market search 测试引用了当前 app surface 里已经不存在的
  `sharedPreferencesProvider`。
- KYC 存在 unused import/local、collection literal inference、dead code、Flutter
  deprecation、async context 等 warning/info。

这说明测试已经有量，但当前不能作为可信 merge gate。

## 5. 当前项目优势

### 5.1 业务覆盖面不低

项目已经覆盖 auth、market、trading、funding、portfolio、KYC、settings、routing、
security、storage、mock-server。它不是 UI-only prototype，也不是薄 demo。

### 5.2 Market 模块相对最深

Market 是最大业务模块，有 11,528 代码行。它包含 REST data、WebSocket client /
notifier、delayed vs realtime tier、reconnect state、pending subscribe /
unsubscribe operation、Drift quote cache 和 integration tests。

这比旧版 benchmark 里的“WebSocket reconnect 和 SQL cache 都缺失”更进一步。现在
应评价为：已经部分实现，但仍缺 production hardening。

### 5.3 安全意图明确

代码库已有这些安全基础设施：

- token service 与 authenticated Dio
- local auth service
- bio challenge 与 HMAC-based token
- nonce/session key
- screen protection
- SSL/certificate pinning scaffold
- jailbreak detection scaffold

这比很多开源 mobile app 的安全基础更完整。风险在于若干部分还停在 scaffold 或
不完整平台集成。

### 5.4 PRD/spec 覆盖详细

当前 docs 对产品意图、phase boundary、模块 tracker 的描述很细。这对交接和审查
有价值。但 review 时必须把“文档里写了 Phase 2”视为“尚未生产可用”，不能当作
已完成能力。

## 6. 主要差距

### P0：先恢复 analyzer 与测试门禁

`flutter analyze` 当前失败。它应该先修，因为这是最低成本、最高信号密度的内部
一致性检查。

直接原因：

- `src/test/features/funding/application/deposit_form_notifier_test.dart` 落后于
  新的 biometric deposit flow。
- `src/test/features/market/application/search_notifier_test.dart` 引用了已移除或
  已重命名 provider。
- KYC warning/info 较多，会持续制造噪声。

建议目标：`flutter analyze` 先做到无 error，再把 warning 降到新问题能被清楚
看见的水平。

### P0：生产关键 stub 必须闭环

明确例子：

- `src/lib/core/push/push_notification_service.dart` 仍是 Firebase no-op stub。
- `src/lib/core/push/notification_handler.dart` 还没有真实通知路由。
- `src/lib/core/auth/biometric_key_manager.dart` 只有 stub implementation。
- `src/lib/core/security/ssl_pinning_config.dart` 仍有 placeholder pins，而且是
  certificate-level hash，不是真正 SPKI extraction。
- `src/android/app/build.gradle.kts` 的 release build 仍使用 debug signing，并且
  app id/signing 仍有 TODO。
- `src/README.md` 仍是默认的 “A new Flutter project”。

这些不是代码洁癖问题。对于 brokerage mobile app，它们是 release blocker。

### P0：Money-moving flow 需要 contract discipline

Funding 和 trading 已经引入更强的 biometric/security 概念，但测试跟不上实现变化
本身就是风险信号。成熟项目会用 generated API client、contract test、idempotency
test、CI freshness check 来降低 mock/server/mobile schema divergence。

建议方向：

- 为 auth、KYC、market、trading、funding、portfolio 定义 OpenAPI 或等价 schema。
- 在可行范围内生成 DTO/client。
- 在 CI 里检查 generated output 是否最新。
- mock server 行为基于同一份 schema 做 contract test。

### P1：原生平台层过薄

对普通 Flutter CRUD app，327 行原生代码可以接受。对交易 app，涉及 biometrics、
push、secure keys、certificate pinning、截图保护、deep links、backgrounding、
应用商店发布，这个量级偏薄。

开源对标说明缺的不是更多 Flutter widget，而是 platform-specific implementation
和 release integration。

### P1：Offline persistence 还太窄

Drift 已经存在，但主要服务 quote snapshot。真实交易客户端需要明确本地数据生命
周期策略：

- watchlist
- search history
- KYC drafts 和 uploads
- order history read model
- portfolio snapshot
- funding transfer history
- cache TTL、invalidation、logout deletion

注意目标不是“缓存一切”。目标是明确哪些数据缓存、是否加密、何时过期、何时删除、
异常时如何恢复。

### P1：Settings/Profile 产品深度不足

PRD 里 settings/profile 承担账户与设置能力，但实现体量相比 auth/KYC/market 偏小。
成熟 app 中 settings 往往是 account operations control plane：

- 设备与 session 管理
- MFA / biometric enrollment
- notification preferences
- tax/account documents
- privacy 与 data controls
- diagnostics/support
- legal disclosures 与 app version metadata

当前项目应把 settings 当作生产控制面，而不是最后补的 UI tab。

### P2：文档与仓库 onboarding 滞后

`src/README.md` 仍是默认 Flutter README。这与当前代码规模、业务风险和交接需求
不匹配。

至少应补齐：

- local setup
- build/analyze 命令
- test command matrix
- mock-server 使用方式
- environment config
- code generation
- release caveats
- known Phase 2 blockers

## 7. 建议 Backlog

### P0：稳定当前 surface

1. 先修 `flutter analyze` errors，尤其是 funding 和 market 测试漂移。
2. 在 notifier/model 变化后同步 generated code。
3. 增加 analyze 和关键 test suite 的 CI gates。
4. 任何 release candidate 前，替换 debug signing 和 app-id TODO。
5. 将 push、notification routing、biometric key manager 从 stub 变成真实平台实现；
   如果短期不做，则必须在 production build 中显式禁用或 gate。

### P1：明确 contract 与 persistence

1. 引入 OpenAPI 或等价 contract source of truth。
2. 增加 schema/client/mock freshness check。
3. 只在产品行为需要的地方扩展 Drift，不为了“显得完整”而缓存敏感数据。
4. 增加 migration、retention、logout deletion 测试。
5. 按 PRD 把 settings/profile 扩展成账户操作控制面。

### P2：补齐成熟项目工程化

1. 增加 Android/iOS release workflow。
2. 增加 dependency/security check，参考 Aves/Immich 的门禁类型。
3. 增加 docs check 和 generated-file freshness check。
4. 改写 onboarding docs，移除默认 Flutter README。
5. 原生能力落地后，增加 platform-specific regression tests。

## 8. 对旧 benchmark 结论的校正

`OPENSOURCE_BENCHMARK_SUMMARY.md` 可以作为历史参考，但部分结论已经过期。

不建议再直接复用这些旧说法：

- “Domain Layer + UseCase missing”：当前 features 已经有 `domain`、`data`、
  `application`、`presentation` 目录。现在的问题是深度和一致性，不是完全缺失。
- “SQL cache missing”：Drift 和 quote cache 已存在。现在的差距是覆盖面、生命周期
  策略、migration、敏感数据策略。
- “WebSocket reconnect missing”：market WebSocket notifier 已经有 reconnect state
  和 backoff logic。现在的差距是 production hardening、WebSocket native TLS pinning、
  lifecycle/network 变化下的集成验证。

更新后的结论应该是：架构已经往前走了一步，但生产边界没有以同样速度闭环。

## 9. Bottom Line

当前项目的代码量已经足够认真对待。和 Aves、Immich、Spotube、Flame 相比，主要短板
不是原始体量，而是这些地方缺代码、缺闭环：

- native/platform 生产行为
- release 与 CI 体系
- API contract enforcement
- offline data lifecycle
- analyzer-clean 的测试同步
- account/settings 操作深度

如果目标是真实生产 brokerage app，下一阶段应优先做 release-readiness hardening，
而不是继续扩大功能面。
