---
provider: services/fund-transfer
consumer: services/admin-panel
protocol: REST
status: DRAFT
version: 0
created: 2026-03-13
last_updated: 2026-03-13
last_reviewed: null
sync_strategy: provider-owns
---

# Fund Transfer → Admin Panel 接口契约

## 契约范围

Admin Panel 需要审批 Fund Transfer 服务的出金请求、查看入金记录、对账报告以及可疑交易报告（SAR），供合规团队进行出金审批、资金监控和反洗钱合规管理。

## 接口列表

| 端点 | 方法 | 用途 | SLA | 版本引入 |
|------|------|------|-----|---------|
| /admin/withdrawals/queue | GET | 待审批出金队列（按金额/风险等级/提交时间排序筛选） | TBD | v1 |
| /admin/withdrawals/:id/approve | POST | 出金审批（通过/拒绝，附审批意见和合规依据） | TBD | v1 |
| /admin/deposits | GET | 入金记录（支持按用户/渠道/时间范围/状态筛选） | TBD | v1 |
| /admin/reconciliation/reports | GET | 对账报告（每日三方对账结果：内部账本/银行流水/托管余额） | TBD | v1 |
| /admin/sar | GET | 可疑交易报告列表（SAR 状态、触发规则、关联交易） | TBD | v1 |

> **Note**: 端点列表为初始占位，待实现阶段填充具体路径和参数。

## 数据流向

Fund Transfer 作为 Provider，向 Admin Panel 暴露出金审批队列、入金记录、对账报告和 SAR 管理接口。合规团队通过这些接口审批大额或高风险出金请求、追溯入金来源、查看每日对账结果以及管理可疑交易报告的上报流程。出金审批结果写回 Fund Transfer 服务，触发后续打款或拒绝流程。

## 访问控制

Admin Panel 所有请求需携带 admin JWT token，额外要求 RBAC 角色验证。
Provider 侧需检查请求来源为 admin-panel 服务且具备对应角色权限。

- 出金审批操作 (`POST /admin/withdrawals/:id/approve`) 需要 `fund-approver` 或 `compliance-officer` 角色
- SAR 查看和管理需要 `compliance-officer` 角色
- 对账报告查看需要 `finance-staff` 或 `compliance-officer` 角色
- 入金记录查看需要 `ops-staff` 及以上角色
- 所有操作记入审计日志

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

## Changelog

暂无变更记录。
