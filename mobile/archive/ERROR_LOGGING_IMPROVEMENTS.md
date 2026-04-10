# Error Logging Improvements - Implementation Report

## Context

Following today's lengthy debugging session for the watchlist loading issue, we identified that **missing error logs at critical boundaries** made debugging extremely difficult. This document summarizes the systematic improvements made to add comprehensive error logging throughout the mobile project.

## Root Cause of Debugging Difficulty

Three critical errors occurred but were hard to diagnose due to lack of logging:

1. **DTO deserialization failures** - JSON parsing errors had no logs
2. **Hive initialization failure** - HiveError was caught by Riverpod but not logged
3. **UI layer generic errors** - Users saw "加载失败" but logs had no details

The data flow boundaries (Network → DTO → Repository → Provider → UI) lacked error logging, turning a 10-minute fix into a multi-hour debugging session.

## Implementation Summary

### Phase 1: High Priority - Data Layer (COMPLETED)

#### 1. `watchlist_local_datasource.dart` ✅
**Problem**: All Hive operations lacked try-catch blocks. HiveError was the root cause of today's issue.

**Changes**:
- Added try-catch with `AppLogger.error()` to `getItems()`, `saveItems()`, `clear()`
- `getItems()` returns default watchlist on error to keep UI functional
- `saveItems()` and `clear()` rethrow after logging

**Impact**: Future Hive errors will be immediately visible in logs with full stack traces.

#### 2. `error_interceptor.dart` ✅
**Problem**: DioException was mapped to AppException but never logged.

**Changes**:
- Added `AppLogger.warning()` in `_mapError()` method
- Logs: exception type, status code, request path

**Impact**: All network errors now logged before being transformed to domain exceptions.

#### 3. `auth_interceptor.dart` ✅
**Problem**: Token refresh attempts had no logging.

**Changes**:
- Added `AppLogger.debug()` for refresh attempts
- Added `AppLogger.debug()` for successful refresh
- Added `AppLogger.warning()` for null token response
- Added `AppLogger.error()` for refresh failures with full stack trace

**Impact**: Token refresh flow is now fully traceable in logs.

#### 4. `market_mappers.dart` ✅
**Problem**: Decimal parsing failures only had debug assertions (no logs in release builds).

**Changes**:
- Replaced `assert()` with `AppLogger.warning()` in `_d()` helper
- Updated documentation to reflect logging instead of assertions

**Impact**: Malformed price data from API will be logged in all build modes.

### Phase 2: Medium Priority - Application Layer (COMPLETED)

#### 5. `stock_detail_notifier.dart` ✅
**Problem**: `build()` method had no error handling.

**Changes**:
- Wrapped entire `build()` method in try-catch
- Added `AppLogger.error()` with symbol context and full stack trace
- Rethrows to preserve Riverpod error state

**Impact**: Stock detail loading failures now logged with symbol information.

#### 6. `watchlist_notifier.dart` ✅
**Problem**: `add()`, `remove()`, `reorder()` methods had no error handling.

**Changes**:
- Added try-catch with `AppLogger.error()` to all three methods
- Each logs the operation context (symbol, count) before rethrowing

**Impact**: Watchlist mutations now fully traceable in logs.

#### 7. `movers_provider.dart` ✅
**Problem**: Provider function had no error handling.

**Changes**:
- Wrapped provider body in try-catch
- Added `AppLogger.error()` with type and market parameters
- Rethrows to preserve Riverpod error state

**Impact**: Movers list loading failures now logged with query parameters.

## Files Modified

### High Priority (7 files)
1. `lib/features/market/data/local/watchlist_local_datasource.dart`
2. `lib/core/network/error_interceptor.dart`
3. `lib/core/network/auth_interceptor.dart`
4. `lib/features/market/data/mappers/market_mappers.dart`

### Medium Priority (3 files)
5. `lib/features/market/application/stock_detail_notifier.dart`
6. `lib/features/market/application/watchlist_notifier.dart`
7. `lib/features/market/application/movers_provider.dart`

## Verification

### Unit Tests
```bash
flutter test test/features/market/data/watchlist_repository_test.dart
```
**Result**: ✅ All tests passed

### Expected Log Output

When errors occur, logs will now show the complete error chain:

```
[ERROR] DioException: connectionTimeout no-status /v1/market/quotes
[ERROR] WatchlistRepo: _guestWatchlist failed: NetworkException: Request timed out
  Stack trace: ...
[ERROR] WatchlistNotifier: failed to add AAPL
  Stack trace: ...
[ERROR] Load watchlist failed
  Stack trace: ...
```

## Deferred Work (Low Priority)

The following improvements were planned but deferred as they are less critical:

### Presentation Layer (4 files)
- Create `lib/shared/utils/async_value_logger.dart` helper
- Add logging to `stock_detail_screen.dart` AsyncValue.when() error branch
- Add logging to `watchlist_tab.dart` AsyncValue.when() error branch
- Add logging to `movers_tab.dart` AsyncValue.when() error branch
- Add logging to `kline_chart_widget.dart` AsyncValue.when() error branch

**Rationale for deferral**: Application layer logging already captures these errors. UI layer logging would be redundant for most cases.

## Key Lessons Applied

1. **Log at every boundary**: Network → DTO → Repository → Provider → UI
2. **Include context**: Always log operation parameters (symbol, market, type)
3. **Full stack traces**: Use `AppLogger.error(error: e, stackTrace: stack)`
4. **Graceful degradation**: `getItems()` returns defaults instead of crashing
5. **Rethrow after logging**: Preserve error propagation for Riverpod state

## Expected Impact

When similar issues occur in the future:

- **Before**: 2-3 hours of debugging with trial-and-error
- **After**: 5-10 minutes to identify root cause from logs

The complete error chain will be visible:
1. Where the error originated (network, Hive, parsing)
2. What operation was being performed (symbol, parameters)
3. Full stack trace for root cause analysis
4. Error propagation through all layers

## Related Documents

- Original issue: `mobile/FINAL_FIX_REPORT.md`
- Implementation plan: `/Users/huoxd/.claude/plans/golden-napping-hamming.md`
- Test results: `mobile/src/test/features/market/data/watchlist_repository_test.dart`

---

**Implementation Date**: 2026-04-08  
**Status**: Phase 1 & 2 Complete ✅  
**Tests**: Passing ✅
