# PRD 技术评审总览报告

**项目**: 环球通证券（Huanqiutong Securities）— Phase 1 MVP
**评审日期**: 2026-03-13
**评审角色**: 6 个工程职能（iOS、Android、Backend、Frontend、Fund Transfer、Trading Engine）
**覆盖 PRD**: PRD-00 到 PRD-08（9 个模块）

> 🚀 **移动端技术路线最终决策（2026-03-13）**：经综合技术评估，移动端正式采用 **Flutter 3.41.4**。详见技术方案文档：[mobile-flutter-tech-spec.md](../mobile-flutter-tech-spec.md)

---

## 一、总体结论

PRD 的**用户侧移动端流程设计完整**，KYC 7 步流程、订单状态机、费用计算均有合理规格。但以下两类缺陷系统性地出现：

1. **Admin Panel 严重欠设计**：前端、出入金、交易引擎、后端评审均独立发现 Admin API 大规模缺失，影响 KYC 审核、出金审批、订单监控等核心运营功能。
2. **Native App 安全方案不兼容**：PRD 的 Refresh Token（HttpOnly Cookie）和 SMS Listener 方案来自 Web 安全最佳实践，在 iOS/Android Native App 中不适用，需在开发前统一更改。

---

## 二、问题汇总统计

> **技术路线更新**：iOS/Android 原生评审及 KMP/CMP 评审均已废弃，移动端已于 2026-03-13 正式决策采用 **Flutter**。Flutter 技术方案及 12 个技术问题解决方案详见 [mobile-flutter-tech-spec.md](../mobile-flutter-tech-spec.md)。

| 角色 | P0 | P1 | P2 | 合计 | 报告文件 |
|------|----|----|----|----|------|
| ~~iOS Engineer~~ | ~~2~~ | ~~6~~ | ~~2~~ | ~~10~~ | 已废弃，见 Flutter 方案 |
| ~~Android Engineer~~ | ~~1~~ | ~~6~~ | ~~3~~ | ~~10~~ | 已废弃，见 Flutter 方案 |
| ~~移动端 KMP/CMP~~ | ~~3~~ | ~~9~~ | ~~2~~ | ~~14~~ | 已废弃，见 Flutter 方案 |
| **移动端 Flutter** | **2** | **3** | **0** | **5** | [mobile-flutter-tech-spec.md](../mobile-flutter-tech-spec.md)（残留需 Method Channel 的问题） |
| Backend Engineer | 4 | 11 | 5 | **20** | backend-engineer-review.md |
| Frontend Engineer（Admin Panel） | 5 | 9 | 5 | **19** | frontend-engineer-review.md |
| Frontend Engineer（WebView/H5 补充） | 2 | 6 | 2 | **10** | frontend-webview-supplement.md |
| Fund Transfer Engineer | 3 | 6 | 3 | **12** | fund-transfer-engineer-review.md |
| Trading Engine Engineer | 3 | 6 | 5 | **14** | trading-engine-engineer-review.md |
| **有效合计** | **19** | **41** | **15** | **75** | — |

> **P0 = 19 项**（阻塞上线/开发/存在安全漏洞）
> **P1 = 41 项**（功能正确性或运营风险，需 Sprint 1 前澄清）
> **P2 = 15 项**（设计歧义或优化建议，不阻塞开发）
>
> *注：Flutter 方案解决了原 KMP/CMP 中的多数 P1 移动端问题（SMS OTP、APNs 桥接、KYC 裁剪、PDF 查看、截图防护、iOS 原生一致性）；生物识别硬件密钥签名（Secure Enclave + CryptoObject）仍需 Method Channel 原生实现（P1），后端 Refresh Token 接口变更仍需与后端对齐（P0）。*

---

## 三、P0 问题清单（必须在开发启动前解决）

### 3.1 认证安全类

| ID | 来源 | 问题 | 建议 |
|----|------|------|------|
| P0-Auth-01 | KMP + Backend | **Refresh Token 使用 HttpOnly Cookie 在 Native App 中无安全语义**，Ktor `HttpCookies` 插件无 Keychain/Keystore 集成 | iOS: Keychain（`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`）；Android: EncryptedSharedPreferences；推荐库 KVault |
| P0-Auth-02 | KMP | **生物识别密钥绑定：两平台 expect/actual 实现差异极大**，无成熟跨平台库支持 Secure Enclave 签名 | 定义粗粒度 `BiometricKeyManager` expect/actual，独立封装为 `:core:biometric` 模块 |
| P0-Auth-03 | Backend | **Refresh Token 轮换竞态条件**：多端同时刷新 Token 时均通过验证 | Redis Lua 脚本原子消费 Token；检测到二次使用视为重放攻击 |
| P0-Auth-04 | Backend | **生物识别 Challenge 无服务端绑定接口**，缺少 `POST /v1/auth/biometric/challenge` | 补充下发接口，Redis 存储 `challenge → device_id`，单次有效 |
| P0-Auth-05 | Backend | **注册并发竞态（TOCTOU）**：同手机号并发注册触发 UNIQUE 违反返回 500 | `INSERT ... ON CONFLICT DO NOTHING RETURNING id` |

### 3.2 Admin API 缺失类

| ID | 来源 | 问题 | 影响 |
|----|------|------|------|
| P0-Admin-01 | Frontend + Backend | **KYC 审核工作台 Admin API 全部缺失**：无队列列表、详情、通过/拒绝/补件接口 | Admin Panel 无法开发，KYC 审核流程不可上线 |
| P0-Admin-02 | Frontend + Fund Transfer | **出金审批队列 Admin API 全部缺失**：无 L1/L2/L3 审批、SAR 发起接口 | 出金审批工作台不可开发 |
| P0-Admin-03 | Frontend | **热门列表管理 Admin API 缺失**：PRD-03 说"Admin Panel 可管理热门列表"但无对应接口 | 热门列表运营无法实现 |
| P0-Admin-04 | Frontend | **SAR 无 API 且无数据模型**：sar_filings 表未定义，FinCEN 30 天申报时限下无实现路径 | 监管合规风险 |
| P0-Admin-05 | Frontend | **订单监控 Admin 视图 API 缺失**：用户侧 `/v1/orders` 只能查自己的订单，不支持跨用户监控 | 运营无法监控订单 |

### 3.3 资金安全类

| ID | 来源 | 问题 | 影响 |
|----|------|------|------|
| P0-Fund-01 | Fund Transfer | **可提现余额公式符号错误**：PRD 写 `+ 未结算卖出资金` 但注释和 API 示例均为减法，三处描述不一致 | 提现金额计算错误，用户实际可提现金额被高估 |
| P0-Fund-02 | Fund Transfer | **ACH Return（银行退汇）处理逻辑完全缺失**：R07/R10（未授权退汇）是欺诈信号需触发 SAR，Late Return（入账后退汇）无补偿流程 | 资金损失风险，合规盲区 |
| P0-Fund-03 | Fund Transfer | **`ledger_accounts` 表缺失**：PRD-07 引用此表做乐观锁，但 PRD-05 只有 `ledger_entries`，并发出金请求无法防止超扣 | 并发超扣导致账户负余额 |

### 3.4 交易引擎类

| ID | 来源 | 问题 | 影响 |
|----|------|------|------|
| P0-Trade-01 | Trading Engine | **市价单无价格保护机制**：低流动性股票市价单可能以远超显示价格成交，偏差可能超 50% | 用户资金损失，FINRA 最优执行审计风险 |
| P0-Trade-02 | Trading Engine | **订单状态机 `RISK_CHECKING` 失败路径未定义，且状态机与代码不一致**：`StatusRejected` vs `REJECTED`，`PENDING_FILL` vs `StatusOpen` 等 | 前后端 API 契约断裂，用户提示消息不准确 |
| P0-Trade-03 | Trading Engine | **SEC Fee 存储精度不足**：`NUMERIC(18,4)` 导致小额交易费用四舍五入为 $0.0000；费率硬编码但 SEC 每年调整两次 | 监管合规违规，费用记录不准确 |

### 3.5 WebView/H5 类（新增）

| ID | 来源 | 问题 | 影响 |
|----|------|------|------|
| P0-H5-01 | Frontend WebView | **JSBridge 接口规范完全缺失**：风险披露"滚动到底"回调、协议关闭回调、W-8BEN 分享、帮助中心客服跳转均依赖 H5↔Native 通信，但 PRD 无任何 JSBridge 定义 | iOS `WKScriptMessageHandler` 与 Android `addJavascriptInterface` 双端无依据，联调大量返工 |
| P0-H5-02 | Frontend WebView | **H5 页面鉴权方案未定义**：JWT 存于 Keychain 无法被 WebView 直接访问，Refresh Token 机制 H5 无法调用，URL 传 Token 有日志泄露风险 | H5 页面无法获取登录态，W-8BEN/风险披露等需鉴权的页面不可实现 |

### 3.6 KYC 数据完整性类

| ID | 来源 | 问题 | 影响 |
|----|------|------|------|
| P0-KYC-01 | Backend | **KYC 进度保存接口无幂等性**：断网重试导致 OCR 重复调用，resume_token 未绑定场景可跳过步骤 | 数据覆写、步骤绕过安全风险 |

---

## 四、高影响 P1 问题（按模块）

### 认证模块（PRD-01）

| 问题 | 来源 | 核心影响 |
|------|------|---------|
| Android: `READ_SMS` 权限被 Google Play 拒绝，应改用 SMS Retriever API | Android | App 无法上架 Google Play |
| Android: `BiometricPrompt` 降级处理和 `KeyPermanentlyInvalidatedException` 未覆盖 | Android | 部分设备崩溃 |
| iOS: "iOS SMS Listener" 概念错误，iOS 只有 `UITextContentType.oneTimeCode` | iOS | 开发实现错误功能 |
| Backend: `user_devices` 全局唯一约束错误，应为 `(user_id, device_id)` 复合唯一 | Backend | 换机登录丢失历史，转让设备无法登录 |
| Backend: OTP `purpose` 未与 Redis 绑定，可跨场景复用 OTP | Backend | 安全漏洞：攻击者可用登录 OTP 完成手机号更换 |
| Backend: 手机号更改后 Token 失效存在最长 15 分钟时间窗口 | Backend | 安全：旧设备持续访问 |

### KYC 模块（PRD-02）

| 问题 | 来源 | 核心影响 |
|------|------|---------|
| Admin KYC 审核接口全部缺失（详见 P0-Admin-01） | Frontend + Backend | - |
| KYC 提交缺少服务端完整性校验（步骤位图） | Backend | 可绕过协议签署步骤 |
| W-8BEN 到期状态变更无触发机制，无 `is_current` 约束 | Backend | 股息税率无法自动切换 30% |
| KYC 状态 `IN_PROGRESS` 超时后处理未定义（KYC 漏斗统计失真） | Backend | 运营数据失真 |
| Android: HEIC 图片格式在 API 26-27 完全不支持 | Android | API 26-27 设备崩溃 |
| iOS: HEIC 原图可达 6-10MB，超出 5MB 限制，需强制转 JPEG | iOS | 上传失败 |
| Presigned URL API 缺失（证件图片安全访问） | Frontend | PII 泄露风险 |
| OCR 高亮对比不可行（无 bounding box 坐标） | Frontend | 功能不可实现，需改方案 |

### 行情模块（PRD-03）

| 问题 | 来源 | 核心影响 |
|------|------|---------|
| WebSocket 身份验证协议完全未定义（如何传 JWT、Token 过期降级） | Backend | 访客/用户隔离漏洞，无限订阅 DDoS |
| iOS: Swift Charts 不支持 Candlestick，500 根 K 线性能问题 | iOS | 需要 Canvas 自绘 PoC，影响排期 |
| Android: MPAndroidChart 2021 年停更，Compose 集成有性能风险 | Android | 需评估替代方案 |
| K 线历史接口无分页/数量限制，全历史月线可 OOM | Backend | DoS 攻击向量 |
| Watchlist 无数据模型定义，并发添加无幂等 | Backend | 数据重复，上限矛盾 |
| `symbols` 参数无长度限制，N+1 放大攻击 | Backend | API 成本和性能风险 |
| 访客延迟行情切换到实时流的策略未定义（价格闪烁） | iOS + Android | 用户体验：价格跳变 |
| Android: WebSocket 后台保活在 API 26+ 受限，应改为 FCM | Android | 后台推送策略需重设计 |

### 交易模块（PRD-04）

| 问题 | 来源 | 核心影响 |
|------|------|---------|
| 盘前/盘后 DAY 订单生命周期未定义 | Trading Engine | 订单过期处理不确定 |
| GTC 90 天过期机制无调度器、节假日处理 | Trading Engine | GTC 订单无法正确过期 |
| 持仓均价并发更新竞态（乐观锁策略不一致）| Trading Engine | 持仓/余额错误 |
| 冻结资金在取消/拒绝/到期时解冻流程未定义 | Trading Engine | 用户可用资金永久减少 |
| FIX ExecutionReport 到内部状态映射缺失 | Trading Engine | DAY 订单收盘过期无处理 |
| 费用预估 vs 实际差异无用户沟通设计 | Trading Engine | 产品体验缺陷 |
| iOS: Slide-to-Confirm 缺失手势冲突/防重复提交/VoiceOver | iOS | 无障碍合规缺陷 |
| Android: Slide-to-Confirm 需同时检查位置+速度 | Android | 快速甩动可绕过确认 |

### 出入金模块（PRD-05）

| 问题 | 来源 | 核心影响 |
|------|------|---------|
| Admin 出金审批 API 全部缺失（详见 P0-Admin-02） | Frontend + Fund Transfer | - |
| KYC Tier 1 入金权限与银行卡绑定前置条件矛盾 | Fund Transfer | 合规：IN_PROGRESS 状态可绑卡但姓名未核实 |
| 冷却期（3 天）vs 人工审核触发（7 天）规则重叠冲突 | Fund Transfer | 用户体验混乱，规则无法实现 |
| 银行回调无幂等保护（bank_reference 无 UNIQUE 约束）| Fund Transfer | 重复到账通知导致双重入账 |
| 微存款暴力破解（9801 种组合，无限重绑重置次数）| Fund Transfer | 安全漏洞 |
| Structuring Detection 实现规格缺失（窗口类型/拦截时序）| Fund Transfer | 合规：结构性交易检测不确定 |

### 设置/Profile 模块（PRD-08）

| 问题 | 来源 | 核心影响 |
|------|------|---------|
| 设置更新接口 PUT vs PATCH 语义矛盾，无并发控制 | Backend | 多端静默覆写设置 |
| W-8BEN 到期 Admin 提醒无实现路径（无对应 Admin 模块）| Frontend | 合规运营功能缺失 |
| iOS: colorScheme 切换需从根视图注入，iOS 16/17 API 差异 | iOS | 主题切换局部失效 |

---

## 五、跨模块交叉问题

以下问题被**多个角色独立发现**，说明是系统性设计缺陷：

| 问题 | 发现角色 | 严重程度 |
|------|---------|---------|
| Refresh Token 存储方案（HttpOnly Cookie）不适用 Native App | iOS + Android | P0 |
| Admin API 大规模缺失（KYC审核/出金审批/热门列表/订单监控/SAR）| Frontend + Backend + Fund Transfer + Trading Engine | P0 |
| `ledger_accounts` vs `ledger_entries` 架构矛盾 | Fund Transfer + Trading Engine（冻结解冻）| P0 |
| 访客延迟行情 → 实时行情切换策略未定义 | iOS + Android + Backend | P1 |
| W-8BEN 到期触发机制缺失 | Backend + Frontend | P1 |
| 各 WebSocket 认证和后台策略 | iOS + Android + Backend | P1 |

---

## 六、分角色评审报告索引

| 报告文件 | 角色 | 状态 | P0 | P1 | P2 |
|---------|------|------|----|----|-----|
| [mobile-flutter-tech-spec.md](../mobile-flutter-tech-spec.md) | **移动端 Flutter 工程师** | ✅ 当前有效（技术方案文档） | — | — | — |
| [mobile-tech-comparison.md](./mobile-tech-comparison.md) | 移动端（KMP vs Flutter 对比） | 📋 参考文档（技术决策依据） | — | — | — |
| [backend-engineer-review.md](./backend-engineer-review.md) | Backend Engineer | ✅ 当前有效 | 4 | 11 | 5 |
| [frontend-engineer-review.md](./frontend-engineer-review.md) | Frontend Engineer（Admin Panel） | ✅ 当前有效 | 5 | 9 | 5 |
| [frontend-webview-supplement.md](./frontend-webview-supplement.md) | Frontend Engineer（WebView/H5） | ✅ 当前有效 | 2 | 6 | 2 |
| [fund-transfer-engineer-review.md](./fund-transfer-engineer-review.md) | Fund Transfer Engineer | ✅ 当前有效 | 3 | 6 | 3 |
| [trading-engine-engineer-review.md](./trading-engine-engineer-review.md) | Trading Engine Engineer | ✅ 当前有效 | 3 | 6 | 5 |
| [mobile-kmp-review.md](./mobile-kmp-review.md) | 移动端 KMP/CMP 工程师 | ⚠️ 已废弃（Flutter 决策替代） | — | — | — |
| [ios-engineer-review.md](./ios-engineer-review.md) | iOS Engineer（SwiftUI） | ⚠️ 已废弃（技术路线变更） | — | — | — |
| [android-engineer-review.md](./android-engineer-review.md) | Android Engineer（Jetpack Compose） | ⚠️ 已废弃（技术路线变更） | — | — | — |

---

## 七、建议行动计划

### Sprint 0（开发启动前 — 必须完成）

**产品/后端对齐（2-3 天）**

1. **统一 Refresh Token 方案**：与产品、iOS、Android、后端对齐，从 HttpOnly Cookie 改为 Native Keychain/EncryptedSharedPreferences + Bearer Token 方案。修改 PRD-01 认证规格。
2. **补充完整 Admin API 规格**：输出 PRD-Admin-01 文档，覆盖：
   - KYC 审核工作台（队列、详情、审批操作）
   - 出金审批工作台（三级审批 API）
   - 热门列表管理
   - SAR 发起及数据模型
   - 订单监控（跨用户视图）
3. **明确 RBAC 权限矩阵**：确认各角色对应的操作权限，解决 Compliance Officer 跨模块职责重叠问题。

**交易引擎对齐（1-2 天）**

4. **市价单价格保护**：定义保护上限比例（建议常规 5%，盘前/盘后 3%）和超出保护价格的处理逻辑。
5. **对齐订单状态机**：统一 PRD 状态名与代码状态名，明确 `RISK_CHECKING → REJECTED` 失败路径。

**出入金对齐（1 天）**

6. **修正提现公式**：将 `+ 未结算卖出资金` 改为 `- 未结算卖出资金`，明确各字段定义。
7. **补充 `ledger_accounts` 表设计**：选择方案 A（快照表）或方案 B（SELECT FOR UPDATE），在 PRD-05 中明确。

### Sprint 1（开发进行中 — P1 问题澄清）

按模块分批处理 44 个 P1 问题：

| 优先级 | 模块 | 关键问题（Top 5） |
|--------|------|----------------|
| 高 | KYC | Admin 接口实现、KYC 完整性校验、W-8BEN 触发机制 |
| 高 | 行情 | WebSocket 认证协议、K 线图技术方案（PoC 验证）|
| 高 | 出入金 | 银行回调幂等保护、微存款暴力破解防护 |
| 中 | 交易 | 冻结/解冻资金生命周期、FIX ExecutionReport 映射 |
| 中 | 认证 | SMS Retriever API（Android）、OTP purpose 绑定 |

### 上线前（P2 问题）

- SEC Fee 精度升级（NUMERIC(18,8)）
- Wash Sale Rule 检测实现
- 审计日志索引补充
- 各 P2 设计细节文档化

---

## 八、未评审范围

以下模块未在本次技术评审中覆盖（Phase 1 范围内但 PRD 未指定需评审）：

- PRD-06 持仓与 P&L（部分问题在交易引擎评审中覆盖）
- PRD-07 跨模块触发（部分问题在各角色报告中提及）
- 推送通知服务、报告服务、API Gateway 设计

---

*所有问题详情见对应角色评审报告。如有疑问，联系对应角色工程师或产品负责人。*
