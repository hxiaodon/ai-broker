# Mobile Engineer Quick Commands

## 🎯 Current Session

| Item | Value |
|------|-------|
| **Simulator** | iPhone 17 Pro (iOS 26.4) |
| **App** | Running in Debug mode |
| **Mock Server** | ✅ http://localhost:8080 (strategy: normal) |
| **Current Screen** | Market / Quotes Tab |

---

## ⚡ Quick Commands (Run from `mobile/src` or `mobile/`)

### 📱 App Control

```bash
# Hot reload (preserves state)
r

# Hot restart (full restart)
R

# Quit app
q

# Run with verbose logging
flutter run -v

# Run with specific device
flutter run -d "77C1A607-78C7-48D2-98CF-93A0B3A09451"

# Clean rebuild
flutter clean && flutter pub get && flutter run
```

### 🧪 Testing

```bash
# Run all integration tests
cd mobile/src
flutter test integration_test/ --verbose

# Run specific test file
flutter test integration_test/auth/auth_state_management_test.dart

# Run with coverage
flutter test --coverage integration_test/

# Run test with custom timeout
flutter test integration_test/ --timeout=30m
```

### 🔌 Mock Server Control

```bash
cd mobile/mock-server

# Current (normal strategy)
./mock-server --strategy=normal

# Switch strategy (kill & restart)
./mock-server --strategy=delayed   # 6s stale data
./mock-server --strategy=guest     # 15m delayed data
./mock-server --strategy=error     # auth failures
./mock-server --strategy=unstable  # 30% disconnect

# Check health
curl http://localhost:8080/health | jq

# Kill all mock servers
killall mock-server
# or
kill -9 4542
```

### 📡 API Testing from Terminal

```bash
# Auth flow
curl -X POST http://localhost:8080/v1/auth/otp/send \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+8613812345678"}'

# Verify OTP (code = 123456)
curl -X POST http://localhost:8080/v1/auth/otp/verify \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+8613812345678", "otp": "123456"}'

# Market quotes
curl "http://localhost:8080/v1/market/quotes?symbols=AAPL,TSLA" | jq

# WebSocket test
wscat -c ws://localhost:8080/ws/market-data
```

### 📊 Screenshots & Logging

```bash
# Capture simulator screenshot
xcrun simctl io "77C1A607-78C7-48D2-98CF-93A0B3A09451" screenshot ~/Desktop/app.png

# View Flutter logs
flutter logs

# View only errors
flutter logs | grep -i "error\|exception"

# Clear logs and run fresh
flutter logs -c
flutter run
```

### 🔍 Debugging

```bash
# Attach debugger
flutter attach

# Run with performance profiling
flutter run --profile

# Release build (final)
flutter run --release

# Check for issues
flutter doctor

# Analyze code
dart analyze lib/

# Format code
dart format lib/ -i
```

---

## 📂 Key File Paths

| What | Path |
|------|------|
| App Entry | `mobile/src/lib/main.dart` |
| Auth Module | `mobile/src/lib/features/auth/` |
| Market Module | `mobile/src/lib/features/market/` |
| Providers | `mobile/src/lib/features/*/providers/` |
| Widgets | `mobile/src/lib/features/*/widgets/` |
| Config | `mobile/src/lib/core/config/` |
| HTTP Client | `mobile/src/lib/core/http/` |
| Integration Tests | `mobile/src/integration_test/` |
| Mock Server | `mobile/mock-server/` |

---

## 🚨 Common Issues

### App won't sync to simulator
```bash
cd mobile/src
flutter clean
rm -rf build/ .dart_tool/ pubspec.lock
flutter pub get
flutter run
```

### Mock Server won't start (port in use)
```bash
lsof -i :8080
kill -9 <PID>
cd mobile/mock-server
./mock-server --strategy=normal
```

### WebSocket connection issues
```bash
# Verify Mock Server is running
curl http://localhost:8080/health

# Check WebSocket endpoint
wscat -c ws://localhost:8080/ws/market-data
```

### Biometric auth fails in simulator
- Local_auth returns `false` in simulator by default
- Test with `strategy=error` to verify error handling
- Or mock the biometric response in tests

---

## 📚 Documentation

- [INTEGRATION_TEST_GUIDE.md](./docs/INTEGRATION_TEST_GUIDE.md) — Three-tier test pyramid
- [MOCK_SERVER_GUIDE.md](./docs/MOCK_SERVER_GUIDE.md) — Mock Server detailed guide
- [TESTING_PRACTICES.md](./docs/TESTING_PRACTICES.md) — Manual testing checklist
- [DEVELOPMENT_SESSION.md](./DEVELOPMENT_SESSION.md) — Current session status
- [mobile/CLAUDE.md](./CLAUDE.md) — Mobile domain routing

---

## 🎓 Learning Resources

- **Flutter docs**: https://flutter.dev/docs
- **Riverpod**: https://riverpod.dev
- **Dio HTTP**: https://pub.dev/packages/dio
- **Syncfusion Charts**: https://www.syncfusion.com/flutter-widgets/flutter-charts

---

**Last Updated**: 2026-04-13 10:45  
**Status**: ✅ All systems operational
