---
provider: services/fund-transfer
consumer: mobile
protocol: REST
status: DRAFT
version: 0
created: 2026-03-13
last_updated: 2026-03-13
last_reviewed: null
sync_strategy: provider-owns
---

# Fund Transfer → Mobile 接口契约

## 契约范围

移动端出入金操作、银行卡管理、资金余额查询。Fund Transfer 为 Flutter 移动客户端提供完整的资金管理能力，包括入金/出金发起、出入金记录查询、银行卡绑定与解绑、以及账户余额（总资产、可用、冻结、待结算）展示。

## 接口列表

| 方法 | 路径 | 用途 | 协议 | SLA | 版本引入 |
|------|------|------|------|-----|---------|
| GET | /api/v1/balance | 账户余额：总资产、可用余额、冻结金额、待结算金额 | REST | TBD | v1 |
| POST | /api/v1/deposit | 发起入金（指定银行卡、金额、币种） | REST | TBD | v1 |
| POST | /api/v1/withdrawal | 发起出金（需生物识别确认） | REST | TBD | v1 |
| GET | /api/v1/fund/history | 出入金记录（分页，支持按类型、日期筛选） | REST | TBD | v1 |
| GET | /api/v1/bank-accounts | 已绑定银行卡列表（卡号仅显示后 4 位：****1234） | REST | TBD | v1 |
| POST | /api/v1/bank-accounts | 绑定新银行卡（需身份重验证：生物识别或 2FA） | REST | TBD | v1 |
| DELETE | /api/v1/bank-accounts/:id | 解绑银行卡（软删除，保留审计记录） | REST | TBD | v1 |

> **Note**: 接口列表为初始占位，待各域工程师在实现阶段填充具体请求/响应 schema。

## 数据流向

Mobile 提交入金/出金请求（附带 Idempotency-Key），Fund Transfer 返回交易状态和余额更新。银行卡号在所有响应中均脱敏显示（仅后 4 位：`****1234`）。余额接口返回分项余额，帮助用户理解"可用"与"待结算"的区别。

## 认证与安全

- **所有端点均需 JWT Bearer token**
- 出金操作（POST /withdrawal）额外要求**生物识别认证**
- 绑定新银行卡（POST /bank-accounts）额外要求**身份重验证**（生物识别或 2FA）
- **所有状态变更请求必须携带 `Idempotency-Key` header**（UUID v4 格式）
  - 服务端缓存 idempotency key 72 小时
  - 重复提交返回缓存的原始响应
- **待结算资金不可出金**：US 股票 T+1，HK 股票 T+2
- 每用户最多绑定 **5 张银行卡**
- 新绑定银行卡有 **3 天冷静期**，期间不可用于出金
- 银行卡号存储使用 **AES-256-GCM 加密**

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`services/fund-transfer/api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

## Changelog

暂无变更记录。
