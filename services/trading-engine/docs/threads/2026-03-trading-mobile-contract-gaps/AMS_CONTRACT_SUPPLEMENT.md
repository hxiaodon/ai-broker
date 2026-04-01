# AMS-Trading 契约补充：GetAccountStatus 新字段定义

**版本**: 1.0
**生成日期**: 2026-03-30
**发起方**: trading-engineer
**涉及方**: ams-engineer, trading-engineer
**优先级**: P0 (阻塞 Trading Engine 风控系统)

---

## 摘要

Trading Engine 风控系统需要 AMS 在 `GetAccountStatus` 端点返回 4 个新字段，以支持以下风控检查：

| 风控检查 | 依赖字段 | 用途 |
|---------|---------|------|
| AccountCheck | `kyc_status` | 检查账户是否可交易 |
| BuyingPowerCheck | `kyc_tier` | 决定购买力额度 |
| PDTCheck | `account_type` | 确定是否受 PDT 规则约束 |
| PostTradeCheck | `is_restricted` | 账户是否被冻结 |

---

## 详细定义

### GetAccountStatus (gRPC)

**Protobuf 定义**:

```protobuf
service AMS {
  rpc GetAccountStatus(GetAccountStatusRequest) returns (GetAccountStatusResponse);
}

message GetAccountStatusRequest {
  string account_id = 1;  // UUID 格式
}

message GetAccountStatusResponse {
  // ===== 现有字段 =====
  string account_id = 1;
  string account_name = 2;
  string status = 3;  // ACTIVE | SUSPENDED | CLOSED

  // ===== 新增字段 (必需) =====

  // 4.1 KYC 状态
  string kyc_status = 4;
  // 枚举值: PENDING | APPROVED | REJECTED | SUSPENDED
  //
  // PENDING: 账户正在 KYC 审核中，暂不允许交易
  // APPROVED: KYC 审核通过，可以交易
  // REJECTED: KYC 审核不通过，账户关闭
  // SUSPENDED: KYC 审核通过但账户被 AML 冻结，暂停交易
  //
  // Trading Engine 风控规则:
  //   - 仅当 kyc_status == APPROVED 且 is_restricted == false 时允许交易
  //   - 其他状态拒绝订单，返回错误信息提示用户

  // 4.2 KYC 等级（审核级别）
  int32 kyc_tier = 5;
  // 取值范围: 1 | 2
  //
  // 美股规则 (Reg T):
  //   Tier 1: 基础等级
  //     - 初始保证金: 50%
  //     - 最大购买力: $25,000 (示例，由 Risk Engine 实际控制)
  //   Tier 2: 高级等级
  //     - 初始保证金: 50%
  //     - 最大购买力: 无限制 (由账户资金决定)
  //
  // 港股规则 (SFC):
  //   Tier 1: 基础等级
  //     - 保证金比例: 按标的分级，但有额度上限
  //     - 最大购买力: HK$500,000 (示例)
  //   Tier 2: 高级等级
  //     - 保证金比例: 按标的分级
  //     - 最大购买力: 无限制 (由账户资金决定)
  //
  // Trading Engine 实施:
  //   Risk Engine 在 BuyingPowerCheck 中读取 kyc_tier，
  //   乘以不同的购买力系数或比例限制。

  // 4.3 账户类型
  string account_type = 6;
  // 枚举值: CASH | MARGIN
  //
  // CASH: 现金账户
  //   - 不允许融资买入（保证金交易）
  //   - 不受 PDT (Pattern Day Trader) 规则约束
  //   - 卖出后资金需要 T+1 结算才能购买新股票（防 Free-Riding）
  //
  // MARGIN: 保证金账户
  //   - 允许融资买入（使用保证金杠杆）
  //   - 受 PDT 规则约束 (仅美股)
  //   - 需要维持保证金要求 (FINRA 25%)
  //
  // Trading Engine 实施:
  //   Risk Engine 在多个风控检查中使用 account_type:
  //   - PositionLimitCheck: MARGIN 允许融资，CASH 不允许
  //   - PDTCheck: 仅 MARGIN 账户执行 PDT 逻辑
  //   - MarginCheck: MARGIN 账户需满足保证金要求

  // 4.4 账户限制标记
  bool is_restricted = 7;
  // true: 账户受限
  // false: 账户正常
  //
  // 限制原因示例:
  //   - PDT 冻结: 美股保证金账户在 5 天内日内交易 4+ 次，且账户净值 < $25K
  //   - AML 冻结: 由 AMS → Fund Transfer 的 AML 筛查触发
  //   - Margin Call 未补缴: 账户保证金 < 维持保证金，且用户未在期限内补缴
  //   - 人工限制: 合规或风管人员手动冻结账户
  //
  // Trading Engine 实施:
  //   - AccountCheck: 若 is_restricted == true，拒绝订单
  //   - PDTCheck: 当 is_restricted == true 时，应用更严格的 PDT 规则
  //   - 返回给客户端的错误信息应指示账户受限原因（如果可能）

  // (可选) 4.5 限制原因描述
  string restriction_reason = 8;
  // 示例: "PDT_FROZEN" | "AML_FROZEN" | "MARGIN_CALL" | "MANUAL_RESTRICTION"
  // 用于客户端展示更友好的错误提示

  // (可选) 4.6 限制解除时间
  int64 restriction_until_timestamp = 9;
  // Unix 时间戳（秒）
  // 若为 0，表示长期限制或无期限
  // Trading Engine 可在此时间后自动解除限制（需要定时任务）
}
```

### GetAccountStatus (REST)

**OpenAPI 3.0 定义**:

```yaml
openapi: 3.0.0
paths:
  /api/v1/accounts/{account_id}/status:
    get:
      summary: 获取账户状态（含 KYC 和限制信息）
      parameters:
        - name: account_id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: 账户状态信息
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/GetAccountStatusResponse'
        '404':
          description: 账户不存在

components:
  schemas:
    GetAccountStatusResponse:
      type: object
      required:
        - account_id
        - status
        - kyc_status
        - kyc_tier
        - account_type
        - is_restricted
      properties:
        account_id:
          type: string
          format: uuid
          example: "f47ac10b-58cc-4372-a567-0e02b2c3d479"

        status:
          type: string
          enum: [ACTIVE, SUSPENDED, CLOSED]
          example: ACTIVE

        kyc_status:
          type: string
          enum: [PENDING, APPROVED, REJECTED, SUSPENDED]
          example: APPROVED
          description: |
            KYC 审核状态。
            - PENDING: 审核中，不允许交易
            - APPROVED: 审核通过，允许交易
            - REJECTED: 审核不通过，账户关闭
            - SUSPENDED: AML 冻结，暂停交易

        kyc_tier:
          type: integer
          enum: [1, 2]
          example: 2
          description: |
            KYC 等级，影响购买力和保证金比例。
            1 = 基础等级，2 = 高级等级

        account_type:
          type: string
          enum: [CASH, MARGIN]
          example: MARGIN
          description: |
            账户类型。
            - CASH: 现金账户，不允许融资
            - MARGIN: 保证金账户，允许融资

        is_restricted:
          type: boolean
          example: false
          description: |
            账户是否被限制。true = 受限，不允许交易。

        restriction_reason:
          type: string
          enum: [PDT_FROZEN, AML_FROZEN, MARGIN_CALL, MANUAL_RESTRICTION, null]
          example: null
          nullable: true
          description: 若 is_restricted = true，说明限制原因

        restriction_until_timestamp:
          type: integer
          format: int64
          example: null
          nullable: true
          description: 若 is_restricted = true，表示何时解除限制（Unix 时间戳秒）
```

---

## Trading Engine 缓存策略

为避免 POST /orders 性能衰退，Trading Engine 将缓存 GetAccountStatus 结果：

```go
// Trading Engine 代码示例
const ACCOUNT_STATUS_CACHE_TTL = 60 * time.Second

func (r *Risk) AccountCheck(ctx context.Context, ord *Order) *Result {
    accountID := ord.AccountID

    // 1. 尝试从 Redis 读取缓存
    cached := redis.Get(ctx, fmt.Sprintf("account:%s:status", accountID))
    if cached != nil {
        status := unmarshalAccountStatus(cached)
        return r.validateAccountStatus(status, ord)
    }

    // 2. 缓存未命中，调用 AMS gRPC
    status, err := r.amsClient.GetAccountStatus(ctx, &pb.GetAccountStatusRequest{
        AccountId: accountID,
    })
    if err != nil {
        return Reject("Failed to fetch account status")
    }

    // 3. 缓存到 Redis (TTL 60s)
    redis.SetEx(ctx, fmt.Sprintf("account:%s:status", accountID),
                marshalAccountStatus(status), ACCOUNT_STATUS_CACHE_TTL)

    // 4. 验证并返回
    return r.validateAccountStatus(status, ord)
}

func (r *Risk) validateAccountStatus(status *AccountStatus, ord *Order) *Result {
    // 检查 kyc_status
    if status.KycStatus != "APPROVED" {
        return Reject("KYC not approved")
    }

    // 检查是否被限制
    if status.IsRestricted {
        return Reject(fmt.Sprintf("Account restricted: %s", status.RestrictionReason))
    }

    return Approve()
}
```

### 缓存失效事件

当以下事件发生时，AMS 应主动推送 Kafka 事件，Trading Engine 订阅并刷新缓存：

```protobuf
// AMS → Kafka: account.status_changed
message AccountStatusChanged {
  string account_id = 1;
  string kyc_status = 2;       // 变更后的状态
  string previous_kyc_status = 3;
  int32 kyc_tier = 4;
  string account_type = 5;
  bool is_restricted = 6;
  string restriction_reason = 7;
  int64 changed_at = 8;        // Unix 时间戳
  string changed_by = 9;       // 操作人 ID
}
```

Trading Engine 订阅此事件后，立即刷新 Redis 缓存或移除缓存键，强制下次查询时重新获取。

---

## 实施时间表

| Phase | Task | Timeline | Owner |
|-------|------|----------|-------|
| 1 | 合规审核：确认新字段不违反隐私政策 | 1-2 days | compliance-team |
| 2 | 实施：AMS 数据库添加新字段 | 3-5 days | ams-engineer |
| 3 | 集成测试：与 Trading Engine 联调 | 2-3 days | ams-engineer + trading-engineer |
| 4 | 部署：灰度发布 10% 流量 | 1 day | devops + ams-engineer |
| 5 | 验证：性能和功能测试通过 | 1 day | qa-engineer |
| 6 | 全量发布 | 1 day | devops |

**目标完成日期**: 2026-04-15

---

## 后续步骤

1. **ams-engineer** 评估实施难度和时间成本
2. **trading-engineer** 准备联调测试用例
3. 周会中讨论实施计划
4. 签署合约补充附件

