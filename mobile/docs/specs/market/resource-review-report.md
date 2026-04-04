# Market 模块资源审查报告

**日期**: 2026-04-04  
**审查人**: mobile-engineer  
**目的**: 验证 PRD、原型、API 合约的完整性与一致性

---

## 1. 高保真原型审查

### 1.1 已覆盖的 UI 状态

| 原型文件 | 覆盖状态 | 说明 |
|---------|---------|------|
| `index.html` | ✅ 完整 | normal（正常）/ loading（加载中）两个状态 |
| `stock-detail.html` | ✅ 完整 | normal / loading 两个状态 |
| `search.html` | ✅ 完整 | empty（空态）/ results（结果）/ empty-result（无结果）三个状态 |

### 1.2 原型与 PRD 对齐度

| PRD 功能 | 原型覆盖 | Gap |
|---------|---------|-----|
| 自选股列表 | ✅ index.html | 无 |
| 热门/涨跌榜 | ✅ index.html（Tab 切换） | 无 |
| 股票详情 | ✅ stock-detail.html | 无 |
| K线图 | ⚠️ 占位符 | 原型仅占位，实际需 Syncfusion Charts 实现 |
| 搜索 | ✅ search.html | 无 |
| 大盘指数 | ✅ index.html（ETF 代理） | 无 |
| 访客延迟提示 | ❌ 未在原型中体现 | 需补充实现（顶部横幅） |
| Stale Quote 警告 | ❌ 未在原型中体现 | 需补充实现（黄色横幅） |
| 盘前/盘后标识 | ⚠️ 部分体现 | stock-detail.html 显示"盘中"，需补充盘前/盘后/休市/暂停状态 |

**结论**: 原型覆盖核心流程，但访客模式和 Stale Quote 两个合规特性需补充实现。

---

## 2. API 合约审查

### 2.1 REST 接口完整性

| PRD 需求 | 合约端点 | 状态 |
|---------|---------|------|
| 批量行情快照 | GET /v1/market/quotes | ✅ 已定义 |
| K线数据 | GET /v1/market/kline | ✅ 已定义 |
| 股票搜索 | GET /v1/market/search | ✅ 已定义 |
| 涨跌幅榜 | GET /v1/market/movers | ✅ 已定义 |
| 股票详情 | GET /v1/market/stocks/{symbol} | ✅ 已定义 |
| 相关新闻 | GET /v1/market/news/{symbol} | ✅ 已定义 |
| 财报数据 | GET /v1/market/financials/{symbol} | ✅ 已定义 |
| 自选股 CRUD | GET/POST/DELETE /v1/watchlist | ✅ 已定义 |

**结论**: REST 接口完整覆盖 PRD 需求。

### 2.2 WebSocket 协议完整性

| PRD 需求 | 协议支持 | 状态 |
|---------|---------|------|
| 实时报价推送 | quote.realtime 频道 | ✅ 已定义 |
| 访客延迟推送 | T-15min 快照，每5s | ✅ 已定义（DelayedQuoteRingBuffer） |
| 认证流程 | 消息级 JWT（5s 超时） | ✅ 已定义 |
| 订阅管理 | subscribe/unsubscribe（最多50 symbols） | ✅ 已定义 |
| 心跳机制 | ping/pong（30s） | ✅ 已定义 |
| Token 续期 | reauth（无需断开连接） | ✅ 已定义 |
| 访客升级 | reauth 后自动切换实时流 | ✅ 已定义 |
| Protobuf 二进制帧 | WsQuoteFrame（SNAPSHOT/TICK/DELAYED） | ✅ 已定义 |

**结论**: WebSocket 协议完整，支持双轨推送和访客升级。

### 2.3 关键字段对齐

| 字段 | PRD 要求 | API 合约 | 对齐度 |
|------|---------|---------|--------|
| 价格精度 | 美股 4 位小数 | string 类型，4 位小数 | ✅ 对齐 |
| 涨跌幅 | 相对前收盘价 | prev_regular_close（16:00 ET） | ✅ 对齐 |
| 市场状态 | 5 种状态 | REGULAR/PRE_MARKET/AFTER_HOURS/CLOSED/HALTED | ✅ 对齐 |
| is_stale | 陈旧数据标识 | 1s 触发，前端 5s 显示警告 | ✅ 对齐 |
| delayed | 延迟行情标识 | 访客 true，注册用户 false | ✅ 对齐 |
| 换手率 | 当日成交量 ÷ 流通股数 | ⚠️ 流通股数数据源待确认 | ⚠️ Open Question #2 |

**结论**: 字段对齐度高，换手率计算依赖的流通股数数据源需 market-data-engineer 确认。

---

## 3. 技术规格审查

### 3.1 Flutter 技术栈对齐

| PRD 需求 | 技术选型 | 状态 |
|---------|---------|------|
| K线图 | Syncfusion Charts v33.1.46 | ✅ 已在 pubspec.yaml |
| WebSocket | web_socket_channel v3.0.3 | ✅ 已在 pubspec.yaml |
| Protobuf | protobuf v3.1.0 | ✅ 已在 pubspec.yaml |
| 金融计算 | decimal v3.2.1 | ✅ 已在 pubspec.yaml |
| 状态管理 | Riverpod 3.3.1 | ✅ 已在 pubspec.yaml |
| 本地缓存 | Hive CE v2.9.0 | ✅ 已在 pubspec.yaml |

**结论**: 技术栈完整，无需额外依赖。

### 3.2 架构模式对齐

| 层级 | PRD 需求 | 技术规格 | 对齐度 |
|------|---------|---------|--------|
| Presentation | 行情列表、股票详情、搜索 | Screens + Widgets + Providers | ✅ 对齐 |
| Application | 实时报价流、自选股管理 | Riverpod Notifiers | ✅ 对齐 |
| Data | REST API + WebSocket | Repository + DataSource | ✅ 对齐 |
| Infrastructure | 网络、缓存、安全 | Dio + Hive + SecureStorage | ✅ 对齐 |

**结论**: Clean Architecture 分层清晰，符合 tech-spec 规范。

---

## 4. 合规要求审查

### 4.1 数据授权

| 要求 | PRD 说明 | 实现计划 | 状态 |
|------|---------|---------|------|
| Polygon Poly.feed+ 授权 | Phase 1 必须升级 | ⚠️ 待 PM 确认 | ⚠️ Open Question #1 |
| 延迟行情标识 | 访客所有价格旁显示"延迟15分钟" | DelayedQuoteBanner + 价格旁徽标 | ✅ 已规划 |
| 数据来源披露 | 股票详情页底部显示"行情数据由 Polygon.io 提供" | Footer Widget | ✅ 已规划 |
| 大盘指数替代 | 使用 ETF（SPY/QQQ/DIA），标注"追踪 XXX" | 原型已体现 | ✅ 已规划 |

**结论**: 合规要求已覆盖，Polygon 授权需 PM 确认。

### 4.2 安全要求

| 要求 | 实现方案 | 状态 |
|------|---------|------|
| 证书固定 | Dio + SPKI 公钥指纹验证 | ✅ 已规划 |
| WebSocket 认证 | 消息级 JWT（不使用 URL query param） | ✅ 已规划 |
| PII 日志掩码 | AppLogger 自动掩码 | ✅ 已规划 |
| 访客数据隔离 | 本地 Hive 存储，不同步服务端 | ✅ 已规划 |

**结论**: 安全要求已覆盖。

---

## 5. Open Questions 汇总

| # | 问题 | 影响任务 | 优先级 | 负责人 |
|---|------|---------|--------|--------|
| 1 | Polygon.io Poly.feed+ 授权是否已完成？ | T16（WebSocket） | 🔴 P0 | PM + Legal |
| 2 | 换手率计算所需的"流通股数"数据源是否已接入？ | T04（股票详情） | 🟡 P1 | market-data-engineer |
| 3 | 中文公司名与拼音搜索的 Top 1000 美股数据是否已准备？ | T06/T13（搜索） | 🟡 P1 | market-data-engineer |
| 4 | 访客升级为注册用户后，WebSocket reauth 是否需要重新订阅 symbols？ | T16（WebSocket） | 🟢 P2 | market-data-engineer |
| 5 | K线图"分时"显示范围是否仅常规交易时段（09:30-16:00 ET）？ | T05（K线图） | 🟢 P2 | PM |

**建议**: 在开始 T16（WebSocket）和 T04（股票详情）前，先解决 Q1 和 Q2。

---

## 6. Gap 分析

### 6.1 原型 Gap

| Gap | 影响 | 建议 |
|-----|------|------|
| 访客延迟提示横幅未在原型中体现 | 合规风险 | 实现时补充，参考 auth 模块的 GuestPlaceholderScreen |
| Stale Quote 警告横幅未在原型中体现 | 用户体验 | 实现时补充，黄色背景 + 警告图标 |
| 盘前/盘后/休市/暂停状态未完整展示 | 功能完整性 | 实现时补充，参考 PRD §5.2 交易时段显示规则 |

### 6.2 API 合约 Gap

| Gap | 影响 | 建议 |
|-----|------|------|
| 无明显 Gap | — | — |

### 6.3 技术规格 Gap

| Gap | 影响 | 建议 |
|-----|------|------|
| Protobuf 消息定义文件路径未明确 | 开发阻塞 | 确认 `docs/specs/api/grpc/market_data.proto` 是否存在 |
| WebSocket Subprotocol 握手细节未在 Flutter 侧说明 | 实现细节 | 参考 websocket-spec v2.1 §消息帧类型约定 |

---

## 7. 实现建议

### 7.1 任务优先级

**Phase 1.1（核心流程，2 周）**:
- T14-T18（Data 层）：Repository + DataSource + WebSocket Client
- T10（QuoteStreamProvider）：实时报价流
- T01-T03（Presentation 层）：行情首页 + 自选股 + 涨跌榜

**Phase 1.2（详情页，1 周）**:
- T04-T05（股票详情 + K线图）
- T12（StockDetailNotifier）

**Phase 1.3（搜索与优化，1 周）**:
- T06/T13（搜索）
- T19-T21（Route Guards + Error Handling + Performance）

**Phase 1.4（合规与测试，1 周）**:
- T07-T09（访客模式 + 市场状态 + Stale Quote）
- T22（Data Models）
- 单元测试 + 集成测试

### 7.2 风险缓解

| 风险 | 缓解措施 |
|------|---------|
| Polygon 授权未完成 | 使用 Mock WebSocket Server 开发，授权完成后切换真实端点 |
| Protobuf 消息定义缺失 | 先用 JSON 文本帧开发，后续迁移至 Protobuf |
| K线图性能问题 | 早期进行性能测试（500+ 根 K线），必要时引入虚拟化 |
| WebSocket 高频更新掉帧 | 使用 RxDart throttle（100ms），配合 leak_tracker 检测内存泄漏 |

---

## 8. 结论

**资源完整性**: ✅ 高  
**PRD-原型-合约对齐度**: ✅ 高  
**技术可行性**: ✅ 高  
**阻塞项**: ⚠️ 2 个（Polygon 授权、流通股数数据源）

**建议**: 可以开始 Phase 1.1 实现（Data 层 + 核心流程），同时并行解决 Open Questions #1 和 #2。
