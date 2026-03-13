---
provider: services/ams
consumer: services/admin-panel
protocol: REST
status: DRAFT
version: 0
created: 2026-03-13
last_updated: 2026-03-13
last_reviewed: null
sync_strategy: provider-owns
---

# AMS → Admin Panel 接口契约

## 契约范围

Admin Panel 需要读取 AMS 提供的用户账户数据、KYC 申请审核队列以及通知记录，供运营和合规团队进行用户管理、KYC 审核和通知追溯。

## 接口列表

| 端点 | 方法 | 用途 | SLA | 版本引入 |
|------|------|------|-----|---------|
| /admin/users | GET | 用户列表+搜索（支持分页、按姓名/邮箱/状态筛选） | TBD | v1 |
| /admin/users/:id | GET | 用户详情（账户信息、KYC 状态、风险等级） | TBD | v1 |
| /admin/kyc/queue | GET | KYC 待审核队列（按提交时间排序、支持状态筛选） | TBD | v1 |
| /admin/kyc/:id/approve | POST | KYC 审核（通过/拒绝，附审核意见） | TBD | v1 |
| /admin/notifications | GET | 通知记录（系统通知、用户通知历史） | TBD | v1 |

> **Note**: 端点列表为初始占位，待实现阶段填充具体路径和参数。

## 数据流向

AMS 作为 Provider，向 Admin Panel 暴露用户账户、KYC 审核、通知等管理接口。Admin Panel 运营人员通过这些接口查看用户信息、处理 KYC 审核队列、追溯通知发送记录。KYC 审核结果由 Admin Panel 写回 AMS，触发后续账户状态变更。

## 访问控制

Admin Panel 所有请求需携带 admin JWT token，额外要求 RBAC 角色验证。
Provider 侧需检查请求来源为 admin-panel 服务且具备对应角色权限。

- KYC 审核操作 (`POST /admin/kyc/:id/approve`) 需要 `compliance-officer` 或 `kyc-reviewer` 角色
- 用户数据查看需要 `ops-staff` 及以上角色
- 所有操作记入审计日志

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

## Changelog

暂无变更记录。
