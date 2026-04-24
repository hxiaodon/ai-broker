# Portfolio Integration Tests

Three-tier test suite for the Portfolio module following the [INTEGRATION_TEST_GUIDE](../../../docs/INTEGRATION_TEST_GUIDE.md) standard.

## Test Files

| File | Type | Tests | Dependencies | Speed |
|------|------|-------|--------------|-------|
| `portfolio_state_management_test.dart` | State Management | TP1–TP12 | None | ~30s |
| `portfolio_api_integration_test.dart` | API Integration | TPA1–TPA9 | Mock Server | ~15s |
| `portfolio_e2e_app_test.dart` | E2E | Journey 1–5 | Mock Server + Emulator | ~30s |

## Running Tests

```bash
# State management — no Mock Server needed
flutter test integration_test/portfolio/portfolio_state_management_test.dart

# API integration — requires Mock Server
cd ../mock-server && go run . --strategy=normal &
flutter test integration_test/portfolio/portfolio_api_integration_test.dart

# E2E — requires Mock Server + emulator
flutter test integration_test/portfolio/portfolio_e2e_app_test.dart

# Full portfolio suite
flutter test integration_test/portfolio/
```

## What's Tested

### State Management (TP1–TP12)
- **TP1** App States: Authenticated user can access portfolio tab
- **TP2–TP3** Provider Loading: `positionsProvider` and `portfolioSummaryProvider` load data
- **TP4** `positionDetailProvider(AAPL)` returns correct entity (companyName, sector, washSaleFlagged, recentTrades)
- **TP5** WS overlay: `positionDetailProvider` merges real-time `currentPrice` from `positionsProvider`
- **TP6** P&L ranking sorted descending by unrealizedPnl
- **TP7** Sector allocation: AAPL (Technology) + 0700 (Communication Services) weights sum to 1.0
- **TP8** Single-position sector weight = 1.0 exactly
- **TP9–TP10** WS Position Updates: known symbol patches in-place, unknown symbol appends to list
- **TP11–TP12** Empty portfolio states: no-positions/no-cash, cash-only

### API Integration (TPA1–TPA9)
- **TPA1** `GET /api/v1/positions` — array with >= 2 entries
- **TPA2** `GET /api/v1/positions/AAPL` — `company_name`, `sector`, decimal fields
- **TPA3** `GET /api/v1/positions/AAPL` — `recent_trades` array with correct schema
- **TPA4** `GET /api/v1/positions/AAPL` — `wash_sale_status` in `["clean", "flagged"]`
- **TPA5** `GET /api/v1/positions/NONEXIST` — 404 `POSITION_NOT_FOUND`
- **TPA6** `GET /api/v1/portfolio/summary` — all decimal fields parseable
- **TPA7** `PortfolioRepositoryImpl.getPositionDetail('AAPL')` → `PositionDetail` domain object
- **TPA8** `getPositionDetail('NONEXIST')` → throws `ServerException(404)`
- **TPA9** WS `/ws/trading` → receives `portfolio.summary` update within 5s

### E2E Journeys (Journey 1–5)
- **Journey 1** Full app launches for authenticated user
- **Journey 2** `PortfolioScreen` renders `AssetSummaryCard` with Mock Server data
- **Journey 3** Position list shows AAPL and 0700 from Mock Server
- **Journey 4** `PositionDetailScreen(AAPL)` shows "Apple Inc." from Mock Server `company_name`
- **Journey 5** `PortfolioAnalysisScreen` shows "Technology" sector bar

## Architecture Notes

- **Provider reuse**: Portfolio module watches `positionsProvider` and `portfolioSummaryProvider` from the trading module (no data layer duplication).
- **WS inject helpers**: `tradingWsProvider.notifier.injectPositionUpdate()` and `injectPortfolioUpdate()` available for state management tests (added alongside `injectOrderUpdate`).
- **Mock Server requirement**: `GET /api/v1/positions/:symbol` returns extended fields (`company_name`, `sector`, `realized_pnl`, `wash_sale_status`, `recent_trades`) since Portfolio 2026-04-24.
