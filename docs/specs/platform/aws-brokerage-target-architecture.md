---
type: platform-architecture
level: L3
scope: cross-domain
status: DRAFT
created: 2026-04-10T00:00+08:00
maintainer: codex
applies_to:
  - mobile
  - services/ams
  - services/trading-engine
  - services/market-data
  - services/fund-transfer
  - services/admin-panel
---

# 美股互联网券商 AWS 完整部署成熟方案

> 本文档面向“美股互联网券商”场景，给出一套覆盖前台业务、后台业务、中间件、数据、网络、安全、容灾、运维的 AWS 目标架构。
> 文档以 AWS 官方资料为依据，并结合本仓库当前的域划分与契约约束形成可落地方案。
>
> 对齐文档：
> - [Service Dependency Map](../../contracts/INDEX.md)
> - [Kafka 拓扑规范](./kafka-topology.md)
> - [Go 微服务架构规范](./go-service-architecture.md)

## 1. 目标与范围

### 1.1 业务目标

本方案覆盖一家面向零售客户的美股互联网券商，至少包含以下业务域：

- 客户端渠道：Mobile、H5、Admin Panel、开放 API
- 账户域：注册、登录、设备管理、KYC/KYB、AML、税务表单、账户限制
- 行情域：实时报价、K 线、深度行情、行情权限、搜索、观察列表
- 交易域：下单、撤单、订单生命周期、预交易风控、路由、成交回报、持仓、盈亏
- 资金域：入金、出金、ACH/Wire、银行卡/银行账户绑定、买力、现金台账
- 中后台：运营、合规审核、风控预警、清算、对账、公司行动、结单、税单、审计
- 数据与分析：监管报表、经营分析、埋点、告警、追踪、数据留痕

### 1.2 非目标

本文档不替代以下内容：

- 券商牌照、清算模式、做市商/清算商合同选择
- SEC/FINRA/州监管法律意见
- 交易所会员、市场数据许可、税务申报法律判断

本文档只提供云上技术底座与部署方案。合规条款是否满足，仍需法务、合规和审计团队做正式确认。

## 2. 设计结论

### 2.1 推荐总方案

推荐采用以下组合，而不是“所有服务统一一种运行时”：

- `us-east-1` 作为美股主 Region，承载全部交易写路径、市场数据接入、订单路由、主账本
- `us-west-2` 作为跨 Region 灾备 Region，承载 warm standby / pilot light
- 多账号 Landing Zone，由 AWS Control Tower + AWS Organizations 治理
- 业务服务主运行时为 Amazon EKS
- 超低延迟和长连接敏感组件使用 EC2 专用节点组或独立 EC2 Auto Scaling Group
- 事务数据库统一采用 Amazon Aurora MySQL
- 事件总线统一采用 Amazon MSK
- 中间件分层使用：API Gateway / NLB / ALB / MSK / EventBridge / SQS FIFO / Amazon MQ / Step Functions / ElastiCache
- 审计留存统一落到 S3 Object Lock，备份落到 AWS Backup Vault Lock

### 2.2 三个核心架构判断

#### 判断 A：热交易链路不能完全 Serverless 化

下单、预风控、买力检查、FIX 会话、成交回报、行情推送都对连接状态、延迟抖动、控制面稳定性敏感。成熟方案应该把 Serverless 用在“胶水”和“编排”层，而不是订单热路径。

因此：

- 热路径用 EKS + EC2
- Lambda 只用于轻量 webhook、异步任务、文件触发和运营自动化
- Step Functions 只用于 KYC、对账、结单、工单、批处理编排

#### 判断 B：交易写路径推荐单主 Region，读路径与接入层可多 Region

对于单一“美股交易”场景，成熟互联网券商不建议从 Day 1 就做跨 Region 双主订单写入。原因是：

- 订单、买力、风险、持仓、成交之间一致性要求高
- 跨 Region 双写会显著放大幂等、顺序、时钟、冲突处理复杂度
- 大多数互联网券商的核心交易恢复目标是“低 RTO + 低 RPO + 清晰切换 runbook”，而不是“无感双主”

因此目标形态是：

- `us-east-1`：交易主 Region
- `us-west-2`：灾备 Region
- 前台入口、静态资源、只读查询、报表、监控可多 Region
- 订单写入、风控、账本、清算主状态保持单主

#### 判断 C：中间件必须分角色，而不是“一个消息系统打天下”

建议严格区分：

- `Amazon MSK`：核心领域事件总线，承载订单事件、成交事件、资金事件、审计事件、行情标准化流
- `Amazon EventBridge`：跨域编排、SaaS/运营集成、定时触发，不放热交易链路
- `Amazon SQS FIFO`：需要顺序和重试隔离的异步工作队列，例如结单生成、对账任务、通知补偿
- `Amazon MQ`：只用于对接遗留 JMS/AMQP/STOMP 系统，不上核心交易链路
- `ElastiCache for Redis`：热缓存、限流、会话、WebSocket session map、热点参考数据

## 3. 目标架构总览

```text
Clients
  ├─ Mobile App
  ├─ H5 WebView
  ├─ Admin Panel
  └─ Partner / Open API
        │
        ▼
Global Edge
  ├─ Route 53 / Global Accelerator
  ├─ CloudFront
  ├─ AWS WAF + Shield Advanced
  └─ API Gateway / NLB / ALB
        │
        ▼
Application Layer (us-east-1 primary, us-west-2 DR)
  ├─ EKS: AMS / Fund Transfer / Market API / Trading API / Backoffice / Admin API
  ├─ EC2: FIX Gateway / Market Feed Adapter / Smart Router Adapter
  ├─ Step Functions / EventBridge Scheduler / Batch
  └─ Notification / Document / Reporting workers
        │
        ▼
Middleware
  ├─ Amazon MSK
  ├─ EventBridge
  ├─ SQS FIFO
  ├─ Amazon MQ
  ├─ ElastiCache Redis
  └─ RDS Proxy
        │
        ▼
Data Layer
  ├─ Aurora MySQL (Global Database)
  ├─ DynamoDB (idempotency / token / small-state)
  ├─ S3 + Object Lock
  ├─ OpenSearch
  ├─ Lake Formation + Glue + Athena
  └─ Security Lake / Backup Vault Lock
        │
        ▼
External Connectivity
  ├─ Clearing / Executing Broker
  ├─ Exchanges / Market Data Vendors
  ├─ Banks / ACH / Wire
  ├─ KYC / AML / Fraud vendors
  └─ Tax / Statement / Corp Action data providers
```

## 4. 账号、组织与治理

### 4.1 Landing Zone

使用 AWS Control Tower 建立标准 Landing Zone，并通过 AWS Organizations 管理账号与策略。

推荐 OU 和账号如下：

| OU | 账号 | 作用 |
|---|---|---|
| Root | management | Organizations 管理账号，仅做组织管理 |
| Security | log-archive | 组织级 CloudTrail、Config、Security 日志归档 |
| Security | audit-security | Security Hub、GuardDuty、Audit Manager、Security Lake 聚合 |
| Shared | identity | IAM Identity Center、员工访问、跨账号角色入口 |
| Shared | network | Transit Gateway、Direct Connect、Private Hosted Zone、集中防火墙 |
| Shared | platform | ECR、CI/CD、制品、共享 Helm/镜像/基础模块 |
| Production | prod-edge | CloudFront、WAF、API Gateway、Global Accelerator |
| Production | prod-core | EKS、EC2、Aurora、MSK、Redis、订单与资金主业务 |
| Production | prod-data | 数据湖、Glue、Lake Formation、Athena、OpenSearch、BI |
| NonProd | nonprod-shared / nonprod-core | 开发、测试、预发 |

补充约束：

- `prod-core` 账号内同时承载 `us-east-1` 主 Region 和 `us-west-2` DR Region 的核心运行时与 MSK 集群
- 这样做可以减少跨账号复制复杂度，并满足 MSK Replicator 对同账号 MSK 集群复制的部署约束

### 4.2 治理控制

基线控制建议：

- 用 Service Control Policies 限制生产账号绕过日志、加密、Region 白名单、删除防护
- 组织级 CloudTrail、AWS Config、Security Hub、GuardDuty 全量开启
- 通过 IAM Identity Center 管理员工登录和跨账号授权
- 生产和非生产必须分账号，不共享 VPC、不共享数据库
- 生产所有 S3、EBS、RDS、OpenSearch、MSK 默认开启加密

## 5. Region、可用区与容灾策略

### 5.1 Region 选择

推荐：

- 主 Region：`us-east-1`
- 灾备 Region：`us-west-2`

理由：

- 美股交易与市场数据生态集中在美国东部
- `us-east-1` 适合承载主交易写链路
- `us-west-2` 适合作为真正的 Region 级容灾，而不是同区域近邻
- 两个 Region 对大多数核心 AWS 服务支持成熟

### 5.2 建议的高可用模式

| 层级 | 模式 | 说明 |
|---|---|---|
| 静态前端 | Active-Active | CloudFront 多源容灾 |
| 公网 API 入口 | Active-Active | 入口层多 Region，后端按健康度切换 |
| 行情查询与只读接口 | Active-Active | 读流量可跨 Region 分担 |
| 订单写路径 | Active-Passive | 主 Region 写，DR Region 预热待切换 |
| 数据库 | Aurora Global Database | 主写从读，Region 故障时提升从库 |
| Kafka 事件总线 | MSK + MSK Replicator | 跨 Region 异步复制 |

### 5.3 RTO / RPO 目标

| 域 | RTO | RPO | 说明 |
|---|---|---|---|
| 客户登录/账户查询 | 15 分钟 | < 5 分钟 | EKS + Aurora Global DB + DNS 切换 |
| 行情读服务 | 15 分钟 | 接近 0 | 行情可重新订阅，状态不以 DB 为唯一来源 |
| 订单写链路 | 30 分钟 | < 1 分钟 | 包含人工 runbook、路由切换、FIX 会话恢复 |
| 清算/对账/报表 | 4 小时 | < 15 分钟 | 非热路径 |
| 审计与档案 | 0 数据丢失目标 | 0 | 双重 WORM 与跨 Region 复制 |

### 5.4 切换原则

- 市场交易时段内，Region 切换必须有明确运营 Runbook 和人工审批
- 尽量在闭市后执行主 Region 计划性切换
- 严禁跨 Region 分布式事务
- 故障切换前先冻结新订单入口，再切换数据库和事件总线消费者，再恢复入单

## 6. 网络与接入架构

### 6.1 VPC 分层

在 `prod-core` 账号中，每个 Region 至少部署一套三 AZ VPC：

- Public Subnets：ALB / NAT / Bastion-less access endpoints
- Private App Subnets：EKS worker nodes、内部 ALB/NLB、业务 Pod
- Private Data Subnets：Aurora、Redis、MSK、OpenSearch
- Isolated Connectivity Subnets：FIX / market feed / partner connectivity EC2

### 6.2 关键网络组件

推荐组件：

- AWS Transit Gateway：跨账号 / 跨 VPC 汇聚
- AWS Direct Connect：对接清算商、执行经纪商、市场数据供应商的主连接
- Site-to-Site VPN：Direct Connect 的补充与过渡
- AWS PrivateLink：对接同样运行在 AWS 的合作方，避免公网暴露
- VPC Endpoints：S3、STS、ECR、KMS、Secrets Manager、CloudWatch、MSK 等走私网
- AWS Network Firewall：集中出入口控制和 egress filtering

### 6.3 互联网入口

推荐拆分：

- 静态站点与 H5：S3 + CloudFront + WAF
- Public REST API：API Gateway + WAF
- 高并发 WebSocket 与低延迟 API：Global Accelerator + NLB/ALB + EKS
- Admin Panel：CloudFront + WAF + IAM Identity Center / 企业 IdP + 私网 API

### 6.4 外部金融连接

连接模式按成熟度递进：

| 外部对象 | 推荐方式 | 说明 |
|---|---|---|
| 执行经纪商 / Clearing | Direct Connect 或 VPN + FIX | 大多数互联网券商前期不是自建交易所会员 |
| 市场数据供应商 | Direct Connect / PrivateLink / 专线 | 取决于供应商能力和许可等级 |
| 银行 / 支付机构 | API over mTLS、SFTP、AS2 | 小额实时走 API，批量文件走 Transfer Family |
| KYC / AML / Fraud vendor | API Gateway + mTLS 或 PrivateLink | 不走热链路 |

> 建议：如果业务模式是 introducing broker，应优先对接清算/执行经纪商，而不是直接与交易所建立首期自营连接。直接交易所接入应作为后续增强阶段。

## 7. 业务服务全景部署

### 7.1 前台渠道层

| 服务 | 部署方式 | AWS 服务 | 说明 |
|---|---|---|---|
| Mobile API / BFF | EKS | EKS + ALB/NLB | 聚合 AMS、Trade、Fund、Market Data |
| H5 静态站点 | 静态托管 | S3 + CloudFront | 合规披露、营销页、流程页 |
| Admin Panel 前端 | 静态托管 | S3 + CloudFront | 内部后台 UI |
| Admin API | EKS | EKS + Private ALB | 仅内部运营与合规人员 |
| Open API / Partner API | API Gateway | API Gateway + usage plan + WAF + mTLS | 对机构或量化客户开放 |

### 7.2 账户与身份域（AMS）

建议拆分服务：

- 认证服务：登录、MFA、设备绑定、token、session
- 账户主数据服务：个人资料、税务信息、合规状态、权限
- KYC 编排服务：OCR、人脸、名单筛查、人工复核
- 限制与风控服务：交易权限、出入金限制、制裁名单、黑名单
- 文档服务：身份证明、表单、协议、审计附件

部署建议：

- 运行时：EKS
- 数据库：Aurora MySQL
- 小状态：DynamoDB 或 Redis
- 文件与原件：S3 + Object Lock
- 流程编排：Step Functions
- 供应商集成：API Gateway / PrivateLink / SQS

### 7.3 行情域（Market Data）

建议拆分为两层：

- 接入与标准化层：feed adapter、归一化、权限判断
- 分发层：查询 API、WebSocket、缓存、K 线聚合

部署建议：

- 市场数据接入器：EC2 专用实例或 EKS 专用节点组
- 查询与推送服务：EKS
- 热缓存：Redis Cluster
- 标准化流：MSK
- 历史与归档：S3
- 搜索与证券主数据：OpenSearch + Aurora

关键设计：

- 行情权限控制单独做 entitlement service
- 交易校验所用价格与客户端展示价格要同源或可追溯
- WebSocket fanout 不经 API Gateway 热路径，直接走 NLB/ALB

### 7.4 交易域（Trading Engine）

建议拆分服务：

- Order API / Order Gateway
- Pre-Trade Risk
- Buying Power / Exposure Check
- OMS / Order State Machine
- Execution Adapter / FIX Gateway
- Fill Processor
- Position / PnL Service
- Corporate Action Adjuster
- Surveillance / Audit Event Publisher

部署建议：

- OMS、Risk、Position、P&L：EKS
- FIX Gateway、SOR connector、broker adapter：EC2 专用 ASG 或 EKS 专用节点组
- 事务库：Aurora MySQL
- 热状态缓存：Redis
- 领域事件：MSK

关键规则：

- 下单同步链路使用 gRPC / 内部 RPC，不经 EventBridge/SQS
- 订单最终状态以 OMS + 审计事件为准
- Kafka 只承载异步下游传播，不承担同步成交流转决策
- 严格执行 Outbox Pattern，与现有 [Kafka 拓扑规范](./kafka-topology.md) 对齐

### 7.5 资金域（Fund Transfer）

建议拆分服务：

- 银行账户绑定 / 验证
- 入金服务（ACH push / pull、Wire）
- 出金服务
- 现金余额与买力镜像
- 双分录资金台账
- AML / 异常资金监测
- 对账与失败补偿

部署建议：

- 运行时：EKS
- 数据库：Aurora MySQL
- 工作流：Step Functions
- 顺序工作队列：SQS FIFO
- 银行文件交换：AWS Transfer Family
- 审计与对账文件：S3 + Object Lock

### 7.6 中台与后台服务

建议补齐以下后台服务，它们通常是互联网券商最容易被忽略、但最影响上线成熟度的部分：

| 后台域 | 主要能力 | AWS 形态 |
|---|---|---|
| Compliance Case Management | KYC 复审、AML 告警、冻结/解冻、人工审批 | EKS + Aurora + OpenSearch + Step Functions |
| Reconciliation | 银行对账、清算对账、持仓现金核对 | Batch/EKS Jobs + SQS + S3 |
| Settlement & Clearing | 成交确认、结算、失败重试、券源/交收 | EKS + Aurora + Transfer Family |
| Statement & Tax | 日结单、月结单、1099/W-8/W-9 文档 | Batch + S3 + Object Lock |
| Corporate Actions | 拆股、派息、并购、symbol change | Batch + Aurora + Kafka |
| Customer Support Ops | 工单、账户恢复、风控处置 | Admin Panel + EKS |
| Risk Surveillance | 异常下单、频繁撤单、限价偏离、欺诈 | EKS + OpenSearch + Athena |

## 8. 中间件设计

### 8.1 中间件选型总表

| 类别 | AWS 服务 | 在本方案中的角色 | 是否允许上热交易链路 |
|---|---|---|---|
| API 接入 | API Gateway | Public REST/Open API、鉴权、配额、mTLS | 否，除非是客户控制面 API |
| 四层转发 | NLB | WebSocket、FIX、低延迟 TCP | 是 |
| 七层转发 | ALB | 常规 HTTP/HTTPS、内部服务入口 | 是 |
| 事件流 | Amazon MSK | 核心领域事件总线 | 是，但只用于异步传播 |
| 集成总线 | EventBridge | 工作流触发、跨域通知、SaaS 集成 | 否 |
| 队列 | SQS FIFO | 顺序异步任务、补偿、重试隔离 | 否 |
| 遗留消息 | Amazon MQ | JMS/AMQP/STOMP 兼容 | 否 |
| 缓存 | ElastiCache Redis | 热缓存、session map、限流 | 是 |
| 工作流 | Step Functions | KYC、AML、对账、审批、批处理编排 | 否 |
| 定时 | EventBridge Scheduler | 定时批任务、市场开闭市作业 | 否 |
| 关系库连接池 | RDS Proxy | EKS 到 Aurora 连接复用 | 是 |
| 文件交换 | Transfer Family | SFTP/FTPS/AS2 对接外部机构 | 否 |

### 8.2 推荐消息架构

#### 核心事件总线：Amazon MSK

MSK 负责：

- 订单生命周期事件
- 成交与持仓更新事件
- 资金到账/出金事件
- 审计事件
- 行情标准化流
- 中后台异步消费

MSK Topic、DLQ、Envelope、Outbox 设计沿用现有 [Kafka 拓扑规范](./kafka-topology.md)。

#### 集成与编排：EventBridge

EventBridge 负责：

- KYC vendor callback 触发后续工作流
- 闭市批任务触发
- 内部非核心域集成
- 面向 SaaS 或运营系统的事件出口

不建议：

- 用 EventBridge 传订单状态热流
- 用 EventBridge 做预风控同步链路

#### 顺序工作队列：SQS FIFO

SQS FIFO 用于：

- 每账户顺序处理的对账任务
- 结单生成和重试
- 通知补偿
- 小额资金异步校验

#### 遗留接口总线：Amazon MQ

如果必须对接遗留系统：

- JMS
- AMQP
- STOMP
- 已有 MQ 中间件的运营系统

则用 Amazon MQ 做协议隔离层，但必须与核心交易链路解耦，禁止成为订单主链路依赖。

## 9. 数据层设计

### 9.1 事务数据

推荐 Aurora MySQL 按业务域拆库：

- `aurora-ams`
- `aurora-trading`
- `aurora-fund`
- `aurora-backoffice`

设计原则：

- 每个域独立 schema / cluster，避免全平台单库
- 生产库全部 Multi-AZ
- 前台高并发连接经 RDS Proxy
- 审计和业务表分层，不在高频订单表里堆积长周期留档字段

### 9.2 Global Database

Aurora Global Database 用于：

- 跨 Region 灾备
- DR Region 本地低延迟读
- 故障切换时提升只读 Region

注意事项：

- 交易写仍然只在主 Region
- 不做双 Region 同时写
- 切换有 runbook，不做隐式自动双主

### 9.3 缓存与热状态

ElastiCache for Redis 主要承载：

- 证券主数据热点缓存
- 行情热点缓存
- WebSocket session registry
- 限流计数器
- 幂等键短期存储
- 临时买力镜像和风控热点状态

### 9.4 对象与档案

S3 分层建议：

- `s3-brokerage-documents`：KYC 文件、协议、上传原件
- `s3-brokerage-statements`：结单、税单、确认单
- `s3-brokerage-audit-archive`：订单、成交、资金、审计原始留档
- `s3-brokerage-data-lake`：业务明细、埋点、分析数据

其中：

- 审计与法定留档桶开启 Object Lock
- 长期冷数据转 Glacier Flexible Retrieval / Deep Archive
- 跨 Region 复制必须结合保留策略统一设计

### 9.5 搜索与分析

推荐：

- OpenSearch：运营检索、日志聚合、合规检索、订单调查
- Lake Formation + Glue + Athena：湖仓查询与监管报表
- 可选 Redshift：重 BI 和财务报表
- 可选 FinSpace / Managed kdb：高频时序分析、量化研究、回放

## 10. 关键业务流落地方式

### 10.1 开户与 KYC

```text
Mobile/H5
  -> API Gateway / BFF
  -> AMS
  -> Step Functions
  -> OCR / Face / AML / Sanctions vendors
  -> Manual Review Queue
  -> Account Approved
  -> Kafka event: brokerage.ams.account.kyc-approved
  -> Trading/Fund/Admin consumers
```

落地建议：

- KYC 工作流用 Step Functions 编排
- 人工复核任务进入 Admin Panel
- 原始材料入 S3 Object Lock
- 审批轨迹写入 Aurora + 审计 Topic

### 10.2 实时行情

```text
Vendor / Feed
  -> Feed Adapter (EC2/EKS dedicated)
  -> Normalizer
  -> MSK
  -> Redis / Kline aggregator
  -> Quote API + WebSocket service
  -> Mobile / Admin / Trading consumers
```

落地建议：

- 标准化流写 MSK
- 热展示和秒级查询走 Redis
- 历史 K 线和重建数据落 S3
- 行情权限由 entitlement service 控制

### 10.3 下单与成交

```text
Client
  -> BFF / Trading API
  -> Auth + Account Status
  -> Pre-Trade Risk
  -> Buying Power / Exposure
  -> OMS transaction commit
  -> Outbox publish to MSK
  -> FIX Gateway / Broker Adapter
  -> Execution Report
  -> OMS status update
  -> Position/PnL/Fund/Admin/Notification consumers
```

落地建议：

- 订单主链路全部同步 RPC
- OMS 持久化成功后再通过 Outbox 发事件
- 成交回报先写 OMS，再扩散给下游
- 整个平台以 correlation ID 打通日志、trace、Kafka envelope

### 10.4 入金、出金与对账

```text
Client
  -> Fund API
  -> Step Functions
  -> Bank API / File Channel
  -> Ledger update
  -> Kafka event
  -> Reconciliation jobs
  -> Statement / Admin / AML consumers
```

落地建议：

- 强事务部分落 Aurora
- 银行异步回执使用 SQS FIFO + Step Functions
- 日终对账使用 Batch / EKS Jobs
- 对账差异自动生成运营工单

## 11. 安全、审计与合规控制

### 11.1 身份与权限

- 员工登录：IAM Identity Center + 企业 IdP
- 服务到服务：IAM role + EKS Pod Identity / IRSA + mTLS
- 客户登录：由 AMS 统一管理；如需托管认证能力，可在 AMS 后接 Cognito，但业务状态仍归 AMS
- 生产权限采用 JIT 审批、最小权限、短期凭证

### 11.2 数据保护

- 全部生产数据默认 KMS 加密
- Secrets 统一放 Secrets Manager
- 私有证书统一放 ACM Private CA
- 对极高敏感密钥与 PII tokenization，可选 Nitro Enclaves / CloudHSM

### 11.3 外围安全

- CloudFront / API Gateway / ALB 前统一接 WAF
- 购买 Shield Advanced 保护公网入口
- 通过 Firewall Manager 做组织级策略下发
- 使用 Network Firewall 做中心化南北向与出站控制

### 11.4 检测与审计

建议至少开启：

- CloudTrail organization trail
- AWS Config
- GuardDuty
- Security Hub
- Inspector
- Security Lake
- Audit Manager

### 11.5 留档与不可篡改

技术底座建议：

- 订单、成交、资金、审计原始文件落 S3 Object Lock
- 数据库和关键存储备份进入 AWS Backup Vault Lock
- 法律调查和监管检查使用 Legal Hold + 桶保留策略

说明：

- S3 Object Lock 与 AWS Backup Vault Lock 都能提供 WORM 能力
- 是否满足 SEC / FINRA 具体条款，需要结合你们的 retention policy、监督流程、WSP、审计流程共同确认

## 12. 可观测性与运维

### 12.1 监控体系

建议分层：

- 指标：Amazon Managed Service for Prometheus
- 大盘：Amazon Managed Grafana 或自管 Grafana
- 日志：CloudWatch Logs + OpenSearch + S3
- Trace：OpenTelemetry + X-Ray / OTLP backend
- 合成监控：CloudWatch Synthetics

### 12.2 告警体系

按域拆分：

- 交易热链路：订单拒单率、风控延迟、FIX session、成交回报延迟
- 行情：行情断流、tick lag、WebSocket 断连率
- 资金：银行回执失败率、账实不一致、待处理工单
- 安全：高危发现、异常 API 调用、凭证泄露、配置漂移

### 12.3 运维原则

- 市场交易时段禁止滚动升级 FIX gateway
- 交易域和非交易域分不同发布窗
- 生产变更必须支持快速回滚
- 至少每季度做一次 Region DR 演练

## 13. CI/CD 与基础设施交付

### 13.1 推荐交付栈

- IaC：Terraform 或 AWS CDK
- 镜像仓库：Amazon ECR
- 镜像扫描：ECR Enhanced Scanning / Inspector
- 部署：Argo CD 或 CodePipeline + Helm
- 配置与密钥：SSM Parameter Store + Secrets Manager

### 13.2 流水线阶段

```text
Git Push / PR
  -> Unit Test
  -> Contract Test
  -> SAST / Dependency Scan
  -> Build Image
  -> Push to ECR
  -> Sign / Approve
  -> Deploy to NonProd
  -> Integration Test
  -> Manual Approval
  -> Deploy to Prod
```

### 13.3 基础设施分层

- Layer 1：Landing Zone / 账号 / IAM / 网络
- Layer 2：EKS / Aurora / MSK / Redis / OpenSearch
- Layer 3：基础中间件与共享服务
- Layer 4：各业务服务

## 14. 与当前仓库服务的映射

| 仓库服务 | 推荐运行时 | 主存储 | 关键中间件 | 备注 |
|---|---|---|---|---|
| `services/ams` | EKS | Aurora MySQL + S3 | Step Functions、SQS、Redis | 账户、KYC、限制、通知 |
| `services/trading-engine` | EKS + EC2 | Aurora MySQL + Redis | MSK、NLB、RDS Proxy | OMS/Risk/Position 在 EKS，FIX/Adapter 在 EC2 |
| `services/market-data` | EKS + EC2 | Redis + Aurora + S3 | MSK、NLB | Feed 接入与标准化建议独立 |
| `services/fund-transfer` | EKS | Aurora MySQL | Step Functions、SQS FIFO、Transfer Family | 入金出金、台账、对账 |
| `services/admin-panel` | CloudFront + EKS API | S3 + Aurora | WAF、IAM Identity Center | 前端静态化，后台 API 私网化 |
| `mobile` / H5 | CloudFront + API Gateway | S3 | WAF、Global Accelerator | 静态资源与 API 分层 |

## 15. 分阶段落地路线

### Phase 0：Landing Zone 与安全基线

- 建立 Control Tower、多账号、SCP、组织级日志、KMS 基线
- 打通 IAM Identity Center、网络、VPC endpoint、WAF、Shield

### Phase 1：账户、前台、资金、文档归档

- 先上线 AMS、Fund Transfer、H5、Admin 基础能力
- 落地 S3 Object Lock、Backup Vault Lock、审计日志

### Phase 2：行情与交易主链路

- 建立 Market Data、Trading Engine、MSK、Redis、Aurora Global DB
- 接入执行经纪商 / 清算商与市场数据源
- 完成下单、撤单、成交、持仓、买力闭环

### Phase 3：后台与监管运营

- 上线对账、结单、税单、公司行动、合规工单
- 建立 OpenSearch / Athena / Lake Formation 分析能力

### Phase 4：容灾与规模化

- 上线 `us-west-2` warm standby
- 配置 MSK Replicator、Aurora Global Database 演练
- 把系统逐步演进为按账户分片的 cell-based 架构

## 16. 不建议的做法

- 不要让订单热路径依赖 Lambda、EventBridge、SQS
- 不要把所有域塞进一个 Aurora 集群
- 不要把所有环境塞进一个 AWS 账号
- 不要把 Amazon MQ 当作核心交易事件总线
- 不要用跨 Region 双写数据库解决单市场交易容灾
- 不要只做“备份”，不做真正的切换 runbook 与演练

## 17. 结论

对“美股互联网券商”而言，最稳妥、最成熟、同时又足够云原生的 AWS 方案是：

- 控制面采用多账号 Landing Zone
- 数据面采用 `us-east-1` 主 Region + `us-west-2` 灾备 Region
- 业务面采用 EKS 为主、EC2 承接低延迟连接组件的混合运行时
- 中间件面采用 MSK 为核心事件骨干，EventBridge/SQS/Step Functions 做外围编排
- 存储面采用 Aurora MySQL + Redis + S3 Object Lock + Lake Formation
- 安全面采用 Control Tower、Identity Center、WAF、Shield、Security Hub、GuardDuty、Audit Manager、Security Lake

如果按这个方案推进，你们可以在不牺牲交易核心确定性的前提下，把账户、资金、行情、交易、中后台和监管留档完整落在 AWS 上。

## 18. AWS 官方参考链接

以下链接均为本次方案调研所依赖的 AWS 官方资料：

- AWS Control Tower: https://docs.aws.amazon.com/controltower/latest/userguide/what-is-control-tower.html
- AWS Organizations SCP: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html
- AWS IAM Identity Center: https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html
- Amazon EKS Best Practices Guide: https://docs.aws.amazon.com/eks/latest/best-practices/introduction.html
- Amazon Aurora Global Database: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html
- Amazon MSK Replicator: https://docs.aws.amazon.com/msk/latest/developerguide/msk-replicator.html
- AWS Direct Connect Resiliency Toolkit: https://docs.aws.amazon.com/directconnect/latest/UserGuide/resiliency_toolkit.html
- Amazon Route 53: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html
- Amazon Application Recovery Controller routing control: https://docs.aws.amazon.com/r53recovery/latest/dg/routing-control.html
- Amazon S3 Object Lock: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html
- AWS Backup Vault Lock: https://docs.aws.amazon.com/aws-backup/latest/devguide/vault-lock.html
- Amazon Security Lake: https://docs.aws.amazon.com/security-lake/latest/userguide/what-is-security-lake.html
- AWS Audit Manager: https://docs.aws.amazon.com/audit-manager/latest/userguide/what-is.html
- Amazon Managed Service for Prometheus: https://docs.aws.amazon.com/prometheus/latest/userguide/what-is-Amazon-Managed-Service-Prometheus.html
- AWS Private CA: https://docs.aws.amazon.com/privateca/latest/userguide/PcaWelcome.html
- AWS Nitro Enclaves: https://docs.aws.amazon.com/enclaves/latest/user/nitro-enclave.html
- AWS CloudHSM: https://docs.aws.amazon.com/cloudhsm/latest/userguide/introduction.html
- AWS Transfer Family: https://docs.aws.amazon.com/transfer/latest/userguide/what-is-aws-transfer-family.html
- Amazon EventBridge: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-what-is.html
- Amazon SQS FIFO queues: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html
- Amazon MQ: https://docs.aws.amazon.com/amazon-mq/latest/developer-guide/welcome.html
- AWS WAF: https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html
- AWS Shield Advanced: https://docs.aws.amazon.com/waf/latest/developerguide/ddos-overview.html
