# Portfolio Module — QA & Security Findings

**Review Date:** 2026-04-24  
**Reviewers:** QA Engineer Agent, Security Engineer Agent  
**Scope:** Flutter portfolio feature, three-tier integration tests, mock server  
**Status:** Open — not yet triaged or assigned

---

## Security Findings

### CRITICAL — CVSS 9.1

#### SEC-C1: SSL Certificate Pinning Completely Ineffective
**File:** `src/lib/core/security/ssl_pinning_config.dart` lines 44–57, 72–76, 108–113

Four compounding defects:
- `badCertificateCallback` is only invoked for invalid certs — never fires for CA-signed MitM proxy certs (Burp/Charles)
- `_spkiPins` contains placeholder `'PLACEHOLDER_PRIMARY_SPKI_PIN_BASE64=='` — if callback did fire, all connections would be rejected
- `_computeSpkiPin` hashes full DER cert, not SPKI bytes — survives no key rotation
- `minTlsVersion` is declared but never applied to `HttpClient`

**Impact:** Attacker with user-installed CA can intercept all traffic — JWT tokens, HMAC signatures, position data, order submissions.  
**Compliance violation:** `security-compliance.md` §Certificate Pinning  
**Fix:** Replace `badCertificateCallback` with `SecurityContext`-based pinning; replace placeholder pins; enforce `client.minProtocol = 'TLSv1.2'`.

---

### HIGH — CVSS 7.5

#### SEC-H1: Screen Capture Protection Not Applied to Portfolio Screens
**Files:**
- `src/lib/features/portfolio/presentation/screens/portfolio_screen.dart`
- `src/lib/features/portfolio/presentation/screens/position_detail_screen.dart`
- `src/lib/features/portfolio/presentation/screens/portfolio_analysis_screen.dart`

`ScreenProtectionMixin` exists and is fully implemented but applied to zero screens. Screens expose: total equity, cumulative P&L, unrealized P&L per position, realized P&L, cost basis, shares held, available-to-sell quantity. Visible in iOS App Switcher, Android Recents, `adb screencap`, accessibility screen readers.

**Compliance violation:** `security-compliance.md` §Anti-Tampering  
**Fix:** Apply `ScreenProtectionMixin` to `_PortfolioScreenState`; convert `PositionDetailScreen` and `PortfolioAnalysisScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` to enable the mixin.

#### SEC-H2: Portfolio Read Endpoints Missing HMAC Request Signing
**Files:**
- `src/lib/features/portfolio/data/remote/portfolio_remote_data_source.dart` lines 20–30
- `src/lib/features/trading/data/remote/trading_remote_data_source.dart` — `getPositions` line 180, `getPortfolioSummary` line 205

`submitOrder` and `cancelOrder` correctly use `HmacSigner.buildHeaders()`. Portfolio GET endpoints (`GET /api/v1/positions/$symbol`, `GET /api/v1/positions`, `GET /api/v1/portfolio/summary`) have no signature — inconsistent with the trading endpoint standard. Also missing `X-Timestamp` header, so replayed responses cannot be detected as stale.

**Compliance violation:** `security-compliance.md` §Request Signing  
**Fix:** Add HMAC headers to all three portfolio GET endpoints; align with backend contract on enforcement scope.

---

### MEDIUM — CVSS 5.3

#### SEC-M1: Financial Position Data Logged Unmasked in Debug Builds
**Files:**
- `src/lib/core/logging/log_interceptor.dart` lines 20–29 (`_sensitiveFields`)
- `src/lib/core/logging/app_logger.dart` lines 88–96 (`_ProductionFilter`)

`_maskBody` only redacts 8 PII fields (password, ssn, hkid, etc.). Portfolio API responses log verbatim: `market_value`, `unrealized_pnl`, `unrealized_pnl_pct`, `today_pnl`, `today_pnl_pct`, `realized_pnl`, `cost_basis`, `avg_cost`, `quantity`, `settled_qty`, `total_equity`, `cash_balance`, `buying_power`, `cumulative_pnl`. Suppressed in release builds only — risk in debug/CI/crash reporting SDKs.

**Compliance violation:** `security-compliance.md` §Logging Rules  
**Fix:** Add financial field names to `_sensitiveFields` in `log_interceptor.dart`.

#### SEC-M2: `portfolioRepositoryProvider` keepAlive — Financial Data Persists After Logout
**Files:**
- `src/lib/features/portfolio/data/portfolio_repository_impl.dart` line 24 (`@Riverpod(keepAlive: true)`)
- `src/lib/features/trading/application/trading_ws_notifier.dart` line 41 (`@Riverpod(keepAlive: true)`)
- `src/lib/features/auth/application/auth_notifier.dart` `logout()` lines 156–168

`logout()` clears tokens but does not invalidate `tradingWsProvider` or `portfolioRepositoryProvider`. WS remains connected and continues receiving position updates for the previous user's account. On shared devices: User B could see User A's real-time position data until the WS reconnects.

**Compliance violation:** `security-compliance.md` §Local Storage: "Clear cached trading data on logout."  
**Fix:** Add `ref.invalidate(tradingWsProvider)` and `ref.invalidate(portfolioRepositoryProvider)` in both `logout()` and `handleRemoteKick()`.

#### SEC-M3: `symbol` Path Parameter Not Validated Before URL Construction
**File:** `src/lib/features/portfolio/data/remote/portfolio_remote_data_source.dart` line 24

`'/api/v1/positions/$symbol'` — symbol flows directly from GoRouter route parameter without validation. Path traversal (`AAPL/../orders`) or query injection (`AAPL?admin=true`) possible depending on server routing.

**Compliance violation:** `financial-coding-standards.md` Rule 7: "Validate symbol format."  
**Fix:** Add regex guard: US `^[A-Z]{1,5}$`, HK `^\d{4,5}$`; throw `ValidationException` on mismatch.

---

### LOW — CVSS 3.7

#### SEC-L1: `handleRemoteKick()` Does Not Close WebSocket
**File:** `src/lib/features/auth/application/auth_notifier.dart` lines 172–176

`handleRemoteKick()` calls `tokenService.clearTokens()` but does not call `ref.invalidate(tradingWsProvider)`. WS stays open until 5 reconnect attempts exhaust. Inconsistency with `logout()` path.

**Fix:** Add `ref.invalidate(tradingWsProvider)` to `handleRemoteKick()`.

---

## QA Findings

### CRITICAL

#### QA-CRIT-01: Unguarded `Decimal.parse()` — App Crash on Malformed API Response
**File:** `src/lib/features/portfolio/data/remote/portfolio_mappers.dart` lines 14–38

Every financial field uses bare `Decimal.parse()` with no error handling. `null`, empty string, `"N/A"`, or non-numeric values from the server throw uncaught `FormatException`. The `DioException` handler in `portfolio_remote_data_source.dart` does not catch `FormatException`. Affects: `price`, `amount`, `fee`, `avgCost`, `currentPrice`, `marketValue`, `unrealizedPnl`, `unrealizedPnlPct`, `todayPnl`, `todayPnlPct`, `realizedPnl`, `costBasis`.

**Fix:** Replace `Decimal.parse(x)` with `Decimal.tryParse(x) ?? Decimal.zero` (or throw typed `ServerException`) inside try/catch in the mapper.

#### QA-CRIT-02: `TradeSide` Defaults to `sell` on Unknown Value
**File:** `src/lib/features/portfolio/data/remote/portfolio_mappers.dart` line 12

```dart
side: side.toUpperCase() == 'BUY' ? TradeSide.buy : TradeSide.sell,
```

Any value other than `"BUY"` silently maps to `TradeSide.sell` — including `"buy"`, `"B"`, `"LONG"`, or upstream data errors. Produces wrong cost-basis display and misleads users about trade history.

**Fix:**
```dart
side: switch (side.toUpperCase()) {
  'BUY' => TradeSide.buy,
  'SELL' => TradeSide.sell,
  _ => throw FormatException('Unknown trade side: $side'),
},
```

#### QA-CRIT-03: 5xx Server Error Maps to `NetworkException`
**File:** `src/lib/features/portfolio/data/remote/portfolio_remote_data_source.dart` lines 48–54

`_mapDioError` handles 4xx explicitly but has no branch for `statusCode >= 500`. 500/503 falls through to `NetworkException`, preventing differentiation of server failures from connectivity issues.

**Fix:** Add explicit `statusCode >= 500` branch returning `ServerException` with the status code.

---

### HIGH

#### QA-HIGH-01: `sectorAllocationProvider` All-or-Nothing Failure
**File:** `src/lib/features/portfolio/application/sector_allocation_provider.dart` lines 17–19

```dart
final details = await Future.wait(
  positions.map((p) => ref.watch(positionDetailProvider(p.symbol).future)),
);
```

`Future.wait` fails fast — one failed position detail empties the entire analysis tab.

**Fix:** Use `Future.wait` with individual try/catch wrappers, or `eagerError: false` + filter errors.

#### QA-HIGH-02: Race Condition Between REST and WS Overlay in `positionDetailProvider`
**File:** `src/lib/features/portfolio/application/position_detail_provider.dart` lines 12–16

Two sequential `ref.watch` awaits: if `positionsProvider` receives a WS update between them, the provider restarts from scratch triggering a redundant REST call. Under rapid WS updates this cascades.

**Fix:** Separate REST load from WS overlay; cache REST result with short TTL; apply WS as synchronous transform.

#### QA-HIGH-03: No Pull-to-Refresh and No Retry Button on Error State
**File:** `src/lib/features/portfolio/presentation/screens/portfolio_screen.dart`

`_PositionsTab` has no `RefreshIndicator`. `_ErrorView` shows "加载失败，请重试" with no interactive retry element. Same problem in `PositionDetailScreen` error state (lines 39–58). Users have no recovery path on error without killing the app.

**Fix:** Wrap scrollable content in `RefreshIndicator`; add retry button calling `ref.invalidate(positionsProvider)`.

#### QA-HIGH-04: Portfolio Weight Denominator Excludes Cash — False Concentration Warnings
**File:** `src/lib/features/portfolio/presentation/screens/portfolio_screen.dart` lines 122–177

`portfolioWeight = pos.marketValue / totalMv` excludes cash from denominator. User with $90k stock + $90k cash sees a "100% concentrated" warning even though the position is only 50% of total equity.

**Fix:** Use total equity (including cash) as the denominator for concentration calculations.

#### QA-HIGH-05: Unguarded `DateTime.parse` — Crash on Unexpected Timestamp Format
**File:** `src/lib/features/portfolio/data/remote/portfolio_mappers.dart` lines 17, 43

`DateTime.parse(executedAt).toUtc()` and `DateTime.parse(s.settleDate).toUtc()` are unguarded. Format changes (unix epoch, milliseconds, date-only) cause unhandled `FormatException`.

**Fix:** Wrap in try/catch; throw typed `ServerException` on parse failure.

---

### MEDIUM

#### QA-MED-01: `toDouble()` in UI Layer — Should Be Annotated
**File:** `src/lib/features/portfolio/presentation/widgets/sector_allocation_bar.dart` line 63

`value: allocation.weight.toDouble()` — unavoidable for `LinearProgressIndicator.value` but lacks a comment explaining why this display-layer `double` cast is acceptable.

#### QA-MED-02: Mock Server P&L Rounding Not Tied to Defined Rounding Rule
**File:** `mock-server/trading.go` lines 145–149

`unrealizedPnlPct` values in mock are manually rounded (`"16.81"` vs calculated `"16.8053"`) with no enforced rounding mode. No test asserts which rounding rule is applied.

#### QA-MED-03: `portfolioRepositoryProvider` keepAlive — Memory Leak on Logout
*(Also SEC-M2 — see security section)*

#### QA-MED-04: Settlement Date Displayed in UTC, Not Local Timezone
**File:** `src/lib/features/portfolio/presentation/screens/position_detail_screen.dart` lines 452–455

`_formatDate` accesses `.year`, `.month`, `.day` on UTC `DateTime`. For UTC-5 users, a settlement date of `2026-04-25T01:00:00Z` displays as `2026-04-25` when the user's local date is `2026-04-24` — one day off.

**Fix:** Convert to local time before formatting: `d.toLocal()`.

#### QA-MED-05: Trade Execution Time Has Same UTC/Local Issue
**File:** `src/lib/features/portfolio/presentation/screens/position_detail_screen.dart` lines 467–469

Same root cause as MED-04 for trade execution timestamps.

#### QA-MED-06: Portfolio Summary Test Only Validates 4 of 9 Required Fields
**File:** `src/integration_test/portfolio/portfolio_api_integration_test.dart` lines 140–165

`TPA6` validates `total_equity`, `cash_balance`, `buying_power`, `day_pnl` only. Unchecked: `total_market_value`, `day_pnl_pct`, `cumulative_pnl`, `cumulative_pnl_pct`, `unsettled_cash`. A mock server field rename would not be caught.

#### QA-MED-07: TP7 Test Has Incorrect Expected Weight Value
**File:** `src/integration_test/portfolio/portfolio_state_management_test.dart` line 220

`closeTo(0.192, 0.01)` — actual value is `0.192329`. Wide tolerance hides the incorrect comment and expected value.

#### QA-MED-08: Mock Server Never Pushes `position.updated` WS Messages
**File:** `mock-server/trading.go` lines 679–690

Only `portfolio.summary` is pushed every 3 seconds. The `position.updated` WS channel is never exercised via the mock server — only via manual injection in state management tests.

---

### LOW

#### QA-LOW-01: Error View — No Error Type Differentiation in Message
`NetworkException`, `AuthException`, `ServerException` all show "加载失败，请重试".

#### QA-LOW-02: Portfolio Color Hardcoded to `greenUp` Regardless of P&L Direction
**File:** `src/lib/features/portfolio/presentation/screens/portfolio_screen.dart` line 32

#### QA-LOW-03: Settlement Info Dialog Hardcodes T+1, Ignores HK T+2
**File:** `src/lib/features/portfolio/presentation/widgets/asset_summary_card.dart` lines 227–230

#### QA-LOW-04: `pnlRankingProvider` Unstable Sort on Equal Values
**File:** `src/lib/features/portfolio/application/pnl_ranking_provider.dart` lines 14–16

No secondary sort key — equal `unrealizedPnl` values may flicker on WS updates.

#### QA-LOW-05: Sell Button Pre-fills `availableQty` Without Validating Against `qty`
**File:** `src/lib/features/portfolio/presentation/screens/position_detail_screen.dart` lines 244–250

Server data corruption with `availableQty > qty` would pre-fill an order form with excessive quantity.

#### QA-LOW-06: Mock Server Error Strategy Doesn't Apply to Portfolio Detail Endpoint
**File:** `mock-server/trading.go` lines 575–594

`GET /api/v1/positions/AAPL` always returns 200 regardless of active strategy. Cannot test portfolio error path through strategy switching.

---

## Missing Test Cases

### State Management (`portfolio_state_management_test.dart`)

| ID | Scenario |
|----|----------|
| TP-MISS-01 | `positionDetailProvider` when `positionsProvider` returns empty list (REST-only path) |
| TP-MISS-02 | `sectorAllocationProvider` when one position detail fails — partial failure graceful degradation |
| TP-MISS-03 | `positionDetailProvider` with `availableQty > qty` — data corruption invariant |
| TP-MISS-04 | `pnlRankingProvider` with equal `unrealizedPnl` values — stable sort |
| TP-MISS-05 | `sectorAllocationProvider` with all-negative market values |
| TP-MISS-06 | `portfolioRepositoryProvider` disposal after logout — no stale token in Dio |

### API Integration (`portfolio_api_integration_test.dart`)

| ID | Scenario |
|----|----------|
| TPA-MISS-01 | `GET /api/v1/portfolio/summary` validates all 9 required fields parseable |
| TPA-MISS-02 | `GET /api/v1/positions/AAPL` verifies `unrealizedPnl == (currentPrice - avgCost) * qty` |
| TPA-MISS-03 | `GET /api/v1/positions/AAPL` with `--strategy=error` returns 5xx, repo throws `ServerException` |
| TPA-MISS-04 | `GET /api/v1/positions/AAPL` with `--strategy=unstable` — verifies retry behavior |
| TPA-MISS-05 | WS `/ws/trading` — verify `position.updated` channel message schema |
| TPA-MISS-06 | `GET /api/v1/positions/AAPL` with `wash_sale_status: "flagged"` |

### E2E (`portfolio_e2e_app_test.dart`)

| ID | Scenario |
|----|----------|
| E2E-MISS-01 | Empty portfolio — `EmptyPortfolioWidget` renders |
| E2E-MISS-02 | Cash-only portfolio — `CashOnlyPortfolioWidget` with correct balance |
| E2E-MISS-03 | Error state with no retry button visible — regression guard for QA-HIGH-03 |
| E2E-MISS-04 | Sort mode change — positions reorder correctly |
| E2E-MISS-05 | Concentration warning banner renders when position weight > 30% |
| E2E-MISS-06 | `PositionDetailScreen` with wash sale flag — warning card visible |
| E2E-MISS-07 | `PositionDetailScreen` with pending settlements — correct T+1/T+2 dates |

---

## Priority Fix Order

| Priority | Issue | Reason |
|----------|-------|--------|
| 1 | SEC-C1 (SSL Pinning) | All transport security controls depend on this |
| 2 | QA-CRIT-01 (Decimal.parse crash) | Any backend incident crashes all users |
| 3 | SEC-H1 (Screen Protection) | Financial data visible in screenshots |
| 4 | QA-CRIT-02 (TradeSide silent error) | Financial correctness bug |
| 5 | SEC-M2 (Logout WS not closed) | Cross-user data leak on shared devices |
| 6 | QA-HIGH-01 (Future.wait all-or-nothing) | Analysis tab unusable on any single failure |
| 7 | QA-HIGH-03 (No retry button) | Users stranded on error with no recovery |
