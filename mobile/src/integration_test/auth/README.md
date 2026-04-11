# Auth Module Integration Tests

This directory contains three types of integration tests for the Auth module, following the standard classification defined in [INTEGRATION_TEST_GUIDE.md](../INTEGRATION_TEST_GUIDE.md).

## Files

### 1. `auth_state_management_test.dart`
**Type**: State Management Tests  
**Dependencies**: None (no Mock Server required)  
**Speed**: Very fast (~13 seconds)  
**When to run**: During development, after every code change

Tests Riverpod providers, routing logic, and app state management.

```bash
flutter test integration_test/auth/auth_state_management_test.dart
```

**What it tests**:
- ✅ App renders correctly in different auth states
- ✅ Token service stores/retrieves tokens
- ✅ Routing navigates to correct screens
- ✅ Multi-device scenarios

**What it does NOT test**:
- ❌ HTTP API calls
- ❌ Complete user UI flows
- ❌ Network errors

---

### 2. `auth_api_integration_test.dart`
**Type**: API Integration Tests  
**Dependencies**: Mock Server (localhost:8080)  
**Speed**: Fast (~8 seconds)  
**When to run**: Before commits, in CI/CD

Tests HTTP API layer and Mock Server integration using Dio HTTP client.

```bash
# Prerequisites: Mock Server must be running
cd mobile/mock-server && go run . --strategy=normal

# In another terminal:
flutter test integration_test/auth/auth_api_integration_test.dart
```

**What it tests**:
- ✅ OTP send/verify flows
- ✅ Biometric registration and verification
- ✅ Device management (register, list, delete)
- ✅ Account lockout after failed attempts
- ✅ Token refresh
- ✅ Error responses

**What it does NOT test**:
- ❌ Flutter app UI rendering
- ❌ User UI interactions
- ❌ App state management

---

### 3. `auth_e2e_app_test.dart`
**Type**: End-to-End (E2E) Tests  
**Dependencies**: Emulator/Device + Mock Server (localhost:8080)  
**Speed**: Moderate (~16 seconds total)  
**When to run**: Before release, in full CI/CD pipeline

Tests complete user journeys from UI interaction to app state.

```bash
# Prerequisites:
# 1. Mock Server running
cd mobile/mock-server && go run . --strategy=normal

# 2. Emulator/Device running
# 3. In another terminal:
flutter test integration_test/auth/auth_e2e_app_test.dart
```

**Test journeys**:
1. **Journey 1**: Complete OTP login flow (phone → send OTP → verify → home)
2. **Journey 2**: Error handling for wrong OTP
3. **Journey 3**: Guest user accessing market without login
4. **Journey 4**: Authenticated user skipping login
5. **Journey 5**: App stability during user interactions

**What it tests**:
- ✅ Complete user flows from UI to app state
- ✅ App calls correct API endpoints
- ✅ Navigation works correctly
- ✅ Error messages display properly
- ✅ App remains stable during interactions

---

## Running All Auth Tests

### Quick feedback (state management only - no external dependencies)
```bash
flutter test integration_test/auth/auth_state_management_test.dart
# Time: ~13 seconds
```

### With API testing (requires Mock Server)
```bash
# Terminal 1: Start Mock Server
cd mobile/mock-server && go run . --strategy=normal

# Terminal 2: Run all tests except E2E
flutter test integration_test/auth/auth_state_management_test.dart
flutter test integration_test/auth/auth_api_integration_test.dart
# Time: ~21 seconds total
```

### Full testing (requires Mock Server + Emulator)
```bash
# Terminal 1: Start Mock Server
cd mobile/mock-server && go run . --strategy=normal

# Terminal 2: Run all tests including E2E
flutter test integration_test/auth/
# Time: ~40 seconds total (15+8+13+4 teardown)
```

---

## Test Results Summary

✅ **auth_state_management_test.dart**: 15/15 tests passed
- App state rendering
- Token management
- Security
- Error handling
- Multi-device support

✅ **auth_api_integration_test.dart**: 8/8 tests passed
- OTP complete flow
- Wrong OTP handling
- Biometric flows
- Device management
- Token refresh
- Account lockout
- Logout

✅ **auth_e2e_app_test.dart**: 5/5 journeys passed
- OTP login complete flow
- Error handling
- Guest mode
- Authenticated user
- App stability

**Total**: 28/28 tests passing ✅

---

## For Other Modules

When implementing integration tests for other modules (Market, Trading, Portfolio, etc.), follow the same pattern:

```
integration_test/{module}/
├── {module}_state_management_test.dart    # Required
├── {module}_api_integration_test.dart     # Required
├── {module}_e2e_app_test.dart            # Required
├── helpers/
│   └── test_app.dart                      # Can be shared
└── README.md                              # Document like this
```

See [INTEGRATION_TEST_GUIDE.md](../INTEGRATION_TEST_GUIDE.md) for detailed standards and common patterns.

---

## Troubleshooting

### "Connection refused" when running API tests
**Solution**: Mock Server is not running. Start it with:
```bash
cd mobile/mock-server && go run . --strategy=normal
```

### "findWidgets didn't find any widgets" in E2E tests
**Solution**: The app UI structure may differ from test expectations. Review the actual widget tree and adjust find selectors. Check the test's error message for suggested finders.

### Tests timeout
**Solution**: Increase timeout or check if Mock Server is responding slowly. Look for network latency issues.

### Riverpod provider override conflicts
**Solution**: Each testWidgets should create a **single, fresh app instance**. Don't pumpWidget multiple times in one test.

---

## Best Practices

1. **One test = One complete flow**: Don't try to test multiple scenarios in a single test
2. **Use descriptive names**: Test names should describe what user journey is being tested
3. **Isolate state**: Each test gets a fresh app instance
4. **Add logging**: Use `print()` statements with 📱, ✅, ❌ emojis for easy log reading
5. **Check dependencies**: Verify Mock Server and emulator are running before E2E tests
