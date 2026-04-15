# P0-2 Cache E2E Testing Guide

## Quick Start

### Prerequisites
1. **iOS Simulator**: Running `xcrun simctl list | grep -i booted`
2. **Mock Server**: Running locally on `localhost:8080`
3. **Flutter SDK**: Configured in PATH

### Run All E2E Cache Tests
```bash
# 1. Start Mock Server (from mobile directory)
cd mobile/mock-server
go run . --strategy=normal

# 2. In another terminal, run E2E tests (from mobile/src)
cd mobile/src
flutter test integration_test/market/market_cache_e2e_test.dart -v

# Expected output:
# ℹ️ 9 test scenarios
# ✅ All tests should pass in ~20 seconds
```

---

## Test Scenarios Explained

### Scenario 1: Happy Path (Online)
**What**: API is online, data fetches successfully, cache updates
- ✅ Fresh data returned (isStale: false)
- ✅ No offline indicator shown
- ✅ Cache updated for next use

**When to use**: Verify normal operation with good connectivity

---

### Scenario 2: Fresh Cache Fallback
**What**: API fails but cache is fresh (< 30 seconds old)
- ✅ Cached data returned even though API failed
- ✅ User sees no error message
- ✅ App remains responsive

**When to use**: Verify graceful degradation on temporary API issues

---

### Scenario 3: Expired Cache Rejection
**What**: API fails and cache is stale (> 30 seconds old)
- ⚠️ Cache is rejected (too old)
- ⚠️ NetworkException propagated
- ✅ UI shows error, user can retry

**When to use**: Verify data freshness constraints are enforced

---

### Scenario 4: Weak Network
**What**: API is slow (3-5 second response), cache exists
- ⏳ User waits for slow API response
- ✅ Data eventually arrives from API
- ✅ Cache updates with fresh data

**When to use**: Verify app remains usable on slow connections (2G/3G)

---

### Scenario 5: Offline Mode
**What**: No network available, cache displays with indicator
- ✅ Cached data visible on screen
- ℹ️ Offline indicator badge shown (ideally)
- ✅ App stable, no crashes
- ✅ User can still view data

**When to use**: Verify offline-first architecture works (airplane mode, tunnel, dead zone)

---

### Scenario 6: Rapid Requests
**What**: Multiple quote fetches within 30s TTL
- ✅ First fetch hits API, populates cache
- ✅ Second fetch uses cache (no duplicate API call)
- ✅ Efficient caching, no network thrashing

**When to use**: Verify TTL-based cache avoids redundant requests

---

### Scenario 7: Stale Data Flag
**What**: Offline data returned with isStale=true
- ✅ "数据延迟" badge shown in UI
- ✅ User knows data is cached/delayed
- ✅ Can still interact with stale data

**When to use**: Verify UI transparency about data freshness

---

### Scenario 8: Cache Persistence
**What**: Navigate away from market, return to it
- ✅ Cache data immediately restored
- ✅ No re-fetch needed
- ✅ Seamless UX

**When to use**: Verify cache survives app navigation

---

### Scenario 9: Network Recovery
**What**: Offline → Online, user pulls to refresh
- ✅ Fresh API data fetched
- ✅ Cache updated with new data
- ✅ Offline indicator removed (fresh data)

**When to use**: Verify smooth transition from offline to online

---

## Running Individual Tests

### Single Scenario
```bash
# Run only Scenario 1 (Happy Path)
flutter test integration_test/market/market_cache_e2e_test.dart \
  -k "Scenario 1" -v

# Run only Scenario 5 (Offline Mode)
flutter test integration_test/market/market_cache_e2e_test.dart \
  -k "Scenario 5" -v
```

### With Network Simulation

#### Scenario: Slow Network (3-5s delay)
```bash
# Terminal 1: Start Mock Server with slow strategy
cd mobile/mock-server
go run . --strategy=slow

# Terminal 2: Run Scenario 4
cd mobile/src
flutter test integration_test/market/market_cache_e2e_test.dart \
  -k "Scenario 4" -v
```

#### Scenario: Offline (No Network)
```bash
# Terminal 1: Start Mock Server with offline strategy
cd mobile/mock-server
go run . --strategy=offline

# Terminal 2: Run Scenario 5
cd mobile/src
flutter test integration_test/market/market_cache_e2e_test.dart \
  -k "Scenario 5" -v
```

---

## Integration Test Tiers

### Tier 1: Unit Tests (Fast)
```bash
flutter test test/features/market/data/quote_cache_repository_test.dart
# ~1 second, 8 tests
# Tests: cache logic, TTL, decimal precision
# No UI, no network, no Flutter binding
```

### Tier 2: API Integration Tests (Medium)
```bash
flutter test test/features/market/data/quote_cache_repository_api_integration_test.dart
# ~8 seconds, 10 tests
# Tests: API→cache→return flows, HTTP layer
# Uses mocked HTTP client, real cache logic
```

### Tier 3: E2E Tests (Complete)
```bash
flutter test integration_test/market/market_cache_e2e_test.dart
# ~20 seconds, 9 scenarios
# Tests: real Flutter app UI, real network calls, user interactions
# Requires: emulator + Mock Server
```

### Run All Three Tiers
```bash
# All market tests in sequence
flutter test test/features/market/data/ integration_test/market/

# Expected: 27 tests total, ~30 seconds
```

---

## Mock Server Strategies

| Strategy | Behavior | Use Case |
|----------|----------|----------|
| `normal` | Returns data in ~100ms | Normal operation |
| `slow` | Returns data in 3-5 seconds | Weak network (2G/3G) |
| `offline` | Throws connection error | No network/airplane mode |

### Switching Strategies
```bash
# Start with normal
go run . --strategy=normal

# Ctrl+C, restart with slow
go run . --strategy=slow

# Ctrl+C, restart with offline
go run . --strategy=offline
```

---

## CI/CD Integration

### GitHub Actions
```yaml
# .github/workflows/flutter-e2e.yml
name: E2E Tests

on: [push, pull_request]

jobs:
  e2e:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
      
      - name: Start Mock Server
        run: cd mobile/mock-server && go run . --strategy=normal &
      
      - name: Run E2E Tests
        run: cd mobile/src && flutter test integration_test/market/market_cache_e2e_test.dart
      
      - name: Upload Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: flutter-e2e-results
          path: build/flutter_test_results/
```

---

## Debugging Failed Tests

### Test Hangs/Times Out
```bash
# Run with extended timeout
flutter test integration_test/market/market_cache_e2e_test.dart \
  --timeout=60000 -v

# Check Mock Server is running
lsof -i :8080  # Should show go run process
```

### Mock Server Connection Refused
```bash
# Start Mock Server with verbose logging
cd mobile/mock-server
go run . --strategy=normal -v

# Check it's listening
curl http://localhost:8080/health
# Expected: {"status":"ok"}
```

### Cache Data Not Found
```bash
# Verify SQLite database is writable
ls -la ~/Library/Developer/Xcode/DerivedData/*/Caches/

# Check Drift database location in logs
flutter test ... -v 2>&1 | grep -i "database\|sqlite\|drift"
```

---

## Performance Baseline

| Test Tier | Count | Time | Purpose |
|-----------|-------|------|---------|
| Unit | 8 | ~1s | Logic validation |
| API Integration | 10 | ~8s | HTTP layer |
| E2E | 9 | ~20s | User journeys |
| **Total** | **27** | **~30s** | **Complete coverage** |

---

## Next Steps (P0-3)

Once E2E cache tests are passing:

1. **WebSocket Auto-Reconnect** (P0-3)
   - Implement exponential backoff
   - Connection state machine
   - Message buffering during reconnect
   - Health checks (ping/pong)

2. **Market Data Integration**
   - Combine cache layer + WebSocket
   - Real-time updates with fallback to cache
   - Seamless transition between modes

3. **Load Testing**
   - High-frequency updates (100+ quotes/sec)
   - Connection churn (connect/disconnect cycles)
   - Memory pressure (large position lists)

---

## Checklist for Test Review

- [ ] All 9 E2E scenarios passing
- [ ] Mock Server strategies working (normal, slow, offline)
- [ ] Cache TTL validation correct (30 seconds)
- [ ] Offline indicator (isStale flag) visible in UI
- [ ] No crashes in offline mode
- [ ] Cache persists across navigation
- [ ] Weak network handled gracefully
- [ ] Zero lint warnings in test code
- [ ] Documentation complete and clear
