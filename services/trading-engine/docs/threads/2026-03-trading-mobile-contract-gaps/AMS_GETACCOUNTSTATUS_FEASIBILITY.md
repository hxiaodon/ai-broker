# AMS GetAccountStatus 新字段可行性评估
## 4 个新字段的存在性、影响、实现计划

**版本**: 1.0
**生成日期**: 2026-03-30
**受众**: ams-engineer, trading-engineer, product-manager
**优先级**: P0（阻塞交易引擎风控系统）

---

## 1. 字段存在性检查表

| 字段 | 是否在 AMS 中存在 | 当前存储位置 | 存在形式 | 备注 |
|------|----------------|-----------|---------|------|
| `kyc_status` | ✅ 是 | `accounts.kyc_status` | ENUM/VARCHAR(20) | 在 account-financial-model.md §3、§8.1 中已定义，状态值：PENDING / VERIFIED / REJECTED（原）或 PENDING / APPROVED / REJECTED / SUSPENDED（新） |
| `kyc_tier` | ✅ 是 | `accounts.kyc_tier` | VARCHAR(20) 或 INT32 | 在 account-financial-model.md §8.1 中已定义，当前枚举值：BASIC / STANDARD / ENHANCED；需改为 1 / 2 枚举 |
| `account_type` | ✅ 是 | `accounts.trading_type` | VARCHAR(20) | 在 account-financial-model.md §2.2 中已定义，枚举值：CASH / MARGIN_REG_T / MARGIN_PORTFOLIO；需重新映射为 CASH / MARGIN |
| `is_restricted` | ⚠️ 部分存在 | 无单一字段，分散存储 | 组合判断 | 需要新增：当前分散在 `pdt_flagged` / `margin_call_active` / 隐含在状态机（SUSPENDED / UNDER_REVIEW） 中 |

**结论**：前 3 个字段**已存在**，仅需调整枚举值和 Protobuf 映射；`is_restricted` 需新建**派生字段或计算逻辑**。

---

## 2. 详细字段评估

### 2.1 `kyc_status`

**当前状态**：
```sql
accounts.kyc_status VARCHAR(20)
-- 当前枚举值：PENDING / VERIFIED / REJECTED
```

**需求映射**：
| 原值 | 新值 | 说明 |
|------|------|------|
| PENDING | PENDING | 账户正在 KYC 审核中 |
| VERIFIED | APPROVED | KYC 审核通过，可交易 |
| REJECTED | REJECTED | KYC 审核不通过 |
| —— | SUSPENDED | 新增：KYC 通过但被 AML 冻结 |

**实施影响**：
- ✅ **无数据迁移成本**：已存在，只需调整枚举值和 API 返回映射
- ✅ **无 DB Schema 变更**：字段类型保持 VARCHAR(20)
- ✅ **无向后兼容问题**：枚举值变更在 gRPC/REST 转换层处理
- 依赖：account_status（`SUSPENDED` / `UNDER_REVIEW` 状态） 和 AML 筛查结果需协调

**工作量**：**< 1 小时**
- 在 `GetAccountStatusResponse` Protobuf 中暴露
- 在 Go 服务逻辑中添加简单映射（原 VERIFIED → APPROVED）

---

### 2.2 `kyc_tier`

**当前状态**：
```sql
accounts.kyc_tier VARCHAR(20)
-- 当前枚举值：BASIC / STANDARD / ENHANCED
```

**需求映射**：
| 原值 | 新值 | 说明 | Trading Engine 用途 |
|------|------|------|-------------------|
| BASIC | 1 | 基础等级，购买力上限 $25K（示例） | BuyingPowerCheck 中乘以 1.0x 系数 |
| STANDARD | 2 | 标准等级，购买力无上限 | BuyingPowerCheck 中乘以 4.0x 系数 |
| ENHANCED | 1 或 2（待定） | 暂未定义 | 需产品澄清 |

**实施影响**：
- ⚠️ **需明确映射关系**：BASIC/STANDARD/ENHANCED 与 Trading Engine 的风控参数的对应关系
- ✅ **类型调整**：from VARCHAR(20) → int32（更高效）
- ✅ **无新增数据库字段**
- 依赖：Trading Engine 确认购买力系数和 KYC 等级的映射表

**工作量**：**1 - 2 小时**
- 在 Protobuf 中定义 enum KYCTier { TIER_UNKNOWN=0; TIER_1=1; TIER_2=2; }
- 在 Go 服务中添加枚举转换逻辑（BASIC→1, STANDARD→2）
- 单元测试枚举映射

---

### 2.3 `account_type`

**当前状态**：
```sql
accounts.trading_type VARCHAR(20)
-- 当前枚举值：CASH / MARGIN_REG_T / MARGIN_PORTFOLIO
```

**需求映射**：
| 原值 | 新值 | 说明 |
|------|------|------|
| CASH | CASH | 现金账户，不允许融资 |
| MARGIN_REG_T | MARGIN | Reg T 融资账户 |
| MARGIN_PORTFOLIO | MARGIN | 组合保证金账户 |

**实施影响**：
- ⚠️ **简化映射**：将 MARGIN_REG_T 和 MARGIN_PORTFOLIO 都映射为单一的 MARGIN（Trading Engine 暂不区分）
- ✅ **无新增字段**：Trading Engine 只关心 CASH vs MARGIN 的二元区分
- ⚠️ **未来扩展**：若 Phase 2 需要区分 MARGIN_REG_T vs MARGIN_PORTFOLIO 时，可在 Protobuf 中扩展枚举值

**工作量**：**< 1 小时**
- 在 Protobuf 中定义 enum AccountType { ACCOUNT_TYPE_UNKNOWN=0; CASH=1; MARGIN=2; }
- 在 Go 中简单映射（MARGIN_REG_T or MARGIN_PORTFOLIO → MARGIN）

---

### 2.4 `is_restricted` ⚠️ **新增，需特殊处理**

**当前状态**：
- 无单一 `is_restricted` 字段
- 分散存储在：
  - `accounts.pdt_flagged` (TINYINT(1))
  - `accounts.margin_call_active` (TINYINT(1))
  - 隐含在 `accounts.account_status` (SUSPENDED / UNDER_REVIEW)
  - 隐含在 AML 筛查状态（在 account_sanctions_screenings 表中）

**需求定义**：
```
is_restricted = true 当任何以下条件满足：
  1. account_status ∈ {SUSPENDED, UNDER_REVIEW, CLOSING}
  2. OR pdt_flagged = 1 AND account_equity < $25,000
  3. OR margin_call_active = 1
  4. OR 存在未解除的 AML 冻结（需从 account_sanctions_screenings 推导）
```

**可行性评估**：

**方案 A：数据库新增字段（推荐）**
```sql
ALTER TABLE accounts ADD COLUMN (
  is_restricted TINYINT(1) NOT NULL DEFAULT 0,
  restriction_reason VARCHAR(50),           -- PDT_FROZEN / AML_FROZEN / MARGIN_CALL / MANUAL_RESTRICTION
  restriction_until_timestamp BIGINT        -- Unix 秒数，0=无期限
);

CREATE INDEX idx_accounts_restricted (is_restricted)
WHERE is_restricted = 1;
```

**优点**：
- 直接字段查询，无需复杂计算，性能最优 ✅
- 支持 `restriction_reason` 和 `restriction_until_timestamp` 两个可选字段
- 与缓存策略配合良好（Redis 缓存 60s）

**缺点**：
- 需数据库迁移（创建字段+初始化历史记录）
- 需维护同步逻辑：当 pdt_flagged/margin_call_active/account_status 变更时，更新 is_restricted

**工作量**：**3 - 5 小时**

---

**方案 B：计算字段（API 层推导）**
```go
func (s *Server) GetAccountStatus(ctx context.Context, req *GetAccountStatusRequest) (*GetAccountStatusResponse, error) {
    account := s.db.GetAccount(req.AccountId)

    // 推导 is_restricted
    isRestricted := false
    restrictionReason := ""

    if account.AccountStatus == "SUSPENDED" || account.AccountStatus == "UNDER_REVIEW" {
        isRestricted = true
        restrictionReason = "ACCOUNT_SUSPENDED"
    }
    if account.PDTFlagged && account.Equity < 25000 {
        isRestricted = true
        restrictionReason = "PDT_FROZEN"
    }
    if account.MarginCallActive {
        isRestricted = true
        restrictionReason = "MARGIN_CALL"
    }
    // AML 冻结需查询 sanctions_screenings 表...（N+1 问题）

    return &GetAccountStatusResponse{
        AccountId: account.AccountId,
        KycStatus: mapKycStatus(account.KycStatus),
        IsRestricted: isRestricted,
        RestrictionReason: restrictionReason,
        ...
    }
}
```

**优点**：
- 无数据库迁移，立即部署
- 实时计算，确保与源数据一致

**缺点**：
- 需数据库多表联接（accounts + account_sanctions_screenings）
- 每次 GetAccountStatus 调用增加计算成本
- 难以优化（Trading Engine 缓存 60s，但每次缓存未命中仍需计算）

**工作量**：**2 - 3 小时**

---

**推荐方案**：**方案 A（新增数据库字段）**
理由：
- Trading Engine 会频繁查询（每次下单前）
- 虽然有 60s 缓存，但缓存未命中时性能重要
- `is_restricted` 的变更频率不高（只在 PDT 触发、margin call、AML 审核时变更）
- 与账户状态同步更新，易于维护

---

## 3. Protobuf 规范更新

### 新增 gRPC 服务方法（或扩展现有方法）

**假设**：AMS 已有 `AccountService`，Trading Engine 通过 gRPC 调用。

```protobuf
syntax = "proto3";

package ams.v1;

option go_package = "github.com/brokerage/services/ams/proto/v1;amsv1";

// ============================================================
// Enums
// ============================================================

enum KYCStatus {
  KYC_STATUS_UNKNOWN = 0;
  KYC_STATUS_PENDING = 1;      // 审核中
  KYC_STATUS_APPROVED = 2;     // 通过
  KYC_STATUS_REJECTED = 3;     // 拒绝
  KYC_STATUS_SUSPENDED = 4;    // 冻结（通过但被AML冻结）
}

enum KYCTier {
  KYC_TIER_UNKNOWN = 0;
  KYC_TIER_1 = 1;    // 基础等级
  KYC_TIER_2 = 2;    // 高级等级
}

enum AccountType {
  ACCOUNT_TYPE_UNKNOWN = 0;
  ACCOUNT_TYPE_CASH = 1;       // 现金账户
  ACCOUNT_TYPE_MARGIN = 2;     // 保证金账户
}

enum RestrictionReason {
  RESTRICTION_REASON_UNKNOWN = 0;
  RESTRICTION_REASON_PDT_FROZEN = 1;           // PDT 冻结
  RESTRICTION_REASON_AML_FROZEN = 2;           // AML 冻结
  RESTRICTION_REASON_MARGIN_CALL = 3;          // 保证金追缴未补
  RESTRICTION_REASON_MANUAL_RESTRICTION = 4;   // 人工限制
  RESTRICTION_REASON_ACCOUNT_SUSPENDED = 5;    // 账户暂停（一般性）
}

// ============================================================
// Request / Response
// ============================================================

message GetAccountStatusRequest {
  string account_id = 1;  // UUID 格式
}

message GetAccountStatusResponse {
  // ===== 现有字段 =====
  string account_id = 1;
  string account_name = 2;
  string status = 3;      // ACTIVE | SUSPENDED | CLOSED（保留现有名称）

  // ===== 新增字段（必需）=====

  // 4.1 KYC 状态
  KYCStatus kyc_status = 4;
  // Trading Engine 风控规则：
  //   仅当 kyc_status == KYC_STATUS_APPROVED 且 is_restricted == false 时允许交易

  // 4.2 KYC 等级（审核级别）
  KYCTier kyc_tier = 5;
  // Trading Engine 实施：在 BuyingPowerCheck 中读取，乘以不同购买力系数

  // 4.3 账户类型
  AccountType account_type = 6;
  // Trading Engine 实施：
  //   - PDTCheck 中，仅 ACCOUNT_TYPE_MARGIN 账户受 PDT 规则约束
  //   - BuyingPowerCheck 中，CASH 不允许融资

  // 4.4 账户限制标记
  bool is_restricted = 7;
  // Trading Engine 实施：若 true，拒绝订单

  // ===== 可选字段 =====

  // 4.5 限制原因
  RestrictionReason restriction_reason = 8;

  // 4.6 限制解除时间
  int64 restriction_until_timestamp = 9;
  // Unix 时间戳（秒），为 0 表示长期限制
}

// ============================================================
// Service
// ============================================================

service AccountService {
  rpc GetAccountStatus(GetAccountStatusRequest) returns (GetAccountStatusResponse);

  // 现有其他方法...
  // rpc ValidateAccount(ValidateAccountRequest) returns (ValidateAccountResponse);
  // rpc GetAccountSnapshot(GetAccountSnapshotRequest) returns (AccountSnapshot);
}
```

**Notes**：
- 使用 enum 而非 string，便于未来扩展和客户端类型检查
- 保留字段编号 1-7 未来可扩展（如添加更多字段）
- string status 字段保留现有名称，避免 API 破坏

---

## 4. 缓存策略建议

### 4.1 缓存架构（Trading Engine 侧）

```
Trading Engine
    │
    ├─ Redis Key: account:{account_id}:status
    │  ├─ Type: JSON String（存储 GetAccountStatusResponse 序列化）
    │  ├─ TTL: 60 秒
    │  └─ 更新时机：
    │      1. 缓存未命中时从 AMS gRPC 获取
    │      2. 订阅 Kafka 事件 account.status_changed 时主动刷新
    │
    └─ Kafka Topic: ams.account.status_changed
       ├─ Message: AccountStatusChangedEvent（见下文）
       ├─ Partition Key: account_id（同一账户事件有序）
       └─ 消费者：Trading Engine 的 Kafka Consumer
```

### 4.2 缓存的 TTL 合理性分析

**60 秒 TTL 的依据**：

| 风控检查 | 需求延迟 | 是否与 60s 匹配 | 说明 |
|---------|---------|----------------|------|
| AccountCheck（账户状态） | 秒级（下单时） | ✅ 匹配 | 账户状态变更（冻结、激活）通常异步发生，60s 延迟可接受 |
| BuyingPowerCheck | 秒级 | ✅ 匹配 | KYC 等级很少变更，60s 延迟可接受 |
| PDTCheck | 秒级 | ✅ 匹配 | PDT 标记由交易引擎自己维护，不依赖 AMS 实时更新 |
| PostTradeCheck | 秒级 | ✅ 匹配 | 限制标记通常来自 AMS 或交易引擎，60s 延迟可接受 |

**极端场景**：
- **场景**：用户账户被人工冻结（合规操作），用户随即下单
- **影响**：最坏延迟 60 秒后才生效
- **缓解**：AMS 发送 Kafka 事件立即刷新缓存（见 §4.3）

**结论**：**60 秒是合理的**。在可接受的延迟内，又能显著降低 AMS 的 QPS 压力。

---

### 4.3 缓存失效机制（事件驱动）

**AMS 应发布的 Kafka 事件**：

```protobuf
// Topic: ams.account.status_changed
message AccountStatusChangedEvent {
  string event_id = 1;                    // UUID，去重
  string account_id = 2;                  // 账户 ID

  // KYC 变更
  string kyc_status = 3;                  // PENDING / APPROVED / REJECTED / SUSPENDED
  string previous_kyc_status = 4;
  int32 kyc_tier = 5;

  // 账户类型和限制
  string account_type = 6;                // CASH / MARGIN
  bool is_restricted = 7;
  string restriction_reason = 8;          // PDT_FROZEN / AML_FROZEN / ...
  int64 restriction_until_timestamp = 9;

  // 审计信息
  int64 changed_at = 10;                  // Unix 纳秒
  string changed_by = 11;                 // 操作人 ID（system 或 user_id）
  string change_reason = 12;              // 变更原因代码
}
```

**Trading Engine 订阅逻辑**：

```go
// Consumer Group: trading-engine-account-status-sync
func (c *KafkaConsumer) ConsumAccountStatusChanged(ctx context.Context) error {
    for {
        msg := c.ReadMessage(ctx)

        event := &pb.AccountStatusChangedEvent{}
        proto.Unmarshal(msg.Value, event)

        // 刷新 Redis 缓存
        cacheKey := fmt.Sprintf("account:%s:status", event.AccountId)
        c.redis.Del(ctx, cacheKey)  // 删除缓存，强制下次查询重新获取

        // 可选：主动推送给移动端（WebSocket）
        c.wsHub.BroadcastAccountStatusChange(event.AccountId, event)
    }
}
```

**缓存失效时机**：
1. **立即**（AMS 发送 Kafka 事件）
   - KYC 状态审核通过 / 拒绝
   - 账户被冻结（人工或 AML）
   - PDT 标记触发
   - Margin Call 触发

2. **定期**（防止事件丢失）
   - Redis 自动 TTL 过期（60s）

---

## 5. 对 AMS 服务性能的影响评估

### 5.1 数据库性能影响

**场景**：Trading Engine 会在下单时调用 GetAccountStatus

**预期 QPS**：
- 平时：200-500 req/s（假设平均 20-50 个活跃下单请求/秒，每个可能查询 1 次）
- 尖峰（开盘）：500-1000 req/s
- 缓存命中率：预期 90%+（60s TTL）

**MySQL 查询成本**：

```sql
-- 现有查询
SELECT
  account_id, account_name, account_status,
  kyc_status, kyc_tier, trading_type
FROM accounts
WHERE account_id = ?;
-- 索引：PRIMARY KEY (id) + UNIQUE (account_id)
-- 预期延迟：< 1ms
```

**新增字段的成本**：
- 若采用**方案 A**（新增 is_restricted 字段）：**0ms 额外成本**（同一行查询）
- 若采用**方案 B**（计算推导）：可能 +5-20ms（需额外查询 account_sanctions_screenings）

**推荐**：采用**方案 A**（新增字段）

**结论**：**对 MySQL 的影响：可忽略不计**

---

### 5.2 gRPC 服务开销

**新增字段的 Protobuf 大小**：
- 原：~150 字节
- 新：+50-60 字节（4 个新字段 + 可选字段）
- 总：~200-210 字节

**序列化/反序列化成本**：< 1ms （Protobuf 3 优化良好）

**网络延迟**：不变（同一 RPC）

**结论**：**对 gRPC 的影响：完全可忽略**

---

### 5.3 Redis 缓存压力

**缓存大小估算**：
```
每个账户状态缓存大小 ≈ 200 字节（Protobuf 序列化）
假设 10 万活跃账户，同时有缓存
总内存 ≈ 200 字节 × 10 万 = 20 MB

Redis 内存典型配置 ≥ 1 GB，占用 << 1%
```

**缓存 QPS**：
- 读：500-1000 req/s（大多数都是缓存命中，Redis 性能 > 50K req/s）
- 写：10-50 req/s（Kafka 事件驱动的缓存刷新）

**结论**：**对 Redis 的影响：可忽略不计**

---

### 5.4 Kafka 消息流量

**每个账户状态变更事件**：
- 大小：~300 字节
- 频率：低（仅在 KYC/AML/PDT/Margin Call 等事件时）
- 预期 QPS：< 1 msg/s（所有账户聚合）

**结论**：**对 Kafka 的影响：可忽略不计**

---

### 5.5 综合结论

| 组件 | 影响 | 风险等级 |
|------|------|----------|
| MySQL | +0.5 字节/行，查询无额外开销 | 🟢 低 |
| gRPC | +50 字节/响应，序列化成本 < 1ms | 🟢 低 |
| Redis | +20 MB 内存（假设 10 万账户） | 🟢 低 |
| Kafka | < 1 msg/s（状态变更事件） | 🟢 低 |

**综合评估**：**对 AMS 服务性能影响可忽略不计**

---

## 6. 实现计划与工作量评估

### 6.1 任务分解

| 序号 | 任务 | 负责方 | 工作量 | 依赖 | 备注 |
|------|------|--------|--------|------|------|
| 1 | 需求确认：KYC 等级（BASIC/STANDARD/ENHANCED）与 Trading Engine 风控系数的映射关系 | Product Manager | 2h | — | 必做，否则无法验证 |
| 2 | 数据库迁移：accounts 表新增 is_restricted / restriction_reason / restriction_until_timestamp 列 | AMS Engineer | 3-5h | ✓1 | 使用 goose 迁移工具，含初始化脚本 |
| 3 | Protobuf 定义：GetAccountStatusResponse 新增 4 个枚举和字段 | AMS Engineer | 1h | ✓1 | 含 Go stubs 生成 |
| 4 | 业务逻辑：GetAccountStatus 方法实现（字段映射 + is_restricted 计算） | AMS Engineer | 2-3h | ✓2, ✓3 | 含单元测试 |
| 5 | Kafka 事件发布：account.status_changed 事件定义与发布逻辑 | AMS Engineer | 3h | ✓2 | 含 Dead Letter Queue 处理 |
| 6 | Trading Engine 适配：缓存层实现 + Kafka 消费逻辑 | Trading Engineer | 4-5h | ✓5 | 含集成测试 |
| 7 | 测试：端到端集成测试（AMS → Trading Engine 联调） | Both | 3h | ✓4, ✓6 | Mock、集成测试、性能测试 |
| 8 | 部署与灰度：10% → 50% → 100% 流量灰度 | DevOps + AMS | 2h | ✓7 | 含部署后监控 |

**总工作量**：
- AMS 侧：**12-16 小时** (tasks 1-5, 7)
- Trading Engine 侧：**7-8 小时** (tasks 6-7)
- 总计：**19-24 小时**（约 2.5 个工作日）

---

### 6.2 完整实现计划（时间线）

```
Day 1（第一天）
├─ 09:00-11:00  Kickoff + 需求确认（task 1）
├─ 11:00-15:00  DB 迁移设计 + 代码编写（task 2，含初始本地测试）
├─ 15:00-16:30  Protobuf 定义与生成（task 3）
└─ 16:30-17:00  日报汇总

Day 2（第二天）
├─ 09:00-12:00  GetAccountStatus 实现（task 4）
├─ 12:00-13:00  午餐
├─ 13:00-16:00  Kafka 事件发布逻辑（task 5）
├─ 16:00-17:00  AMS 单元测试 + 本地集成测试
└─ 17:00-17:30  日报汇总

Day 3（第三天）
├─ 09:00-12:00  Trading Engine 缓存层 + Kafka 消费（task 6）
├─ 12:00-13:00  午餐
├─ 13:00-15:00  端到端集成测试（task 7）
├─ 15:00-16:30  联调 + 性能测试
├─ 16:30-17:00  修复 bug
└─ 17:00-17:30  日报 + 灰度计划确认

Day 4（第四天，可选，预留）
├─ 09:00-11:00  部署准备 + staging 验证
├─ 11:00-12:00  监控告警配置
├─ 12:00-13:00  午餐
├─ 13:00-17:00  灰度部署（10% → 50% → 100%）+ 上线后监控
└─ 17:00-17:30  日报 + 回顾
```

**目标完成日期**：2026-04-02（本周三）

---

### 6.3 关键决策点

| 决策 | 选项 A | 选项 B | 推荐 | 理由 |
|------|--------|--------|------|------|
| is_restricted 实现方式 | 新增 DB 字段 | API 层计算推导 | A | 性能优先，查询成本降低 |
| KYC 等级枚举值 | BASIC/STANDARD/ENHANCED（字符串）| 1/2（数字）| 2 | 与风控系数更直观，更节省存储 |
| 缓存 TTL | 30s | 60s | 60s | 平衡实时性和 QPS 压力 |
| Kafka 事件分区 | 无（单分区） | account_id（多分区，有序）| 多分区 | 确保同一账户事件有序 |

---

## 7. 风险与缓解策略

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| **is_restricted 与 account_status 状态冗余** | 中 | 数据一致性 | 编写一致性校验脚本；Kafka 事件驱动同步；添加审计日志 |
| **Kafka 事件丢失导致缓存过期** | 低 | Trading Engine 收不到更新 | Redis TTL 60s 兜底；添加 Kafka DLQ + 告警；每日定时同步任务 |
| **KYC 等级映射错误** | 低 | 风控参数计算错误 | 需求阶段充分澄清；测试用例覆盖所有映射组合 |
| **缓存穿透（账户不存在）** | 低 | QPS 尖峰时 MySQL 压力 | 负缓存：缓存 NOT_FOUND 结果，TTL=300s |
| **联调延期** | 中 | 整体上线延期 | 充分准备 Mock、集成测试框架；预留 1 天缓冲时间 |

---

## 8. 验收标准

✅ **Functional Requirements**
- [ ] GetAccountStatus gRPC 方法返回所有 4 个新字段，格式符合 Protobuf 规范
- [ ] kyc_status 映射正确（PENDING/APPROVED/REJECTED/SUSPENDED）
- [ ] kyc_tier 返回 1 或 2（非字符串）
- [ ] account_type 返回 CASH 或 MARGIN（统一简化映射）
- [ ] is_restricted 逻辑准确（反映所有冻结场景）
- [ ] restriction_reason 和 restriction_until_timestamp 可选字段按需填充

✅ **Performance Requirements**
- [ ] GetAccountStatus P99 延迟 ≤ 5ms（含缓存和 DB 查询）
- [ ] Redis 缓存命中率 ≥ 90%
- [ ] Kafka 事件发布延迟 ≤ 1s
- [ ] 1000 req/s 压力测试，无错误

✅ **Integration Requirements**
- [ ] Trading Engine 成功消费 account.status_changed 事件
- [ ] Trading Engine 缓存层正确识别所有 4 个字段
- [ ] 风控检查（AccountCheck/BuyingPowerCheck/PDTCheck）正确使用新字段
- [ ] 端到端场景测试（e.g., 账户冻结 → 下单被拒）通过

✅ **Compliance & Audit**
- [ ] 所有状态变更写入审计日志（account_status_events）
- [ ] 数据库迁移脚本含初始化逻辑，无数据丢失
- [ ] Kafka 事件含完整审计信息（changed_at, changed_by）

---

## 9. 一句话结论与可行性等级

### 结论

**完全可行。前 3 个字段已在 AMS 中存在，仅需调整枚举映射；`is_restricted` 需新增单一 DB 字段，设计成本极低。整体实现 2.5 个工作日，无性能风险。建议立即启动，2026-04-02 前完成。**

### 可行性等级

🟢 **HIGH（绿灯）**

**理由**：
- 4 个字段中 3 个已存在（0 创新成本）
- 1 个新字段（is_restricted）是简单的派生字段，无复杂逻辑
- AMS 数据库设计完备，扩展空间充足
- 性能影响可忽略（< 1% 资源增长）
- 缓存策略成熟（Redis + Kafka 驱动失效）
- Trading Engine 无重大改造（纯消费方）

**完成时间**：2 - 2.5 个工作日（含测试）
**上线风险**：🟢 LOW（灰度 + 监控充分）

---

## 10. 后续行动

### 立即（今天）
1. Product Manager 确认 KYC 等级（BASIC/STANDARD/ENHANCED）与风控参数的映射关系
2. AMS Engineer 开始 task 1-3（DB 设计 + Protobuf 定义）
3. Trading Engineer 准备 Mock 框架和集成测试用例

### Week 1（本周）
1. AMS Engineer 完成 tasks 2-5（实现 + Kafka 事件）
2. Trading Engineer 完成 task 6（缓存层 + Kafka 消费）
3. Both 完成联调测试（task 7）

### Week 2（下周一前）
1. 灰度部署至 staging（10% 流量）
2. 性能和功能验证通过
3. 全量上线至生产

---

## 附录：现有数据库 Schema 参考

```sql
-- 现有字段（来自 account-financial-model.md §8.1）
CREATE TABLE accounts (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id          CHAR(36) UNIQUE NOT NULL,
    ...
    account_status      VARCHAR(20) NOT NULL DEFAULT 'APPLICATION_SUBMITTED',
    kyc_status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    kyc_tier            VARCHAR(20) NOT NULL DEFAULT 'BASIC',
    trading_type        VARCHAR(20) NOT NULL DEFAULT 'CASH',
    pdt_flagged         TINYINT(1) NOT NULL DEFAULT 0,
    margin_call_active  TINYINT(1) NOT NULL DEFAULT 0,
    ...
);

-- 新增字段（方案 A）
ALTER TABLE accounts ADD COLUMN (
    is_restricted TINYINT(1) NOT NULL DEFAULT 0 AFTER margin_call_active,
    restriction_reason VARCHAR(50) AFTER is_restricted,
    restriction_until_timestamp BIGINT UNSIGNED DEFAULT 0 AFTER restriction_reason
);

CREATE INDEX idx_accounts_restricted (is_restricted)
WHERE is_restricted = 1;
```

---

## 文档历史

| 版本 | 日期 | 作者 | 变更 |
|------|------|------|------|
| 1.0 | 2026-03-30 | AMS Engineer | 初始版本：4 字段存在性检查、可行性评估、实现计划、风险分析 |

