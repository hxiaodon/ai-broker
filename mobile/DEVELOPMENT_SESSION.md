# Development Session — 2026-04-13

## 🚀 Environment Status

### iOS Simulator
- **Device**: iPhone 17 Pro
- **UUID**: `77C1A607-78C7-48D2-98CF-93A0B3A09451`
- **iOS Version**: 26.4
- **Status**: ✅ Running

### Flutter Application
- **Framework**: Flutter 3.41.4 / Dart 3.7.x
- **Build Mode**: Debug
- **Location**: `mobile/src/`
- **Status**: ✅ Running and synced
- **Entry Point**: `lib/main.dart`
- **Initial Log**: "App starting — Phase 1 skeleton (env: development)"

### Mock Server
- **Binary**: `mobile/mock-server/mock-server`
- **Host**: `localhost`
- **Port**: `8080`
- **Strategy**: `normal` (real-time data simulation)
- **PID**: `4542`
- **Status**: ✅ Running and healthy

---

## 📡 Mock Server API Endpoints (Verified)

### Auth Endpoints
```bash
# 1. Send OTP
POST /v1/auth/otp/send
{
  "phone_number": "+8613812345678"
}
# Response: session_id returned (OTP = "123456")

# 2. Verify OTP
POST /v1/auth/otp/verify
{
  "phone_number": "+8613812345678",
  "otp": "123456"
}
# Response: access_token + refresh_token (3600s expiry)

# 3. Refresh Token
POST /v1/auth/token/refresh
{
  "refresh_token": "xxx"
}

# 4. Register Biometric
POST /v1/auth/biometric/register
{
  "device_id": "device_abc123",
  "biometric_type": "face_id"
}

# 5. Logout
POST /v1/auth/logout
{
  "access_token": "xxx"
}
```

### Market Endpoints
```bash
# Get Quotes
GET /v1/market/quotes?symbols=AAPL,TSLA

# Get Stock Detail
GET /v1/market/stocks/{symbol}

# Search
GET /v1/market/search?q=apple

# Movers (涨跌榜)
GET /v1/market/movers

# WebSocket
ws://localhost:8080/ws/market-data
```

### Health Check
```bash
GET /health
# Response: {"status":"ok","strategy":"normal"}
```

---

## 🎯 Development Workflow

### Hot Reload
```
Press 'r' in Flutter terminal
```

### Hot Restart
```
Press 'R' in Flutter terminal
```

### Stop App
```
Press 'q' in Flutter terminal
```

### Test API Endpoints
```bash
cd mobile

# Quick auth flow test
curl -X POST http://localhost:8080/v1/auth/otp/send \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+8613812345678"}'

# Get quotes
curl "http://localhost:8080/v1/market/quotes?symbols=AAPL,TSLA"
```

---

## 🧪 Running Integration Tests

### Three-Tier Test Pyramid

| Type | File Pattern | Purpose | Dependencies |
|------|---|---|---|
| **State Management** | `*_state_management_test.dart` | Riverpod providers, routing | None |
| **API Integration** | `*_api_integration_test.dart` | HTTP layer with Mock Server | Mock Server |
| **E2E** | `*_e2e_app_test.dart` | Complete user flows | Emulator + Mock Server |

### Run Tests

```bash
cd mobile/src

# All tests
flutter test integration_test/ --verbose

# Specific module
flutter test integration_test/auth/auth_state_management_test.dart
flutter test integration_test/auth/auth_api_integration_test.dart
flutter test integration_test/auth/auth_e2e_app_test.dart

# Market tests
flutter test integration_test/market/ --verbose
```

### Automated Test Script
```bash
cd mobile
./run-integration-tests.sh  # Starts Mock Server + runs all tests
```

---

## 📊 Mock Server Strategies

For testing different scenarios, restart the Mock Server with different strategies:

```bash
cd mobile/mock-server

# Normal mode (current)
./mock-server --strategy=normal

# Guest mode (15-minute delayed data)
./mock-server --strategy=guest

# Delayed mode (6-second stale data)
./mock-server --strategy=delayed

# Error mode (auth failures)
./mock-server --strategy=error

# Unstable mode (30% connection drop probability)
./mock-server --strategy=unstable
```

**To switch strategy without restarting:**
1. Kill current process: `kill -9 4542`
2. Start new one: `./mock-server --strategy=<new_strategy>`

---

## 🔧 Android Emulator (Alternative)

If you need to test on Android instead:

```bash
# List available emulators
flutter emulators

# Start Android emulator
flutter emulators --launch <emulator_id>

# Run on Android
flutter run -d <emulator_id>
```

**Note**: For Android emulator, use `10.0.2.2` instead of `localhost` to access the Mock Server.

---

## 📋 Next Steps

1. **Login Flow**: Test OTP send → verify → token exchange
2. **Market Data**: Monitor WebSocket and real-time quotes
3. **K-line Charts**: Verify Syncfusion candlestick rendering
4. **State Management**: Observe Riverpod provider state changes
5. **Error Handling**: Test edge cases with different Mock Server strategies

---

## 🆘 Troubleshooting

### Mock Server won't start
```bash
# Check if port 8080 is in use
lsof -i :8080

# Kill process if needed
kill -9 <PID>

# Try different port
cd mobile/mock-server
./mock-server --port=9090
```

### Flutter can't connect to Mock Server
- iOS Simulator: Uses `localhost:8080` automatically
- Android Emulator: Use `10.0.2.2:8080` instead
- Physical device: Use your Mac's IP address (e.g., `192.168.x.x:8080`)

### App won't sync files
```bash
cd mobile/src
flutter clean
flutter pub get
flutter run
```

### WebSocket connection issues
- Check Mock Server is running: `curl http://localhost:8080/health`
- Verify WebSocket endpoint: `ws://localhost:8080/ws/market-data`
- Test with wscat: `npm install -g wscat && wscat -c ws://localhost:8080/ws/market-data`

---

**Session Started**: 2026-04-13 10:40:56  
**Flutter Version**: 3.41.4  
**Dart Version**: 3.7.x  
**Environment**: Development  
**Target**: iOS (iPhone 17 Pro Simulator)
