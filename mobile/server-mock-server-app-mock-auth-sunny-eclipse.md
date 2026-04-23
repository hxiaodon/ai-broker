# 交易链路集成测试计划（Mock Server 驱动）

## Context

交易模块安全加固（S-01~S-05）已完成客户端实现，但后端服务尚未开发完毕。为了在 server 端就绪前验证完整交易链路的客户端行为，需要：

1. 扩展 Mock Server，支持交易相关的所有端点（含安全协议端点）
2. 按照 auth/market 模块的三层测试模式，为交易模块实现完整集成测试

**目标**：在无真实后端的情况下，验证下单流程（bio challenge → biometric → nonce → HMAC 签名 → 提交）、撤单、WebSocket 认证、持仓/组合查询的端到端正确性。

---

## 需要新增的 Mock Server 端点

**文件**：`mobile/mock-server/trading.go`（新建）+ `mobile/mock-server/main.go`（注册路由）

### 安全协议端点（S-01/S-02/S-03）

| 方法 | 路径 | 行为 |
|------|------|------|
| POST | `/api/v1/auth/session-key` | 返回 `{key_id, hmac_secret, expires_at}`，30min TTL |
| GET | `/api/v1/trading/nonce` | 返回一次性 `{nonce, expires_at}`，60s TTL，Redis 用 in-memory map 模拟 |
| GET | `/api/v1/trading/bio-challenge` | 返回 `{challenge, expires_at}`，30s TTL，一次性 |

### 交易业务端点

| 方法 | 路径 | 行为 |
|------|------|------|
| POST | `/api/v1/orders` | 校验必要 header（X-Key-Id, X-Nonce, X-Signature, X-Biometric-Token, X-Bio-Challenge），返回 201 订单 |
| GET | `/api/v1/orders` | 返回订单列表（支持 status/market 过滤） |
| GET | `/api/v1/orders/:id` | 返回订单详情 + fills |
| DELETE | `/api/v1/orders/:id` | 校验 nonce，返回 202 |
| GET | `/api/v1/positions` | 返回持仓列表 |
| GET | `/api/v1/positions/:symbol` | 返回单只持仓 |
| GET | `/api/v1/portfolio/summary` | 返回组合概览 |

### WebSocket 端点（S-04）

- `ws://localhost:8080/ws/trading`
- 连接后 10s 内等待 `{"type":"auth", ...}` 消息
- 校验 token 非空 → 回复 `{"type":"auth.ok"}`
- 认证成功后每 3s 推送 `order.updated`、`portfolio.summary`

### Mock Server 策略扩展

在现有 5 种策略基础上，交易端点响应受策略影响：
- `normal`：正常返回，nonce/challenge 校验宽松（只检查非空）
- `error`：POST /orders 返回 503，session-key 返回 401

---

## 三层集成测试实现

### 层 1：State Management Tests
**文件**：`mobile/src/integration_test/trading/trading_state_management_test.dart`

**覆盖（无 Mock Server，无网络）**：
- T1：已认证用户可进入交易屏幕
- T2：`OrderSubmitState` 初始为 idle
- T3：`OrderSubmitState` 状态机转换（idle → awaitingBiometric → submitting → success/error）
- T4：`OrdersNotifier` 初始加载状态
- T5：`PortfolioSummaryProvider` 初始加载状态
- T6：`PositionsProvider` 初始加载状态

**实现方式**：override `tradingRepositoryProvider`、`sessionKeyServiceProvider`、`nonceServiceProvider`、`bioChallengeServiceProvider` 为 mock 实现，不发起真实 HTTP 请求。

### 层 2：API Integration Tests
**文件**：`mobile/src/integration_test/trading/trading_api_integration_test.dart`

**覆盖（需要 Mock Server，直接调 Dio，不启动 App）**：

**安全协议链路**：
- TA1：`POST /api/v1/auth/session-key` 返回合法 key_id + hmac_secret
- TA2：`GET /api/v1/trading/nonce` 返回一次性 nonce
- TA3：`GET /api/v1/trading/bio-challenge` 返回 challenge
- TA4：nonce 一次性验证（同一 nonce 第二次使用应被拒绝）

**下单链路**：
- TA5：完整下单流程（先拿 session-key + nonce + bio-challenge，再 POST /orders，验证所有安全 header 存在）
- TA6：缺少 X-Nonce header → 400
- TA7：缺少 X-Biometric-Token header → 400
- TA8：POST /orders 返回 201，包含 order_id

**撤单链路**：
- TA9：DELETE /orders/:id 返回 202
- TA10：撤单也需要 nonce（每次独立获取）

**查询链路**：
- TA11：GET /orders 返回列表
- TA12：GET /orders/:id 返回详情 + fills
- TA13：GET /positions 返回持仓
- TA14：GET /portfolio/summary 返回组合概览

**错误处理**：
- TA15：503 映射为 NetworkException（FIX 断线场景）
- TA16：403 映射为 BusinessException（风控拒绝）

### 层 3：E2E Tests
**文件**：`mobile/src/integration_test/trading/trading_e2e_app_test.dart`

**覆盖（需要 Mock Server + 模拟器，启动完整 App）**：

- Journey 1：已认证用户进入交易页 → 输入订单参数 → 滑动确认 → 生物识别（mock）→ 订单提交成功 → 显示 order_id
- Journey 2：下单失败（503）→ 显示错误提示 → 可重试
- Journey 3：撤单流程 → 订单列表刷新
- Journey 4：WebSocket 连接 → 收到 order.updated 推送 → UI 更新
- Journey 5：持仓页加载 → 显示 AAPL 持仓数据

---

## 关键实现细节

### Mock Server 中的安全校验策略

`normal` 策略下，Mock Server 对安全 header 的校验**宽松**（只检查非空，不验证 HMAC 签名），原因：
- 集成测试的目的是验证客户端**发送了正确的 header**，而非验证签名算法本身（签名算法已有单元测试覆盖）
- 避免 Mock Server 需要维护 session key 状态来做完整 HMAC 验证

校验规则：
```
POST /api/v1/orders 必须包含：
  X-Key-Id: 非空
  X-Nonce: 非空且未被使用过（in-memory set）
  X-Signature: 非空
  X-Biometric-Token: 非空
  X-Bio-Challenge: 非空
  X-Bio-Timestamp: 非空
  Idempotency-Key: 非空
```

### 测试中绕过生物识别

`OrderSubmitNotifier` 中生物识别通过 `local_auth` 触发，在集成测试中无法真实触发。

**方案**：在 E2E 测试中，通过 `ProviderScope` override `bioChallengeServiceProvider`，使 `fetchChallenge()` 返回固定值，并在 `OrderSubmitNotifier` 中增加一个 `biometricEnabled: false` 路径（已存在），直接跳过生物识别，传空 token。

API Integration Tests 直接调 Dio，不经过 `OrderSubmitNotifier`，手动构造所有 header。

### 内置测试数据

Mock Server 内置以下交易数据（`trading.go` 中定义）：
```go
// 预置订单
orders = [
  {order_id: "ord-001", symbol: "AAPL", status: "PENDING", ...},
  {order_id: "ord-002", symbol: "TSLA", status: "FILLED", ...},
]

// 预置持仓
positions = [
  {symbol: "AAPL", qty: 100, avg_cost: "150.25", ...},
  {symbol: "0700", qty: 200, avg_cost: "368.50", ...},
]
```

---

## 文件清单

### 新建文件

| 文件 | 说明 |
|------|------|
| `mobile/mock-server/trading.go` | 交易端点 handler（session-key, nonce, bio-challenge, orders, positions, portfolio, WS） |
| `mobile/src/integration_test/trading/trading_state_management_test.dart` | 层 1 测试 |
| `mobile/src/integration_test/trading/trading_api_integration_test.dart` | 层 2 测试 |
| `mobile/src/integration_test/trading/trading_e2e_app_test.dart` | 层 3 测试 |
| `mobile/src/integration_test/trading/README.md` | 测试文档 |

### 修改文件

| 文件 | 改动 |
|------|------|
| `mobile/mock-server/main.go` | 注册 trading.go 中的路由 |
| `mobile/src/integration_test/helpers/test_app.dart` | 新增 `createAppWithTrading()` 工厂方法，override 交易相关 provider |

---

## 验证方式

```bash
# 1. 启动 Mock Server（含交易端点）
cd mobile/mock-server && go run . --strategy=normal

# 2. 验证新端点可用
curl -X POST http://localhost:8080/api/v1/auth/session-key \
  -H "Authorization: Bearer test-token"
curl http://localhost:8080/api/v1/trading/nonce
curl http://localhost:8080/api/v1/trading/bio-challenge

# 3. 运行层 1（无需 Mock Server）
cd mobile/src
flutter test integration_test/trading/trading_state_management_test.dart

# 4. 运行层 2（需要 Mock Server）
flutter test integration_test/trading/trading_api_integration_test.dart

# 5. 运行层 3（需要 Mock Server + 模拟器）
flutter test integration_test/trading/trading_e2e_app_test.dart

# 6. 运行全部
flutter test integration_test/trading/
```

**预期结果**：
- 层 1：~6 个测试，< 30s，无网络依赖
- 层 2：~16 个测试，< 15s，需要 Mock Server
- 层 3：~5 个 Journey，< 30s，需要 Mock Server + 模拟器
