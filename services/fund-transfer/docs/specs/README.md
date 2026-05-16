# Fund Transfer — Tech Specs 导读

> 建议阅读顺序：①→②→③→④→⑤，再按需深入 ⑥⑦

| # | 文件 | 核心内容 | 必读对象 |
|---|------|---------|---------|
| ① | [fund-transfer-system.md](fund-transfer-system.md) | 系统架构总览、出入金状态机、双账分录、合规规则摘要、部署 | 所有工程师 |
| ② | [fund-custody-and-matching.md](fund-custody-and-matching.md) | 托管账户架构（Omnibus）、入金匹配机制、悬挂资金、SEC 15c3-3 Reserve、与 Trading Engine 的资金边界 | 后端 / 合规 |
| ③ | [failure-handling-matrix.md](failure-handling-matrix.md) | 出入金全场景失败矩阵、补偿 Saga、状态修复 SLA | 后端 |
| ④ | [operations-and-edge-cases.md](operations-and-edge-cases.md) | 节假日处理、限额逻辑、CTR/SAR 申报、Admin 审批队列、跨时区规则、KYC Tier 变更处理 | 后端 / 运营 |
| ⑤ | [ach-risk-and-instant-deposit.md](ach-risk-and-instant-deposit.md) | ACH 垫资风险、即时入金 ICT 分层、Return Code 处理、负余额补偿 | 后端 |
| ⑥ | [fx-conversion-flow.md](fx-conversion-flow.md) | 换汇完整流程、锁价机制、AML 筛查、账本分录、失败补偿 | 后端（FX 功能） |
| ⑦ | [api/grpc/fund_transfer.proto](api/grpc/fund_transfer.proto) | gRPC 接口定义（TransferStatus 枚举、审批 RPC、余额消息） | 所有工程师 |

## 关键设计决策速查

| 问题 | 答案 | 出处 |
|------|------|------|
| KYC Tier 命名和限额 SSOT 在哪？ | AMS 服务，详见 `docs/contracts/ams-to-fund.md` | fund-transfer-system.md §6 |
| FX 换汇要不要做 AML？ | 要，每次必须 | fx-conversion-flow.md §6.5 |
| 负余额时可以出金吗？ | 不可以，一律禁止 | ach-risk-and-instant-deposit.md §5.4 |
| Structuring 检测窗口？ | 双窗口：24h + 7d | operations-and-edge-cases.md §3.2 |
| AMS 宕机时能入金吗？ | 不能，缓存失效时一律拒绝 | operations-and-edge-cases.md §2.6 |
| settlement 事件丢失怎么办？ | 周期性 ReconciliationJob 自愈 | fund-custody-and-matching.md §4.4 |
| QUEUED_HOLIDAY 恢复时需重新 AML？ | 是 | operations-and-edge-cases.md §1.3 |
| Wire SWIFT 金额差 $25 会悬挂吗？ | 不会，容忍 ≤$50/0.5% | fund-custody-and-matching.md §3.4 |
| proto TransferStatus 有哪些状态？ | 19 个，含 BLOCKED_AML/REVERSED/QUEUED_HOLIDAY 等 | fund_transfer.proto |
