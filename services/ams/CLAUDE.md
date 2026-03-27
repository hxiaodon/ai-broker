# AMS -- 账户管理服务（Account Management Service）

## 域职责范围

认证、用户注册、KYC/AML 流程管道、通知服务和完整的账户生命周期管理。AMS 是根身份服务 —— 其他所有服务都依赖 AMS 的 auth token 和账户验证。

**主要职责**：
- JWT RS256 token 签发（15 分钟 access / 7 天 refresh）
- 双司法管辖区用户注册（US SSN + HK HKID）
- KYC 文档采集、验证和状态机管理
- AML 筛查（OFAC SDN + HK 指定人士名单）
- 账户状态管理（PENDING / ACTIVE / SUSPENDED / CLOSED）
- 通知分发（push、SMS、email）用于账户和合规事件
- 会话管理和设备绑定

## 技术栈

- **语言**：Go 1.22+
- **数据库**：MySQL 8.0+（账户、KYC 记录、通知）
- **缓存**：Redis 7+（会话、token 黑名单、速率限制）
- **RPC**：gRPC（服务间）、REST（客户端网关）
- **API**：`api/grpc/`（gRPC）、`api/rest/`（OpenAPI）

## 文档索引

| 路径 | 内容 |
|------|------|
| `docs/prd/` | 域级产品需求文档 —— KYC 规则、账户生命周期（TBD） |
| `docs/specs/` | 技术规范 —— 认证流程、KYC 流程设计 |
| `docs/specs/*.tracker.md` | 实现跟踪文件（动态进度 + 验收记录） |
| `docs/active-features.yaml` | 域级功能实现进度仪表盘 |
| `docs/patches.yaml` | Patch 注册表（活跃补丁 + 技术债） |
| `docs/specs/api/grpc/` | gRPC proto 定义 |
| `docs/specs/api/rest/` | REST OpenAPI 规范（TBD） |
| `docs/threads/` | AMS 决策协作线程 |
| `src/internal/` | 实现代码（TBD） |

## 依赖关系

### 上游
无 —— AMS 是根身份服务。

### 下游（AMS 的消费方）
- **交易引擎**：下单前验证账户状态 + auth
- **资金转账**：验证 KYC 等级以确定提现限额
- **行情数据**：WebSocket 连接认证
- **移动端**：登录、注册、KYC 界面
- **管理后台**：KYC 审核队列、用户管理

### 接口契约
- `docs/contracts/ams-to-trading.md`：账户状态、auth token 验证
- `docs/contracts/ams-to-fund.md`：KYC 等级、账户验证

## 域级 Agent

**Agent**：`.claude/agents/ams-engineer.md`
Go 后端、认证系统、KYC/AML 合规和通知基础设施专家。

## 合规规则参考

本域遵循的合规规则由三层源头定义，按查阅优先级列出（详见 `docs/SPEC-ORGANIZATION.md` 三层知识架构）：

| 规则类型 | 规范文件 | 覆盖范围 |
|---------|---------|---------|
| 金融编码标准 | `../.claude/rules/financial-coding-standards.md` | Rule 1-7：Decimal（禁用浮点）、UTC 时间戳、错误处理、幂等性、审计日志、密钥管理、输入验证 |
| 安全与认证 | `../.claude/rules/security-compliance.md` | JWT RS256、设备绑定、PII 加密/脱敏、API 安全、移动安全、速率限制 |
| 账户与 KYC 模型 | `docs/specs/account-financial-model.md` | 权威业务模型：账户类型、KYC 字段、AML 规则、状态机、保留策略 |
| 认证体系 | `docs/specs/auth-architecture.md` | Token 生命周期、权限模型（RBAC）、gRPC mTLS、公钥分发（JWKS） |
| PII 加密实现 | `docs/specs/pii-encryption.md` | 加密字段分类、AES-256-GCM 实现、密钥管理策略、脱敏规则、数据库约束 |
| KYC 产品流程 | `docs/prd/kyc-flow.md` | 用户开户路径、KYC 供应商集成、文档验证、状态转换、管理后台审核队列 |
| AML 合规流程 | `docs/prd/aml-compliance.md` | OFAC 制裁筛查、HK 指定人士筛查、PEP 分类、风险评分、SARs/CTRs 申报 |

> **使用方法**：按任务类型在上表找到对应规范文件。例如实现 JWT 认证时，先查 `.claude/rules/security-compliance.md` 了解全局要求，再查 `docs/specs/auth-architecture.md` 理解 AMS 的完整设计。
