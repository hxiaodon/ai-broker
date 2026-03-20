---
type: platform-standard
level: L3
scope: cross-domain
status: ACTIVE
created: 2026-03-20T22:00+08:00
maintainer: sdd-expert
applies_to:
  - services/ams
  - services/trading-engine
  - services/market-data
  - services/fund-transfer
  - services/admin-panel
  - mobile
---

# 测试策略规范（Testing Strategy）

> 本文档是平台级测试标准。所有 domain engineer 在实现功能时，必须遵循本规范编写测试。
>
> **核心原则**：Codex verify 是审查（Review），不是测试（Test）。一个功能可以通过全部 6 个 Phase 的 Codex verify 但实际零自动化测试——这在金融监管环境下不可接受。
>
> **适用范围**：所有新功能、功能重构、合规改造。Bug fix 至少需要补充回归测试。

---

## 总览：测试金字塔

```
                    ╱╲
                   ╱  ╲
                  ╱ E2E╲                    少量：关键业务流程端到端
                 ╱──────╲
                ╱ Contract╲                 中量：跨域接口契约验证
               ╱──────────╲
              ╱ Integration ╲               中量：数据库 + 缓存 + 消息队列
             ╱──────────────╲
            ╱   Unit Tests   ╲              大量：领域逻辑、VO、状态机
           ╱──────────────────╲
```

| 测试类型 | 目标 | 速度 | 数量 | 运行时机 |
|---------|------|------|------|---------|
| **Unit** | 领域逻辑、VO 不变量、状态转换、计算 | < 1ms/个 | 多 | 每次提交 |
| **Integration** | Repo 实现、DB 交互、缓存、事务 | < 500ms/个 | 中 | 每次提交 |
| **Contract** | 跨域 gRPC/Kafka 接口不被破坏 | < 200ms/个 | 中 | 每次提交 |
| **E2E** | 关键业务流程端到端（含多服务协作） | < 5s/个 | 少 | PR 合并前 / 日构建 |
| **Performance** | 吞吐量、延迟、并发安全 | 分钟级 | 少 | 每个 Sprint / 重大变更 |

---

## Phase 与测试类型的映射

| Phase | 产出代码层 | 必须的测试类型 | 重点 |
|-------|---------|-------------|------|
| **Phase 1** | DB Schema | Migration 验证 | goose up/down 可逆；字段类型合规 |
| **Phase 2** | Domain Layer | **Unit Tests** | VO 不变量、Entity 业务规则、状态机转换、Domain Service 计算 |
| **Phase 3** | Infrastructure Layer | **Integration Tests** | Repo 实现的 CRUD、ACL 转换、缓存一致性 |
| **Phase 4** | Application Layer | **Unit + Integration** | Usecase 编排逻辑、事务边界、Outbox 事件发布 |
| **Phase 5** | Transport Layer | **Contract Tests** | Proto 兼容性、Handler 输入校验、错误码映射 |
| **Phase 6** | 全栈 | **E2E + Performance** | 端到端流程、合规检查、性能验证 |

### Phase 2 测试要求（Domain Layer）

Domain Layer 是业务规则的核心，测试覆盖要求最严格：

```go
// 必须测试的场景

// 1. Value Object 构造校验
func TestMoney_NewMoney_RejectsNegative(t *testing.T) { ... }
func TestMoney_NewMoney_RejectsFloat(t *testing.T) { ... }
func TestMoney_Add_ReturnsNewInstance(t *testing.T) { ... }

// 2. 状态机转换（每个合法转换 + 每个非法转换）
func TestOrder_Submit_FromPending_Success(t *testing.T) { ... }
func TestOrder_Submit_FromFilled_ReturnsError(t *testing.T) { ... }
// ★ 状态机的测试用例必须覆盖 Tech Spec §2 Mermaid 图中的每条边

// 3. 业务规则 / 不变量
func TestOrder_PartialFill_UpdatesRemainingQty(t *testing.T) { ... }
func TestOrder_PartialFill_NeverExceedsTotalQty(t *testing.T) { ... }

// 4. Domain Service 计算
func TestBuyingPower_Calculate_ExcludesUnsettledProceeds(t *testing.T) { ... }
func TestBuyingPower_Calculate_UsesDecimalNotFloat(t *testing.T) { ... }
```

### Phase 3 测试要求（Infrastructure Layer）

```go
// 使用 testcontainers 或 dockertest 启动真实 MySQL/Redis

// 1. Repository CRUD
func TestOrderRepo_Save_And_FindByID(t *testing.T) { ... }
func TestOrderRepo_FindByID_NotFound_ReturnsDomainError(t *testing.T) { ... }

// 2. ACL 转换
func TestToEntity_ConvertsDecimalStringToDecimal(t *testing.T) { ... }
func TestToDAO_PreservesAllFields(t *testing.T) { ... }

// 3. 缓存一致性（如有 Redis Proxy）
func TestOrderCacheProxy_CacheHit_ReturnsCachedOrder(t *testing.T) { ... }
func TestOrderCacheProxy_CacheMiss_FallsToMySQL(t *testing.T) { ... }
func TestOrderCacheProxy_SaveInvalidatesCache(t *testing.T) { ... }
```

### Phase 4 测试要求（Application Layer）

```go
// 1. Usecase 编排（mock Repository + mock EventPublisher）
func TestPlaceOrderUsecase_HappyPath(t *testing.T) { ... }
func TestPlaceOrderUsecase_AccountSuspended_ReturnsError(t *testing.T) { ... }

// 2. 事务边界（Integration Test：真实 DB）
func TestPlaceOrderUsecase_OutboxAndOrderInSameTransaction(t *testing.T) { ... }
func TestPlaceOrderUsecase_DBFailure_BothRolledBack(t *testing.T) { ... }

// 3. 幂等性
func TestPlaceOrderUsecase_DuplicateIdempotencyKey_ReturnsCachedResult(t *testing.T) { ... }
```

### Phase 5 测试要求（Transport Layer）

```go
// 1. 输入校验
func TestPlaceOrderHandler_InvalidSymbol_Returns400(t *testing.T) { ... }
func TestPlaceOrderHandler_NegativeQty_Returns400(t *testing.T) { ... }

// 2. 错误码映射
func TestPlaceOrderHandler_DomainNotFound_Returns404(t *testing.T) { ... }
func TestPlaceOrderHandler_DomainValidation_Returns422(t *testing.T) { ... }

// 3. Proto 兼容性（Contract Test）
func TestProto_PlaceOrderRequest_BackwardCompatible(t *testing.T) {
    // buf breaking --against '.git#branch=main'
}
```

---

## 覆盖率要求

### 分层覆盖率目标

| 代码层 | 行覆盖率目标 | 分支覆盖率目标 | 强制级别 |
|-------|:---------:|:----------:|:------:|
| Domain Layer | ≥ 90% | ≥ 85% | **强制** |
| Application Layer | ≥ 80% | ≥ 75% | **强制** |
| Infrastructure Layer | ≥ 70% | ≥ 60% | 建议 |
| Transport Layer | ≥ 70% | ≥ 60% | 建议 |

### 金融关键路径强制 100% 分支覆盖

以下路径无论属于哪一层，分支覆盖率**必须 100%**：

| 关键路径 | 原因 | 涉及域 |
|---------|------|-------|
| 资金计算（余额、买入力、可提金额） | 一个分支遗漏 = 资金损失 | Trading, Fund |
| 状态机转换（订单、KYC、提现审批） | 一个非法转换 = 业务逻辑错误 | 全部 |
| AML 筛查决策 | 一个分支遗漏 = 合规违规 | Fund, AMS |
| 手续费/佣金计算 | 计算错误 = 用户投诉或公司损失 | Trading |
| 幂等性检查 | 遗漏 = 重复下单/重复出金 | Trading, Fund |
| PII 加密/解密 | 遗漏 = 数据泄露 | AMS, Fund |

```go
// 示例：AML 筛查决策必须覆盖所有分支
func TestAMLScreening_OFAC_Match_BlocksTransfer(t *testing.T) { ... }
func TestAMLScreening_OFAC_NoMatch_Passes(t *testing.T) { ... }
func TestAMLScreening_AMLO_Match_BlocksTransfer(t *testing.T) { ... }
func TestAMLScreening_AMLO_NoMatch_Passes(t *testing.T) { ... }
func TestAMLScreening_CTR_AboveThreshold_AutoFiles(t *testing.T) { ... }
func TestAMLScreening_CTR_BelowThreshold_NoFiling(t *testing.T) { ... }
func TestAMLScreening_Structuring_MultipleTransactions_Flags(t *testing.T) { ... }
func TestAMLScreening_Structuring_LegitMultiple_NofFlag(t *testing.T) { ... }
func TestAMLScreening_Timeout_MarksReview_NotApprove(t *testing.T) { ... }
```

---

## Spec-Test 可追溯性

### 为什么需要追溯

审计师会问："PRD 说'提现金额超过 $50,000 需要人工审批'——这条规则有测试覆盖吗？"

如果无法快速回答，就是合规缺口。

### 追溯格式

在测试文件中使用 `// Spec:` 标记关联 Tech Spec 的具体章节：

```go
// Spec: docs/specs/withdrawal-workflow.md §5.2 — 提现审批规则
// Rule: 金额 > $50,000 USD → 人工审批
func TestWithdrawalApproval_Above50K_RequiresManualReview(t *testing.T) {
    withdrawal := NewWithdrawal(Money("60000", "USD"), userID)
    result := approvalService.Evaluate(withdrawal)
    assert.Equal(t, ApprovalRequired, result.Decision)
    assert.Equal(t, "AMOUNT_EXCEEDS_AUTO_LIMIT", result.Reason)
}

// Spec: docs/specs/withdrawal-workflow.md §5.2 — 提现审批规则
// Rule: 金额 ≤ $50,000 USD + 无 AML 标记 + 银行账户验证 > 3 天 → 自动批准
func TestWithdrawalApproval_Below50K_NoFlags_AutoApproves(t *testing.T) {
    // ...
}
```

**规则**：
- `// Spec:` 指向 Tech Spec 文件路径 + 章节号
- `// Rule:` 用自然语言描述被测试的业务规则
- 同一业务规则的所有测试用例共享相同的 `// Spec:` 标记
- 金融关键路径的每条业务规则**必须**有至少一个测试用例带 `// Spec:` 标记

### 覆盖度检查

在 Spec Freshness Audit 中增加测试覆盖度维度：

```
对于 Tech Spec §2 状态机中的每条转换边：
  → 是否有 // Spec: 指向该转换的测试用例？

对于 Tech Spec §5 中的每条业务规则：
  → 是否有 // Spec: 指向该规则的测试用例？

对于 Tech Spec §7 中的每个合规要求：
  → 是否有 // Spec: 指向该要求的测试用例？
```

---

## 契约测试（Contract Testing）

### 为什么需要契约测试

在微服务架构中，服务 A 更新了 proto 但不知道服务 B 依赖那个字段 → 服务 B 运行时崩溃。

`docs/contracts/` 定义了接口契约，契约测试确保代码实现不违反契约。

### 两种契约测试

| 类型 | 目标 | 实现方式 | 运行时机 |
|------|------|---------|---------|
| **Provider 测试** | 我发布的接口是否符合契约 | 测试 proto 的 RPC 方法签名和返回格式 | 每次提交 |
| **Consumer 测试** | 我调用的接口是否仍然可用 | Mock server 模拟上游响应，验证解析不报错 | 每次提交 |

### Proto 兼容性检查（必须）

```bash
# 在 CI 中强制运行
cd api && buf breaking --against '.git#branch=main'
```

任何 breaking change 必须：
1. 在 `docs/contracts/` 中记录迁移计划
2. 设定 deprecated 日期和下线日期
3. 通知所有 consumer 域

### Kafka 消息契约测试

```go
// 验证发布的事件格式符合 events.proto 定义
func TestOrderPlacedEvent_ConformsToProto(t *testing.T) {
    event := domain.NewOrderPlacedEvent(order)
    envelope := outbox.NewEventEnvelope(event)

    // 验证必填字段
    assert.NotEmpty(t, envelope.EventID)
    assert.NotEmpty(t, envelope.EventType)
    assert.NotEmpty(t, envelope.CorrelationID)
    assert.True(t, envelope.Timestamp.Before(time.Now()))

    // 验证可序列化为 proto
    _, err := proto.Marshal(envelope.ToProto())
    assert.NoError(t, err)
}
```

---

## 性能测试要求

### 何时执行

| 触发条件 | 测试范围 |
|---------|---------|
| 涉及数据库查询变更 | 查询响应时间 benchmark |
| 涉及并发处理逻辑 | 并发安全 + 吞吐量 |
| 涉及缓存策略变更 | 缓存命中率 + 降级表现 |
| Phase 6 集成验收 | 关键路径端到端延迟 |
| 重大版本发布前 | 全量压测 |

### 性能基线

| 场景 | 目标 | 来源 |
|------|------|------|
| 下单接口 P99 | < 200ms | trading-to-mobile contract |
| 行情推送延迟 P99 | < 500ms | market-data-system.md |
| KYC 提交 P99 | < 1s | 用户体验要求 |
| 提现请求 P99 | < 500ms | fund-transfer-system.md |
| 账户验证 P99 | < 10ms | ams-to-trading contract |

### Go Benchmark 规范

```go
// 放在 _test.go 文件中，命名为 Benchmark 前缀
func BenchmarkPlaceOrder_SingleUser(b *testing.B) {
    // setup...
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _, err := usecase.PlaceOrder(ctx, cmd)
        require.NoError(b, err)
    }
}

func BenchmarkPlaceOrder_Concurrent100(b *testing.B) {
    b.SetParallelism(100)
    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            _, err := usecase.PlaceOrder(ctx, cmd)
            require.NoError(b, err)
        }
    })
}
```

---

## 测试文件组织

### Go 服务

```
services/{domain}/src/
├── internal/
│   ├── domain/order/
│   │   ├── aggregate.go
│   │   ├── aggregate_test.go          # Unit tests（同目录）
│   │   └── aggregate_bench_test.go    # Benchmarks
│   ├── infra/mysql/
│   │   ├── order_repo.go
│   │   └── order_repo_test.go         # Integration tests（testcontainers）
│   ├── app/
│   │   ├── place_order_usecase.go
│   │   └── place_order_usecase_test.go
│   └── server/
│       ├── order_handler.go
│       └── order_handler_test.go
├── tests/
│   ├── e2e/                           # 端到端测试
│   │   └── order_flow_test.go
│   ├── contract/                      # 契约测试
│   │   └── trading_proto_test.go
│   └── fixtures/                      # 测试数据
│       ├── orders.json
│       └── testdata.go
```

### Flutter / Dart

```
mobile/src/
├── lib/
│   └── features/trading/
│       ├── domain/
│       │   └── order_model.dart
│       └── presentation/
│           └── order_screen.dart
├── test/
│   ├── unit/                          # 纯逻辑测试
│   │   └── trading/
│   │       └── order_model_test.dart
│   ├── widget/                        # Widget 测试
│   │   └── trading/
│   │       └── order_screen_test.dart
│   └── integration/                   # 集成测试
│       └── order_flow_test.dart
```

### Admin Panel (React/TypeScript)

```
services/admin-panel/src/
├── components/
│   └── KYCReview/
│       ├── KYCReviewTable.tsx
│       └── KYCReviewTable.test.tsx     # 同目录
├── hooks/
│   └── useWithdrawalQueue.ts
│   └── useWithdrawalQueue.test.ts
└── __tests__/
    └── e2e/                            # E2E（Playwright / Cypress）
        └── kyc-review-flow.test.ts
```

---

## 测试数据规范

### 金融测试数据的特殊要求

```go
// ✅ CORRECT: 使用明确的 decimal 字符串
testOrder := Order{
    Price:    decimal.RequireFromString("150.2500"),
    Quantity: decimal.RequireFromString("100"),
    Amount:   decimal.RequireFromString("15025.0000"),
}

// ❌ WRONG: 使用 float literal
testOrder := Order{
    Price:    150.25,
    Quantity: 100.0,
}
```

### 测试凭证

- 使用显而易见的假数据：`test-api-key-not-real`、`000-00-0000`（SSN）
- 测试数据库使用独立 schema 或 testcontainers（不共享开发数据库）
- 测试中的 PII 数据必须是虚构的，不得使用真实用户数据

### Fixture 管理

- 公共 fixture 放在 `tests/fixtures/`
- 使用 `testdata.go` 或 `factory.go` 封装测试数据构造
- 不在测试代码中硬编码大段 JSON — 使用 `testdata/` 目录下的文件

---

## Phase 验收 Checklist 中的测试要求

以下内容补充到 `feature-development-workflow.md` 各 Phase 的 self-verify checklist：

### Phase 2 追加

```
[ ] Domain Layer 行覆盖率 ≥ 90%，分支覆盖率 ≥ 85%
[ ] Tech Spec §2 状态机的每条转换边都有对应测试（含非法转换）
[ ] 金融计算路径分支覆盖率 100%
[ ] 所有测试使用 decimal 不使用 float
```

### Phase 3 追加

```
[ ] Integration Tests 使用真实数据库（testcontainers / dockertest）
[ ] FindByXxx 的 Not Found 返回 domain error 有测试
[ ] ACL 转换函数（ToEntity / ToDAO）的字段完整性有测试
```

### Phase 4 追加

```
[ ] Usecase 编排的 happy path + 每个 error path 有测试
[ ] 事务边界测试：业务写入 + Outbox 同成功/同失败
[ ] 幂等性测试：重复 Idempotency-Key 返回缓存结果
```

### Phase 5 追加

```
[ ] buf breaking 检查通过（无 breaking change）
[ ] Handler 输入校验的每个拒绝条件有测试
[ ] 错误码映射：每个 domain error → gRPC status code 有测试
```

### Phase 6 追加

```
[ ] 关键业务路径 E2E 测试通过
[ ] 性能基线满足 contract SLA 要求
[ ] Spec-Test 追溯：Tech Spec §2、§5、§7 中的每条规则至少有一个 // Spec: 标记的测试
[ ] 测试覆盖率报告已生成并满足分层目标
```

---

## 参考文档

| 文档 | 路径 | 关联 |
|------|------|------|
| 功能开发工作流 | `docs/specs/platform/feature-development-workflow.md` | Phase 验收 checklist |
| DDD 战术模式 | `docs/specs/platform/ddd-patterns.md` | Domain Layer 测试模式 |
| Kafka 拓扑规范 | `docs/specs/platform/kafka-topology.md` | 事件契约测试 |
| API 契约规范 | `docs/specs/platform/api-contracts.md` | Proto 兼容性测试 |
| Financial Coding Standards | `.claude/rules/financial-coding-standards.md` | 金额精度测试 |
| Security & Compliance Rules | `.claude/rules/security-compliance.md` | PII / 审计测试 |
| Fund Transfer Compliance | `.claude/rules/fund-transfer-compliance.md` | AML 路径测试 |
