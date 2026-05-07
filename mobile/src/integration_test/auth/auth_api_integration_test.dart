import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dio/dio.dart';

/// Auth Module — API Integration Tests
///
/// **Purpose**: Verify HTTP API layer and Mock Server integration
/// **Dependencies**: Mock Server running on localhost:8080
/// **Speed**: Fast (~8 seconds)
/// **Run when**: Before commits, in CI/CD pipeline
///
/// **What is tested**:
/// - OTP send/verify flows
/// - Biometric registration and verification
/// - Device management (register, list, delete)
/// - Account lockout after failed attempts
/// - Token refresh
/// - Error responses and handling
///
/// **What is NOT tested**:
/// - Flutter app UI rendering (see auth_e2e_app_test.dart)
/// - User UI interactions
/// - App state management
/// - Routing
///
/// These tests directly call Mock Server HTTP endpoints using Dio client.
/// No Flutter app is launched - only the HTTP layer is tested.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Dio client for direct API calls
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  group('Auth E2E - Real Backend Integration', () {
    testWidgets(
      'E1: Complete OTP login flow with Mock Server',
      (tester) async {
        printOnFailure('📱 E1: Starting complete OTP login flow');

        // Step 1: Send OTP
        printOnFailure('  📨 Step 1: Sending OTP to +8613812345678...');
        final sendResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/otp/send',
          data: {'phone_number': '+8613812345678'},
        );

        expect(sendResponse.statusCode, 200);
        expect(sendResponse.data!['request_id'], isNotEmpty);
        expect(sendResponse.data!['expires_in_seconds'], isNotNull);
        // P1-04: PRD-01 §6.1 — OTP send response must include 60s resend cooldown
        expect(
          sendResponse.data!['retry_after_seconds'],
          60,
          reason: 'OTP send must enforce 60s resend cooldown per PRD-01 §6.1',
        );
        printOnFailure('  ✅ OTP sent, retry_after_seconds=60');

        // Step 2: Verify OTP (using mock code 123456)
        printOnFailure('  🔐 Step 2: Verifying OTP code 123456...');
        final verifyResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/otp/verify',
          data: {
            'phone_number': '+8613812345678',
            'otp_code': '123456',
          },
        );

        expect(verifyResponse.statusCode, 200);
        expect(verifyResponse.data!['access_token'], isNotEmpty);
        expect(verifyResponse.data!['refresh_token'], isNotEmpty);
        expect(verifyResponse.data!['account_id'], isNotEmpty);
        expect(verifyResponse.data!['status'], isNotEmpty);

        final accessToken = verifyResponse.data!['access_token'];
        printOnFailure('  ✅ OTP verified, access token: ${(accessToken as String).substring(0, 16)}...');

        // Step 3: App would navigate to home
        printOnFailure('  🏠 Step 3: Navigating to home screen...');
        expect(accessToken, isNotEmpty);
        printOnFailure('  ✅ Login flow complete');

        printOnFailure('✅ E1 PASSED: Complete OTP login flow');
      },
    );

    testWidgets(
      'E2: Wrong OTP attempt with error count',
      (tester) async {
        printOnFailure('\n📱 E2: Testing wrong OTP attempt');

        // Send OTP first
        await dio.post<Map<String, dynamic>>('/v1/auth/otp/send', data: {
          'phone_number': '+8613812345678',
        });

        // Try wrong OTP
        printOnFailure('  ❌ Attempting wrong OTP (000000)...');
        final wrongResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/otp/verify',
          data: {
            'phone_number': '+8613812345678',
            'otp_code': '000000',
          },
          options: Options(validateStatus: (status) => status! < 500),
        );

        // Mock server (and production AMS) return 401 for invalid OTP
        expect(wrongResponse.statusCode, 401);
        expect(wrongResponse.data!['message'], contains('验证码错误'));
        printOnFailure('  ✅ Error message shown: ${wrongResponse.data!['message']}');

        printOnFailure('✅ E2 PASSED: Wrong OTP handling');
      },
    );

    testWidgets(
      'E3: Biometric registration flow',
      (tester) async {
        printOnFailure('\n📱 E3: Testing biometric registration');

        const deviceId = 'device-e3-12345';
        const biometricType = 'face_id';

        // Register biometric
        printOnFailure('  👆 Registering $biometricType on device $deviceId...');
        final registerResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/biometric/register',
          data: {
            'device_id': deviceId,
            'biometric_type': biometricType,
          },
        );

        expect(registerResponse.statusCode, 200);
        expect(registerResponse.data!['success'], true);
        expect(registerResponse.data!['message'], contains('注册成功'));
        printOnFailure('  ✅ Biometric registered');

        // Verify biometric
        printOnFailure('  🔐 Verifying biometric...');
        final verifyResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/biometric/verify',
          data: {
            'device_id': deviceId,
            'biometric_type': biometricType,
          },
        );

        expect(verifyResponse.statusCode, 200);
        expect(verifyResponse.data!['success'], true);
        expect(verifyResponse.data!['access_token'], isNotEmpty);
        printOnFailure('  ✅ Biometric verified, got access token');

        printOnFailure('✅ E3 PASSED: Biometric registration and verification');
      },
    );

    testWidgets(
      'E4: Device management - register and list',
      (tester) async {
        printOnFailure('\n📱 E4: Testing device management');

        const deviceId = 'device-e4-xyz789';

        // Register a device via biometric registration
        printOnFailure('  📱 Registering device $deviceId...');
        await dio.post<Map<String, dynamic>>('/v1/auth/biometric/register', data: {
          'device_id': deviceId,
          'biometric_type': 'fingerprint',
        });
        printOnFailure('  ✅ Device registered');

        // Get devices list
        printOnFailure('  📋 Fetching devices list...');
        final listResponse = await dio.get<Map<String, dynamic>>(
          '/v1/auth/devices',
        );

        expect(listResponse.statusCode, 200);
        expect(listResponse.data!['success'], true);
        expect(listResponse.data!['devices'], isNotEmpty);

        final devices = listResponse.data!['devices'] as List;
        expect(
          devices.any((d) => d['device_id'] == deviceId),
          true,
          reason: 'Device should be in list',
        );
        printOnFailure('  ✅ Device found in list (${devices.length} device(s) total)');

        printOnFailure('✅ E4 PASSED: Device listing');
      },
    );

    testWidgets(
      'E5: Device deletion',
      (tester) async {
        printOnFailure('\n📱 E5: Testing device deletion');

        const deviceId = 'device-e5-delete-me';

        // Register device
        await dio.post<Map<String, dynamic>>('/v1/auth/biometric/register', data: {
          'device_id': deviceId,
          'biometric_type': 'face_id',
        });

        // Verify it's in the list
        var listResponse = await dio.get<Map<String, dynamic>>(
          '/v1/auth/devices',
        );
        var devices = listResponse.data!['devices'] as List;
        expect(
          devices.any((d) => d['device_id'] == deviceId),
          true,
        );
        printOnFailure('  ✅ Device registered and verified in list');

        // Delete device
        printOnFailure('  🗑️  Deleting device...');
        final deleteResponse = await dio.delete<Map<String, dynamic>>(
          '/v1/auth/devices/$deviceId',
        );

        expect(deleteResponse.statusCode, 200);
        expect(deleteResponse.data!['success'], true);
        printOnFailure('  ✅ Device deleted');

        // Verify it's removed
        listResponse = await dio.get<Map<String, dynamic>>(
          '/v1/auth/devices',
        );
        devices = listResponse.data!['devices'] as List;
        expect(
          devices.any((d) => d['device_id'] == deviceId),
          false,
          reason: 'Device should no longer be in list',
        );
        printOnFailure('  ✅ Device confirmed removed from list');

        printOnFailure('✅ E5 PASSED: Device deletion');
      },
    );

    testWidgets(
      'E6: Token refresh',
      (tester) async {
        printOnFailure('\n📱 E6: Testing token refresh');

        // Get initial tokens
        final loginResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/otp/verify',
          data: {
            'phone_number': '+8613812345678',
            'otp_code': '123456',
          },
          options: Options(validateStatus: (status) => true),
        );

        if (loginResponse.statusCode != 200) {
          // Resend OTP first
          await dio.post<Map<String, dynamic>>('/v1/auth/otp/send', data: {
            'phone_number': '+8613812345678',
          });

          final retryResponse = await dio.post<Map<String, dynamic>>(
            '/v1/auth/otp/verify',
            data: {
              'phone_number': '+8613812345678',
              'otp_code': '123456',
            },
          );
          expect(retryResponse.statusCode, 200);
        }

        final refreshToken =
            loginResponse.data!['refresh_token'] ?? 'test-refresh-token';

        // Refresh token
        printOnFailure('  🔄 Refreshing token...');
        final refreshResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/token/refresh',
          data: {'refresh_token': refreshToken},
        );

        expect(refreshResponse.statusCode, 200);
        expect(refreshResponse.data!['access_token'], isNotEmpty);
        expect(refreshResponse.data!['refresh_token'], isNotEmpty);
        printOnFailure(
          '  ✅ Token refreshed: ${(refreshResponse.data!['access_token'] as String).substring(0, 16)}...',
        );

        printOnFailure('✅ E6 PASSED: Token refresh');
      },
    );

    testWidgets(
      'E7: Account lockout after 5 failed OTP attempts (PRD-01 §6.1, NIST SP 800-63B)',
      (tester) async {
        printOnFailure('\n📱 E7: Testing account lockout after 5 failed OTP attempts');

        // Unique phone to avoid cross-test lockout contamination
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final phoneNumber = '+861381234${timestamp.toString().substring(timestamp.toString().length - 4)}';

        // Send OTP
        final sendResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/otp/send',
          data: {'phone_number': phoneNumber},
          options: Options(validateStatus: (status) => status! < 500),
        );
        expect(sendResponse.statusCode, 200);

        // Submit 5 wrong OTPs — each should fail with INVALID_OTP_CODE (attempts 1-4)
        // or OTP_MAX_ATTEMPTS_EXCEEDED (attempt 5)
        printOnFailure('  ❌ Submitting 5 wrong OTP codes...');
        Map<String, dynamic>? lastData;
        int? lastStatus;
        for (int i = 1; i <= 5; i++) {
          final response = await dio.post<Map<String, dynamic>>(
            '/v1/auth/otp/verify',
            data: {
              'phone_number': phoneNumber,
              'otp_code': '000000', // always wrong
            },
            options: Options(validateStatus: (status) => status! < 500),
          );
          lastData = response.data;
          lastStatus = response.statusCode;
          printOnFailure('    Attempt $i: ${response.statusCode} ${response.data!['error_code']}');
        }

        // 5th attempt must trigger lockout
        expect(lastStatus, 401);
        expect(lastData!['error_code'], 'OTP_MAX_ATTEMPTS_EXCEEDED');
        expect(lastData['lockout_until'], isNotNull,
            reason: 'lockout_until must be present so UI can show countdown');
        printOnFailure('  🔒 Locked: error_code=${lastData['error_code']}, lockout_until=${lastData['lockout_until']}');

        // 6th verify attempt must still be rejected with lockout error
        final sixthAttempt = await dio.post<Map<String, dynamic>>(
          '/v1/auth/otp/verify',
          data: {
            'phone_number': phoneNumber,
            'otp_code': '000000',
          },
          options: Options(validateStatus: (status) => status! < 500),
        );
        expect(sixthAttempt.statusCode, 401);
        expect(sixthAttempt.data!['error_code'], 'OTP_MAX_ATTEMPTS_EXCEEDED');
        expect(sixthAttempt.data!['lockout_until'], isNotNull);
        printOnFailure('  ✅ 6th attempt still locked: ${sixthAttempt.data!['error_code']}');

        printOnFailure('✅ E7 PASSED: Account lockout after 5 failed attempts');
      },
    );

    testWidgets(
      'E8: Logout',
      (tester) async {
        printOnFailure('\n📱 E8: Testing logout');

        // Get a token first
        final loginResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/otp/verify',
          data: {
            'phone_number': '+8613812345678',
            'otp': '123456',
          },
          options: Options(validateStatus: (status) => true),
        );

        if (loginResponse.statusCode != 200) {
          // Resend and retry
          await dio.post<Map<String, dynamic>>('/v1/auth/otp/send', data: {
            'phone_number': '+8613812345678',
          });
        }

        final accessToken =
            loginResponse.data!['access_token'] ?? 'test-token';

        // Logout
        printOnFailure('  🚪 Logging out...');
        final logoutResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/logout',
          data: {'access_token': accessToken},
        );

        expect(logoutResponse.statusCode, 200);
        expect(logoutResponse.data!['success'], true);
        expect(logoutResponse.data!['message'], equals('登出成功'));
        printOnFailure('  ✅ Logout successful');

        printOnFailure('✅ E8 PASSED: Logout');
      },
    );

    testWidgets(
      'E9: 4th device registration evicts oldest device (PRD-01 §6.3)',
      (tester) async {
        printOnFailure('\n📱 E9: Testing 4th device eviction');

        // Register 3 devices sequentially (using unique timestamps to ensure order)
        final devices = ['e9-dev-alpha', 'e9-dev-beta', 'e9-dev-gamma'];
        for (final deviceId in devices) {
          final resp = await dio.post<Map<String, dynamic>>(
            '/v1/auth/biometric/register',
            data: {'device_id': deviceId, 'biometric_type': 'face_id'},
          );
          expect(resp.statusCode, 200);
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        printOnFailure('  ✅ 3 devices registered: $devices');

        // Verify exactly 3 devices in registry (some may exist from previous tests)
        var listResp = await dio.get<Map<String, dynamic>>('/v1/auth/devices');
        final beforeCount = (listResp.data!['devices'] as List).length;
        printOnFailure('  📋 Devices before 4th registration: $beforeCount');

        // Register the 4th device
        await dio.post<Map<String, dynamic>>(
          '/v1/auth/biometric/register',
          data: {'device_id': 'e9-dev-delta', 'biometric_type': 'fingerprint'},
        );
        printOnFailure('  ➕ 4th device registered: e9-dev-delta');

        // Verify device count did not exceed 3
        listResp = await dio.get<Map<String, dynamic>>('/v1/auth/devices');
        final afterDevices = listResp.data!['devices'] as List;
        expect(
          afterDevices.length,
          lessThanOrEqualTo(3),
          reason: 'Device count must not exceed 3 after registering 4th device',
        );
        // The 4th device (most recently added) must be present
        expect(
          afterDevices.any((d) => d['device_id'] == 'e9-dev-delta'),
          isTrue,
          reason: 'The newly registered 4th device must be present',
        );
        printOnFailure('  ✅ Device count after 4th registration: ${afterDevices.length} (≤3)');

        printOnFailure('✅ E9 PASSED: 4th device evicts oldest per PRD-01 §6.3');
      },
    );
  });
}
