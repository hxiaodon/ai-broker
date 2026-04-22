# Trading Module — Integration Tests

## 概述

交易模块集成测试覆盖完整的交易链路，包括安全协议（S-01~S-04）、下单/撤单、持仓查询和 WebSocket 认证。

## 三层测试分类

| 层级 | 文件 | 依赖 | 速度 |
|------|------|------|------|
| **State Management** | `trading_state_management_test.dart` | 无（全 stub） | ~30s |
| **API Integration** | `trading_api_integration_test.dart` | Mock Server | ~15s |
| **E2E** | `trading_e2e_app_test.dart` | Mock Server + 模拟器 | ~30s |

## 运行方式

### 前置条件

```bash
# 启动 Mock Server（含交易端点）
cd mobile/mock-server
go run . --strategy=normal
```

### 层 1 — State Management（无需 Mock Server）

```bash
cd mobile/src
flutter test integration_test/trading/trading_state_management_test.dart
```

**覆盖**：
- T1: 已认证用户可进入交易屏幕
- T2: `OrderSubmitState` 初始为 idle
- T3: 下单成功 → idle → submitting → success
- T4: `reset()` 返回 idle
- T5: 仓库抛出异常 → error 状态
- T6: `OrdersNotifier` 加载订单列表
- T7: `PositionsNotifier` 加载持仓列表
- T8: `PortfolioSummaryNotifier` 加载组合概览

### 层 2 — API Integration（需要 Mock Server）

```bash
cd mobile/src
flutter test integration_test/trading/trading_api_integration_test.dart
```

**覆盖**：
- TA1: `POST /api/v1/auth/session-key` 返回 key_id + hmac_secret
- TA2: `GET /api/v1/trading/nonce` 返回一次性 nonce
- TA3: `GET /api/v1/trading/bio-challenge` 返回 challenge
- TA4: 同一 nonce 第二次使用被拒绝（400 NONCE_ALREADY_USED）
- TA5: 完整下单（含所有安全 header）→ 201
- TA6: 缺少 X-Nonce → 400 MISSING_HEADER
- TA7: 缺少生物识别 header（非 biometric 流程）→ 201（生物识别可选）
- TA8: 市价单（无 limit_price）→ 201
- TA8b: 市价单 2s 后自动 PENDING → FILLED（含 filled_qty / avg_fill_price / fills）
- TA8c: 限价单保持 PENDING 不自动成交
- TA9: 撤单 → 202
- TA10: 撤单缺少 nonce → 400
- TA11: 订单列表查询
- TA12: 订单详情 + fills
- TA13: 持仓列表
- TA14: 组合概览（含 cumulative_pnl 等字段）
- TA15: 状态过滤查询
- TA16: 单只持仓查询

### 层 3 — E2E（需要 Mock Server + 模拟器）

```bash
cd mobile/src
flutter test integration_test/trading/trading_e2e_app_test.dart
```

**覆盖**：
- Journey 1: 已认证用户进入 App
- Journey 2: OrderEntryScreen 渲染
- Journey 3: 下单（biometric disabled）→ success 状态
- Journey 4: OrderListScreen 从 Mock Server 加载
- Journey 5: 错误处理（graceful degradation）

### 运行全部

```bash
flutter test integration_test/trading/
```

## Mock Server 安全校验规则

`normal` 策略下，Mock Server 对安全 header 的校验规则：

| Header | 校验方式 |
|--------|---------|
| `X-Key-Id` | 非空检查 |
| `X-Nonce` | 非空 + 一次性（in-memory set） |
| `X-Signature` | 非空检查（不验证 HMAC 值） |
| `X-Biometric-Token` | 非空检查 |
| `X-Bio-Challenge` | 非空检查 |
| `X-Bio-Timestamp` | 非空检查 |
| `Idempotency-Key` | 非空检查 |

> HMAC 签名算法的正确性由 `test/core/security/hmac_signer_test.dart` 单元测试覆盖。

## 内置测试数据

Mock Server 预置以下数据：

**订单**：
- `ord-001`: AAPL BUY 100 LIMIT FILLED
- `ord-002`: TSLA BUY 50 LIMIT PENDING

**订单生命周期（Mock Server 模拟）**：
- 市价单：提交时 PENDING，2s 后自动切换为 FILLED（`filled_qty` = 提交量，`avg_fill_price` 取 `baseQuotes[symbol].price`，fallback "100.00"）
- 限价单：保持 PENDING，直到被显式撤单

**持仓**：
- AAPL: qty=100, avg_cost=150.25, market=US
- 0700: qty=200, avg_cost=350.00, market=HK

**组合**：
- total_equity: 96282.20
- buying_power: 10064.40
- cumulative_pnl: 7425.50
