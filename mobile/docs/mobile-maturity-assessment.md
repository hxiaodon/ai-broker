# Mobile 客户端成熟度评估

> 首次评估：2026-03-11
> 技术栈：Kotlin Multiplatform + Compose Multiplatform 1.8.0（iOS + Android）
> 评估方法：28 法则 —— 2 成核心骨架 → 8 成生产可用

---

## 当前快照

| 维度 | 当前值 | 成熟 App 参考值 | 完成度 |
|------|--------|----------------|--------|
| Kotlin 文件数 | 108 | 500–1000+ | ~15% |
| 总代码行数 | ~1.9 万 | 15–30 万 | ~10% |
| UI 页面数 | 18 | 60–120 | ~20% |
| 业务模块（有 ViewModel） | 1（行情） | 6–8 | ~15% |
| 单元测试覆盖 | 0% | 60–70%（核心逻辑） | 0% |

**阶段定位：核心骨架（约 1/8 完成度）**
架构分层清晰，UI 骨架完整，CMP 跨平台能力验证通过，但 domain 层几乎空缺，无测试，无真实 API 对接，无安全加固。

---

## 代码现状 — 模块分类

### composeApp（UI 层）— 14,178 行 / 71 文件

| 子目录 | 文件数 | 行数 | 状态 |
|--------|--------|------|------|
| screens/account | 5 | 2,436 | UI 完整，无 ViewModel 绑定 |
| screens/market | 3 | 1,469 | ✅ 有 ViewModel，有实时行情 |
| screens/auth | 3 | 1,190 | UI 完整，无真实认证 |
| screens/kyc | 1 | 1,054 | UI 草稿 |
| screens/trade | 1 | 853 | UI 草稿，无下单逻辑 |
| screens/portfolio | 1 | 523 | UI 草稿，无数据绑定 |
| screens/orders | 2 | 683 | UI 草稿，无状态机 |
| screens/alert | 2 | 479 | UI 草稿 |
| components | 9 | 2,519 | K 线图、分时图、盘口等核心组件 ✅ |
| icons | 22 | 1,313 | 全量 SVG→ImageVector 转换 ✅ |
| theme | 5 | 551 | 设计系统完整 ✅ |

### shared（业务逻辑层）— 4,724 行 / 36 文件

| 子目录 | 文件数 | 行数 | 状态 |
|--------|--------|------|------|
| domain/marketdata | 7 | 368 | ✅ 模型完整 |
| domain/account | 0 | 0 | ❌ 空目录 |
| domain/auth | 0 | 0 | ❌ 空目录 |
| domain/trading | 0 | 0 | ❌ 空目录 |
| domain/portfolio | 0 | 0 | ❌ 空目录 |
| domain/fundtransfer | 0 | 0 | ❌ 空目录 |
| presentation/market | 3 | 652 | ✅ StockDetailViewModel 完整 |
| data/repository | 2 | ~1,200 | FakeMarketRepository（mock） |
| core/crypto | 3 | ~300 | BiometricAuth、加密工具 |
| core/network | 2 | ~200 | Ktor 客户端骨架 |

---

## 缺失的 8 成 — 系统性分类

### 一、业务功能缺口（最大块，约 40%）

**Domain 层空缺（6 个核心域）：**

- [ ] `domain/auth/` — Token 模型、Session 状态机、登录态管理
- [ ] `domain/account/` — 账户模型、开户流程、KYC 审批状态
- [ ] `domain/trading/` — 订单类型（市价/限价/止损）、委托状态机、撤单逻辑
- [ ] `domain/portfolio/` — 持仓聚合、实时盈亏计算、收益曲线
- [ ] `domain/fundtransfer/` — 出入金流水、银行账户、限额规则
- [ ] `domain/alert/` — 价格预警触发、通知路由

**ViewModel 层空缺（除 market 外全缺）：**

| 业务流 | ViewModel | 缺失核心逻辑 |
|--------|-----------|-------------|
| 登录/注册 | ❌ | Token 获取、刷新、多设备踢出 |
| KYC 上传 | ❌ | 文件上传、审批状态轮询 |
| 下单 | ❌ | 下单校验、委托状态机、撤单 |
| 持仓/盈亏 | ❌ | 实时盈亏计算、持仓聚合 |
| 出入金 | ❌ | 完整出入金流程（申请→审批→到账） |
| 订单历史 | ❌ | 分页、筛选、状态过滤 |
| 消息通知 | ❌ | Push 接收、通知列表 |

---

### 二、工程基础设施（生产必须有，约 25%）

| 基础设施 | 当前状态 | 生产要求 |
|---------|---------|---------|
| 真实 API 对接 | FakeRepository（mock） | Ktor client + REST/WebSocket + 真实后端 |
| 认证 Token 管理 | 无 | JWT 自动刷新、失效拦截、安全存储 |
| 本地缓存 | 依赖已引入，0 使用 | SQLDelight 行情快照、订单缓存、离线读 |
| 全局错误处理 | 局部 | 错误码映射、重试策略、用户友好提示 |
| 网络状态感知 | 无 | 断网提示、请求队列、WebSocket 重连 |
| DI 模块化 | Koin 初始化 | 各业务域 Module 独立注入 |
| Proto 序列化 | 依赖已引入，0 使用 | WebSocket 消息编解码 |
| 多环境配置 | 无 | dev/staging/prod BuildConfig 切换 |
| Crash 收集 | 无 | Firebase Crashlytics 或等价方案 |
| WebSocket 心跳 | 无 | 断线检测、心跳保活、指数退避重连 |

---

### 三、测试体系（当前 0%，约 20%）

金融 App 测试三层：

```
单元测试 ─ ViewModel、Repository、业务规则（目标：核心逻辑 ≥ 70% 覆盖）
集成测试 ─ API 契约、SQLDelight 读写（目标：关键路径全覆盖）
UI 测试  ─ Compose 截图回归、端到端核心流程
```

金融业务专项测试（合规要求）：
- [ ] BigDecimal 价格精度边界值测试
- [ ] 下单幂等性测试（重复提交）
- [ ] 出入金金额校验（同名原则、AML 阈值）
- [ ] 委托状态机完整性测试
- [ ] WebSocket 断线重连行为测试

---

### 四、安全加固（合规强制，约 10%）

| 安全项 | 当前 | 缺失 | 合规要求 |
|--------|------|------|---------|
| SSL Certificate Pinning | ❌ | 防中间人攻击 | 强制 |
| 越狱/Root 检测 | ❌ | 限制交易功能 | 强制 |
| 截屏防护 | ❌ | 交易/KYC/账户页禁截屏 | 强制 |
| 生物识别下单 | 架构有，UI 无 | 下单确认 Face ID/指纹 | 强制 |
| 敏感数据超时清除 | ❌ | 后台超时自动清除 Keychain | 强制 |
| Anti-debugging | ❌ | 生产包防调试注入 | 建议 |
| 数据传输签名 | ❌ | 交易 API HMAC-SHA256 签名 | 强制 |

---

### 五、性能与体验打磨（约 5%）

| 项目 | 现状 | 目标 |
|------|------|------|
| 行情 Canvas 渲染帧率 | 未测量 | 稳定 60fps，无掉帧 |
| 冷启动时间 | 未测量 | < 1.5 秒（首屏可交互） |
| 大列表性能 | 基础 LazyColumn | 预取策略、差分更新 |
| 图片懒加载 | 无 | 新闻图片、用户头像异步加载 |
| ViewModel/Flow 订阅清理 | 局部 | 全面审查内存泄漏 |
| 包体积 | 未测量 | Android < 30MB，iOS < 50MB |

---

## 演进路线图

### Phase 1 — 接真实后端 + 核心业务 ViewModel（2–3 个月）

目标：从 Demo 到可内测版本（~4 万行）

- [ ] 真实 API 替换 FakeRepository（Ktor + WebSocket）
- [ ] 认证完整流程（登录/注册/Token 刷新/登出）
- [ ] 交易下单完整流程（Domain + ViewModel + UI 联通）
- [ ] 持仓/盈亏实时计算（ViewModel + WebSocket 推送）
- [ ] 出入金基础流程（申请 → 审批 → 到账状态）
- [ ] 单元测试基础覆盖（核心业务逻辑 ≥ 50%）
- [ ] SQLDelight 本地缓存（行情、订单离线读）

### Phase 2 — 安全合规 + 工程完善（3–4 个月）

目标：合规审查通过，可提交 App Store（~8 万行）

- [ ] SSL Certificate Pinning
- [ ] 生物识别下单确认（Face ID / 指纹）
- [ ] 越狱/Root 检测 + 截屏防护
- [ ] KYC 完整流程（文件上传、审批状态轮询）
- [ ] Push 通知（行情预警、订单成交、出入金到账）
- [ ] 全局错误处理 + Crashlytics
- [ ] 多环境配置（dev/staging/prod）
- [ ] UI 截图回归测试

### Phase 3 — 打磨 + 生产就绪（2–3 个月）

目标：生产上线标准（~15 万行）

- [ ] 性能调优（60fps 稳定、冷启动 < 1.5s）
- [ ] 端到端 UI 自动化测试
- [ ] 多市场扩展（ETF、衍生品、期权）
- [ ] 国际化（英/繁/简三语）
- [ ] 灰度发布机制
- [ ] 无障碍支持（VoiceOver/TalkBack）

---

## 更新日志

| 日期 | 版本 | 变更摘要 |
|------|------|---------|
| 2026-03-11 | v0.1 | 首次评估。骨架阶段，108 文件，1.9 万行，行情模块可用，其余模块 UI 草稿 |

---

> **下次评估触发条件**：Phase 1 完成 / 代码量翻倍 / 重大架构调整
> **文档维护**：每个 Phase 完成后更新"当前快照"表格和"更新日志"
