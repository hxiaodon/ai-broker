# 美港股券商交易系统 — AWS 云上金融服务基础设施架构设计

## Context

交易引擎计划部署到 AWS EKS，需要一套满足金融监管合规（SEC/FINRA + SFC/AMLO）的云基础设施架构。本文档覆盖多可用区/多地区部署、数据库高可用、服务链路优化、安全合规、灾备等核心维度，作为后续 IaC（Terraform/CDK）实现的架构蓝图。

本文档是**调研 + 设计讨论稿**，不涉及代码实现，产出为架构决策记录。

---

## 一、Region 策略：双 Region 分治

### 1.1 Region 选择

| Region | 用途 | 理由 |
|--------|------|------|
| **us-east-1** (N. Virginia) | 美股主站点 | NYSE/NASDAQ 数据中心在新泽西，距离最近；AWS Direct Connect 节点最密集 |
| **ap-east-1** (Hong Kong) | 港股主站点 | HKEX 数据中心在将军澳，本地 Direct Connect 接入点可用 |

### 1.2 Active-Active 还是 Active-Passive？

**推荐：按市场分治的 Active-Active（双活但职责分离）**

```
                    ┌─────────────────────────────────────────────┐
                    │              Route 53 (GeoDNS)              │
                    │  US 用户 → us-east-1  |  HK 用户 → ap-east-1│
                    └──────────┬──────────────────────┬───────────┘
                               │                      │
              ┌────────────────▼──────┐   ┌──────────▼────────────────┐
              │     us-east-1         │   │      ap-east-1            │
              │                       │   │                           │
              │  EKS Cluster (US)     │   │  EKS Cluster (HK)        │
              │  ├─ trading-core      │   │  ├─ trading-core          │
              │  ├─ trading-gateway   │   │  ├─ trading-gateway       │
              │  │   └─ NYSE pod      │   │  │   └─ HKEX pod         │
              │  │   └─ NASDAQ pod    │   │  │                        │
              │  ├─ trading-portfolio │   │  ├─ trading-portfolio     │
              │  └─ trading-settlement│   │  └─ trading-settlement   │
              │                       │   │                           │
              │  Aurora MySQL (写主)   │   │  Aurora MySQL (写主)      │
              │  ElastiCache Redis    │   │  ElastiCache Redis       │
              │  MSK (Kafka)          │   │  MSK (Kafka)             │
              └────────────┬──────────┘   └──────────┬────────────────┘
                           │     Aurora Global DB     │
                           │◄────── 跨 Region ──────►│
                           │    复制延迟 < 1 秒         │
                           │   MSK MirrorMaker 2      │
```

**核心决策**：
- 每个 Region 独立运行自己市场的完整交易栈，**不是**主备关系
- us-east-1 处理所有美股订单，ap-east-1 处理所有港股订单
- 两个 Region 通过 Aurora Global Database 共享用户账户和持仓数据（只读副本）
- 跨市场持仓汇总：从本地只读副本读取对方 Region 的持仓数据

**为什么不用单 Region？**
- FIX 协议对延迟极其敏感，跨太平洋的网络延迟 (~150ms RTT) 不可接受
- 港股监管（SFC）可能要求数据驻留在香港
- 单点故障风险过高

**灾备**：
- 如果 us-east-1 宕机，ap-east-1 可以接管美股交易（Aurora Global Database failover + 预配置的美股 FIX gateway）
- 反之亦然，但通常不会主动使用（延迟不理想）

---

## 二、EKS 集群设计

### 2.1 集群拓扑

**每个 Region 一个 EKS 集群**，不拆多集群。原因：
- 服务间通信在集群内完成，不跨集群边界
- 简化 RBAC、网络策略、服务发现
- 集群级别的资源配额和 LimitRange 足以隔离租户

### 2.2 Node Group 策略

```yaml
# 4 个专用 Node Group，按工作负载特征划分
nodeGroups:
  # 1. 交易核心 — 低延迟、高可用、固定规模
  trading-core-ng:
    instanceTypes: [c7g.xlarge]        # 4 vCPU, 8GB, Graviton3, 计算优化
    minSize: 3                         # 每个 AZ 至少 1 个
    maxSize: 9
    labels:
      workload-type: trading-core
    taints:
      - key: dedicated
        value: trading-core
        effect: NoSchedule
    placementGroup:
      strategy: cluster                # 同机架部署，最低延迟
    availabilityZones: [a, b, c]       # 跨 3 个 AZ

  # 2. 交易网关 — 有状态长连接、不自动扩缩
  trading-gateway-ng:
    instanceTypes: [m7g.large]         # 2 vCPU, 8GB, 内存够 FIX session
    minSize: 2                         # 至少 2 个节点（HA）
    maxSize: 4
    labels:
      workload-type: trading-gateway
    taints:
      - key: dedicated
        value: trading-gateway
        effect: NoSchedule
    # 不用 placement group — gateway 需要跨 AZ 容灾

  # 3. 组合计算 — 事件驱动、弹性扩缩
  trading-portfolio-ng:
    instanceTypes: [c7g.2xlarge]       # 8 vCPU, 16GB, P&L 计算密集
    minSize: 2
    maxSize: 8
    labels:
      workload-type: trading-portfolio

  # 4. 批处理 — 可中断、Spot 实例
  trading-batch-ng:
    instanceTypes: [m7g.large, m6g.large]  # 多种实例类型，提高 Spot 可用性
    capacityType: SPOT                     # Spot 实例节省 60-70% 成本
    minSize: 0
    maxSize: 4
    labels:
      workload-type: trading-batch
    taints:
      - key: dedicated
        value: trading-batch
        effect: NoSchedule
```

### 2.3 为什么选 Graviton (ARM)

| 维度 | Graviton3 (c7g) | x86 (c7i) |
|------|-----------------|-----------|
| Go 编译 | 原生支持 `GOARCH=arm64` | 默认 |
| 性价比 | **~20% 更优** | 基准 |
| 单核性能 | 接近 x86 | 略高 |
| 生态兼容 | Go + MySQL + Redis + Kafka 全兼容 | 全兼容 |

Go 是 ARM-friendly 的语言，交叉编译只需 `GOARCH=arm64`，所有依赖库（shopspring/decimal、quickfixgo/quickfix、segmentio/kafka-go）均支持 ARM。

### 2.4 Pod 拓扑与调度

```yaml
# trading-core Deployment
spec:
  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: DoNotSchedule    # 严格均匀分布
      labelSelector:
        matchLabels:
          app: trading-core
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: workload-type
                operator: In
                values: [trading-core]
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            topologyKey: kubernetes.io/hostname  # 不同节点
            labelSelector:
              matchLabels:
                app: trading-core
```

**trading-gateway 特殊处理**：
```yaml
# FIX Gateway — 不能被轻易驱逐
spec:
  terminationGracePeriodSeconds: 120      # 2 分钟优雅关闭 FIX session
  containers:
    - lifecycle:
        preStop:
          exec:
            command: ["/bin/sh", "-c", "kill -SIGTERM 1 && sleep 90"]  # FIX Logout
  # PDB: 市场交易时间内不允许驱逐
  podDisruptionBudget:
    maxUnavailable: 0                      # 交易时段零容忍
```

---

## 三、网络架构

### 3.1 VPC 设计

```
┌─────────────────────── VPC (10.0.0.0/16) ────────────────────────────┐
│                                                                       │
│  ┌─── Public Subnets (10.0.0.0/20 per AZ) ───┐                      │
│  │  ALB / NLB (API Gateway 入口)                │                      │
│  │  NAT Gateway (每 AZ 一个，避免跨 AZ 费用)      │                      │
│  └────────────────────────────────────────────┘                      │
│                                                                       │
│  ┌─── Private Subnets - App (10.0.64.0/18 per AZ) ───┐              │
│  │  EKS Worker Nodes (全部 Pod)                          │              │
│  │  trading-core / gateway / portfolio / settlement     │              │
│  └──────────────────────────────────────────────────────┘              │
│                                                                       │
│  ┌─── Private Subnets - Data (10.0.192.0/20 per AZ) ───┐            │
│  │  Aurora MySQL Endpoints                                 │            │
│  │  ElastiCache Redis Endpoints                            │            │
│  │  MSK Broker Endpoints                                   │            │
│  └─────────────────────────────────────────────────────────┘            │
│                                                                       │
│  ┌─── Private Subnets - Exchange (10.0.240.0/22) ───┐                │
│  │  Direct Connect 接入（到 NYSE/NASDAQ/HKEX）         │                │
│  │  FIX Gateway Pod 的出站流量通过这里                   │                │
│  └───────────────────────────────────────────────────┘                │
│                                                                       │
│  VPC Endpoints:                                                       │
│  ├─ Gateway: S3 (审计日志), DynamoDB                                   │
│  ├─ Interface: ECR, KMS, Secrets Manager, STS, CloudWatch Logs       │
│  └─ Interface: MSK Bootstrap (避免 NAT Gateway 费用)                   │
└───────────────────────────────────────────────────────────────────────┘
```

### 3.2 Direct Connect（交易所连接）

```
NYSE/NASDAQ (NJ)                           HKEX (将军澳)
     │                                          │
     │ Equinix NY4/NY5                          │ Equinix HK1
     │    ↓                                     │    ↓
     │ Direct Connect (10Gbps x 2 冗余)         │ Direct Connect (1Gbps x 2)
     │    ↓                                     │    ↓
  us-east-1 VPC                             ap-east-1 VPC
     │                                          │
  trading-gateway-nyse pod                   trading-gateway-hkex pod
  trading-gateway-nasdaq pod
```

**关键配置**：
- 冗余连接（2 条独立线路），故障自动切换
- BGP 路由 with BFD（Bidirectional Forwarding Detection）快速故障检测
- 延迟目标：Direct Connect < 1ms 单向（同城数据中心之间）
- 如果不需要超低延迟（< 5ms），可以先用 VPN over Internet 作为过渡方案

### 3.3 跨 AZ 流量优化

交易系统每天产生大量内部流量（订单事件、行情推送、持仓更新），跨 AZ 费用会很可观。

**策略**：

| 流量类型 | 优化方式 | 预期效果 |
|----------|---------|---------|
| Pod → Pod (gRPC) | `trafficDistribution: PreferClose` | 同 AZ 优先，减少 ~70% 跨 AZ |
| Pod → Aurora | 写入走 Writer（固定 AZ），读走本 AZ 的 Read Replica | 读流量零跨 AZ |
| Pod → Redis | 每 AZ 配 Read Replica，读走本 AZ | 读流量零跨 AZ |
| Pod → MSK | Kafka Rack Awareness，消费者优先读本 AZ broker | 消费流量减少 ~60% |
| ALB → Pod | IP 模式 Target Group（不经过 NodePort） | 零额外跨 AZ 跳转 |

```yaml
# Service 配置示例 — 同 AZ 优先路由
apiVersion: v1
kind: Service
metadata:
  name: trading-core
spec:
  trafficDistribution: PreferClose    # K8s 1.33+ GA
  selector:
    app: trading-core
  ports:
    - port: 9090
      protocol: TCP
```

---

## 四、数据层

### 4.1 Aurora MySQL

```
┌────────────────────────────────────────────────────┐
│              Aurora Global Database                  │
│                                                      │
│  us-east-1 (Primary Cluster)                        │
│  ├─ Writer Instance (db.r7g.2xlarge)                │
│  │   └─ 订单写入、事件追加、持仓更新                    │
│  ├─ Reader 1 (db.r7g.xlarge) — AZ-a                 │
│  ├─ Reader 2 (db.r7g.xlarge) — AZ-b                 │
│  └─ Reader 3 (db.r7g.xlarge) — AZ-c (CQRS 读路径)   │
│                                                      │
│  ap-east-1 (Secondary Cluster)                      │
│  ├─ Reader (只读, < 1s 延迟) — 可提升为 Writer         │
│  └─ 港股交易用本地 Primary Cluster（独立 Global DB）    │
│                                                      │
│  RDS Proxy (每个 Region 独立)                         │
│  ├─ 连接池：最大 100 连接/代理                         │
│  ├─ Pin 行为：事务中不切连接                            │
│  └─ IAM 认证：Pod Identity → RDS Proxy → Aurora       │
└────────────────────────────────────────────────────┘
```

**关键配置**：
- **存储加密**：Aurora 默认 AES-256 (KMS CMK)
- **自动备份**：35 天保留 + 按需快照（保留 7 年，满足 SEC 17a-4）
- **读写分离**：Writer endpoint 给 trading-core 写，Reader endpoint 给 portfolio 和 settlement 读
- **failover 优先级**：tier-0 给 AZ-a 的 Reader（最快提升为 Writer）
- **参数组**：`time_zone = '+00:00'`（强制 UTC）、`max_connections = 5000`

### 4.2 ElastiCache Redis

```yaml
# Redis Cluster Mode (Multi-AZ)
Engine: Redis 7.x
NodeType: cache.r7g.large
NumShards: 3                    # 3 个分片，覆盖 3 个 AZ
ReplicasPerShard: 1             # 每分片 1 个只读副本
AutomaticFailoverEnabled: true
MultiAZEnabled: true
TransitEncryptionEnabled: true  # TLS in-transit
AtRestEncryptionEnabled: true   # KMS at-rest

# 用途分区（通过 Key Prefix）
# idempotency:{key}  — 72h TTL，订单幂等
# bp:{account_id}    — 30s TTL，购买力缓存
# cb:{venue}         — Circuit Breaker 状态
# pos:{user}:{sym}   — 实时持仓缓存
# session:{token}    — Token 黑名单
```

### 4.3 Amazon MSK (Kafka)

```yaml
# MSK Cluster Configuration
BrokerNodeGroupInfo:
  InstanceType: kafka.m7g.large      # Graviton, 性价比
  ClientSubnets: [subnet-a, subnet-b, subnet-c]  # 3 AZ
  StorageInfo:
    EBSStorageInfo:
      VolumeSize: 500                # GB per broker
NumberOfBrokerNodes: 3               # 每 AZ 1 个 broker

# Topics 设计
Topics:
  - name: order.events
    partitions: 12                   # 按 account_id hash，保证同账户有序
    replication-factor: 3            # 跨 3 AZ 持久化
    config:
      retention.ms: 604800000        # 7 天（热数据）
      min.insync.replicas: 2         # 至少 2 个副本确认

  - name: execution.events
    partitions: 12
    replication-factor: 3
    config:
      retention.ms: 604800000

  - name: settlement.events
    partitions: 6                    # 批处理，不需要高并发
    replication-factor: 3

  - name: audit.events
    partitions: 12
    replication-factor: 3
    config:
      retention.ms: 2592000000       # 30 天（然后归档到 S3）
      cleanup.policy: delete
```

**Kafka → S3 归档**：MSK Connect (Kafka Connect) + S3 Sink Connector，将审计事件持久化到 S3 Object Lock bucket，满足 7 年保留。

---

## 五、服务链路通信 — 为什么不用 Service Mesh

### 5.1 核心问题：延迟预算

```
订单提交延迟预算：< 50ms (p99)

传统 Service Mesh (Istio sidecar) 路径：
  Client → Envoy(A) → trading-core → Envoy(A) → Envoy(B) → Market Data → Envoy(B)
                 ↑                        ↑          ↑                         ↑
              +2-3ms                   +2-3ms     +2-3ms                    +2-3ms
                              总额外开销：+8-12ms (p99 可能 +15-20ms)

  50ms 预算中 20ms 被 mesh 吃掉 = 不可接受
```

### 5.2 推荐方案：分层通信策略

| 通信路径 | 方案 | 理由 |
|----------|------|------|
| **trading-core ↔ market-data** | gRPC 直连 + K8s Service | 热路径，零额外开销 |
| **trading-core → trading-gateway** | gRPC 直连 + K8s Service | 热路径 |
| **trading-core → Kafka** | segmentio/kafka-go 直连 MSK | 异步事件，不经过 proxy |
| **trading-portfolio ← Kafka** | Consumer Group 直连 | 异步消费 |
| **任意服务 → Aurora/Redis** | 直连（通过 RDS Proxy） | 数据层，不适合 mesh |
| **外部 → API Gateway** | NLB + Envoy (独立 Gateway) | 入口层 TLS 终止 + 路由 |

### 5.3 mTLS 怎么做（不用 Mesh）

```
方案：cert-manager + SPIFFE

  cert-manager (集群级)
       │
       ▼
  签发 SPIFFE X.509 SVID 到每个 Pod（通过 CSI Volume）
       │
       ▼
  Go 服务启动时加载证书，gRPC 配置 TLS
       │
       ▼
  Pod 间通信强制 mTLS（双向证书验证）
```

- 零 sidecar 开销
- 证书自动轮换（cert-manager 管理）
- SPIFFE ID 格式：`spiffe://brokerage.internal/ns/{namespace}/sa/{service-account}`
- 在 Go gRPC server/client 中配置 TLS credentials

### 5.4 可观测性怎么做（不用 Mesh）

```
方案：OpenTelemetry (OTel) Collector as DaemonSet

  Go 服务 → OTel SDK (traces/metrics/logs)
       │
       ▼ (OTLP gRPC, 本机 localhost)
  OTel Collector DaemonSet (每个节点 1 个)
       │
       ├─→ Prometheus (metrics) → Grafana
       ├─→ Tempo / X-Ray (traces)
       └─→ Loki / CloudWatch Logs (logs)
```

- DaemonSet 模式：Pod 发到本机 Collector，不跨网络
- 比 sidecar 少 90% 的资源开销（一个 Collector 服务所有 Pod）
- Go OTel SDK 的 instrumentation 开销 < 0.1ms

---

## 六、安全架构

### 6.1 加密体系

```
┌─────────────────────────────────────────────────────────┐
│                    加密层次                                │
│                                                           │
│  Layer 1: 传输加密                                        │
│  ├─ 外部入口：TLS 1.3 (NLB/ALB 终止)                      │
│  ├─ Pod 间：mTLS (cert-manager + SPIFFE)                 │
│  ├─ Pod → Aurora：TLS (RDS 证书)                          │
│  ├─ Pod → Redis：TLS (ElastiCache in-transit)             │
│  └─ Pod → MSK：TLS (MSK TLS listeners)                   │
│                                                           │
│  Layer 2: 存储加密                                        │
│  ├─ Aurora：AES-256 (KMS CMK, 自动)                       │
│  ├─ Redis：AES-256 (KMS CMK, 自动)                        │
│  ├─ EBS/S3：AES-256 (KMS CMK, 自动)                       │
│  └─ EKS etcd：Envelope Encryption (KMS CMK, 2025 默认)   │
│                                                           │
│  Layer 3: 应用级加密（PII 字段）                            │
│  ├─ 方案：AWS KMS Envelope Encryption                     │
│  │   1. 调用 KMS GenerateDataKey → 获取 DEK                │
│  │   2. 用 DEK 做 AES-256-GCM 加密 PII 字段               │
│  │   3. 存储 encrypted_DEK + encrypted_data 到 DB          │
│  │   4. 读取时：KMS Decrypt(encrypted_DEK) → DEK → 解密    │
│  ├─ 加密字段：SSN, HKID, 银行账号, 护照号                   │
│  └─ DEK 缓存：本地缓存 5 分钟，减少 KMS API 调用            │
└─────────────────────────────────────────────────────────┘
```

### 6.2 Secrets 管理

```yaml
# 方案：AWS Secrets Manager + CSI Secret Store Driver

# 1. Secret 存储在 Secrets Manager
aws secretsmanager create-secret \
  --name trading-engine/aurora-credentials \
  --secret-string '{"username":"trading_app","password":"..."}'

# 2. EKS Pod 通过 CSI Volume 挂载
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: trading-secrets
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "trading-engine/aurora-credentials"
        objectType: "secretsmanager"
      - objectName: "trading-engine/kafka-credentials"
        objectType: "secretsmanager"

# 3. Pod 定义
volumes:
  - name: secrets
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: trading-secrets
```

**为什么不用 HashiCorp Vault？**
- Vault 功能强大但运维复杂（需要单独的 HA 集群）
- Secrets Manager 是全托管，与 EKS Pod Identity 原生集成
- 对于我们的规模（< 100 个 secret），Secrets Manager 足够
- 如果未来需要动态数据库凭证轮换，再考虑 Vault

### 6.3 网络隔离（PCI DSS 合规）

```yaml
# 默认拒绝所有流量
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: trading
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]

# 只允许 trading-core 访问 Aurora（6.3306 端口）
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: trading-core-to-aurora
  namespace: trading
spec:
  podSelector:
    matchLabels:
      app: trading-core
  policyTypes: [Egress]
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.192.0/20    # Data subnet
      ports:
        - port: 3306
          protocol: TCP
```

**Namespace 隔离**：
```
namespaces:
  ├─ trading          # 交易核心（CDE 级别）
  ├─ trading-batch    # 清算结算（CDE 级别）
  ├─ market-data      # 行情服务（非 CDE）
  ├─ monitoring       # Prometheus/Grafana（运维）
  └─ ingress          # API Gateway/NLB（DMZ）
```

### 6.4 SEC 17a-4 WORM 存储

```
审计事件生命周期：

  Go 服务 → Kafka (audit.events)
                   │
                   ▼
  MSK Connect → S3 Sink Connector
                   │
                   ▼
  S3 Bucket (Object Lock: Compliance Mode)
  ├─ Retention: 7 years (2557 days)
  ├─ 无法删除、无法覆盖（即使 AWS root 账户也不行）
  ├─ Versioning: Enabled (Object Lock 要求)
  └─ Lifecycle Rule:
       0-90 days:   S3 Standard
       90-365 days: S3 Standard-IA
       1-7 years:   S3 Glacier Deep Archive
```

**Cohasset Associates 评估**：AWS S3 Object Lock (Compliance Mode) 已被独立评估为满足 SEC Rule 17a-4(f) 的电子记录存储要求。

---

## 七、可观测性

### 7.1 监控栈

```
┌─────────────────────────────────────────────────┐
│                 可观测性三支柱                      │
│                                                   │
│  Metrics:                                        │
│  ├─ 采集：Prometheus (自托管 on EKS)               │
│  ├─ 存储：Amazon Managed Prometheus (AMP)          │
│  ├─ 展示：Grafana (Amazon Managed Grafana)         │
│  └─ 告警：Alertmanager → SNS → PagerDuty          │
│                                                   │
│  Logs:                                            │
│  ├─ 采集：Fluent Bit DaemonSet                     │
│  ├─ 热存储：CloudWatch Logs (90 天)                │
│  ├─ 冷存储：S3 (7 年, 合规要求)                     │
│  └─ 查询：CloudWatch Logs Insights                 │
│                                                   │
│  Traces:                                          │
│  ├─ 采集：OTel Collector DaemonSet                 │
│  ├─ 存储：AWS X-Ray 或 Grafana Tempo               │
│  └─ 关联：trace_id + order_id + user_id            │
└─────────────────────────────────────────────────┘
```

### 7.2 关键告警规则

| 告警 | 条件 | 严重级别 | 响应 |
|------|------|---------|------|
| 订单延迟超标 | p99 > 50ms 持续 5min | P1 Critical | 自动扩容 + oncall |
| FIX Session 断连 | 任何 venue 断连 | P1 Critical | 立即 oncall |
| 数据库连接池耗尽 | active_connections > 90% | P2 High | 扩容 RDS Proxy |
| Kafka 消费延迟 | consumer_lag > 10,000 | P2 High | 扩容 consumer |
| 清算对账差异 | mismatch_rate > 0.01% | P1 Critical | 暂停结算 + compliance |
| 审计日志写入失败 | 任何失败 | P1 Critical | 立即修复（合规要求） |

---

## 八、灾备策略

### 8.1 RTO/RPO 目标

| 组件 | RPO | RTO | 策略 |
|------|-----|-----|------|
| 订单数据 (Aurora) | < 1s | < 1 min | Aurora Global DB managed failover |
| 审计日志 (S3) | 0 (零丢失) | < 1 hour | S3 跨 Region 复制 |
| 事件流 (Kafka) | < 30s | < 15 min | MSK MirrorMaker 2 |
| Redis 缓存 | N/A (可重建) | < 5 min | 冷启动从 DB 重建 |
| EKS 集群状态 | N/A | < 30 min | GitOps (ArgoCD) 重新部署 |

### 8.2 灾备流程

```
正常状态：
  US 用户 → us-east-1 (Primary for US stocks)
  HK 用户 → ap-east-1 (Primary for HK stocks)

us-east-1 故障：
  1. Route 53 健康检查失败 (30s 检测)
  2. 自动 DNS failover → 所有流量到 ap-east-1
  3. Aurora Global Database: promote ap-east-1 Secondary → Primary (~1 min)
  4. ap-east-1 FIX gateway 接管美股连接（预配置但平时 standby）
  5. 延迟从 ~2ms 上升到 ~150ms（跨太平洋），但服务可用
  6. 人工确认后，宣布 DR 生效
  7. us-east-1 恢复后，反向切换（计划性维护窗口）

关键约束：
  - 市场交易时间（美股 9:30-16:00 ET）不做计划性切换
  - DR 切换需要自动 + 人工确认双重机制（避免误切换）
  - 每季度执行一次 DR 演练（监管要求）
```

---

## 九、成本优化

### 9.1 实例成本策略

| 工作负载 | 实例类型 | 付费模式 | 月估算/实例 |
|----------|---------|---------|-----------|
| trading-core (3 pods) | c7g.xlarge | Compute Savings Plan | ~$75/月 |
| trading-gateway (2 pods) | m7g.large | On-Demand (灵活) | ~$65/月 |
| trading-portfolio (2 pods) | c7g.2xlarge | Compute Savings Plan | ~$150/月 |
| trading-settlement (Spot) | m7g.large | Spot (~60% off) | ~$26/月 |

### 9.2 流量成本优化

| 优化项 | 措施 | 预期节省 |
|--------|------|---------|
| Pod 间跨 AZ | `trafficDistribution: PreferClose` | ~70% 跨 AZ 流量 |
| LB → Pod | IP 模式 Target Group | 100% (零 NodePort 跳转) |
| Pod → AWS 服务 | VPC Endpoints (Gateway 免费) | ~90% NAT Gateway 费用 |
| MSK 消费 | Rack Awareness | ~60% 跨 AZ 消费流量 |
| 审计日志存储 | S3 Lifecycle → Glacier | ~95% 长期存储成本 |
| ECR 镜像拉取 | VPC Endpoint + 镜像缓存 | ~100% NAT Gateway 费用 |

---

## 十、开放问题（需进一步讨论）

### Q1: 港股数据驻留要求
SFC 是否明确要求港股交易数据必须存储在香港 Region？如果是，ap-east-1 需要独立的 Aurora 集群而非 Global Database 的 Secondary。这会影响跨市场持仓汇总的实现方式。

### Q2: Direct Connect vs VPN 作为初始方案
Direct Connect 安装周期长（4-8 周）且费用高。Phase 1 是否可以先用 Site-to-Site VPN（延迟 ~5-15ms vs Direct Connect ~1ms）？还是 FIX 协议延迟要求必须从 Day 1 就用 Direct Connect？

### Q3: 自建 Prometheus 还是用 AMP
Amazon Managed Prometheus (AMP) 免运维但按指标样本计费。如果指标量大（10K+ 时间序列），成本可能高于自建。需要估算指标量后决定。

### Q4: 合规审计日志的实时查询需求
7 年的审计日志如果只存 S3 + Glacier，查询很慢。是否需要保留最近 30/90 天的日志在 CloudWatch Logs 或 OpenSearch 中供实时查询？这影响成本和架构。

### Q5: 交易服务拆分粒度
当前方案是 4 个 Deployment。是否需要进一步讨论 trading-core 是否应该拆成 OMS + Risk + SOR 三个独立服务？这取决于团队规模和独立部署的需求。

### Q6: EKS 版本管理和升级策略
EKS 版本支持周期 ~14 个月。金融系统升级需要充分测试。是否采用 Blue-Green 集群升级（新集群 + 流量切换）而非 In-place 升级？

---

## 参考资料

- [AWS Well-Architected Financial Services Industry Lens](https://docs.aws.amazon.com/wellarchitected/latest/financial-services-industry-lens/financial-services-industry-lens.html)
- [AWS SEC Rule 17a-4 Compliance](https://aws.amazon.com/compliance/secrule17a-4f/)
- [EKS Managed Node Groups with Placement Groups](https://aws.amazon.com/blogs/containers/leveraging-amazon-eks-managed-node-group-with-placement-group-for-low-latency-critical-applications/)
- [EKS Cross-AZ Cost Optimization](https://docs.aws.amazon.com/eks/latest/best-practices/cost-opt-networking.html)
- [Building PCI DSS-Compliant Architectures on EKS](https://aws.amazon.com/blogs/containers/building-pci-dss-compliant-architectures-on-amazon-eks/)
- [Multi-Region EKS + Aurora Global Database](https://aws.amazon.com/blogs/database/part-1-scale-applications-using-multi-region-amazon-eks-and-amazon-aurora-global-database/)
- [Low Latency Cloud-Native Exchanges on AWS](https://aws.amazon.com/blogs/industries/low-latency-cloud-native-exchanges/)
- [Tick-to-Trade Latency Optimization on AWS](https://aws.amazon.com/blogs/web3/optimize-tick-to-trade-latency-for-digital-assets-exchanges-and-trading-platforms-on-aws/)
- [Addressing Latency and Data Transfer Costs on EKS using Istio](https://aws.amazon.com/blogs/containers/addressing-latency-and-data-transfer-costs-on-eks-using-istio/)
- [EKS Envelope Encryption with KMS](https://docs.aws.amazon.com/eks/latest/userguide/envelope-encryption.html)
- [Amazon MSK Express Brokers](https://aws.amazon.com/blogs/big-data/simplifying-kafka-operations-with-amazon-msk-express-brokers/)
- [MSK Rack Awareness for Cross-AZ Optimization](https://aws.amazon.com/blogs/big-data/optimize-traffic-costs-of-amazon-msk-consumers-on-amazon-eks-with-rack-awareness/)
