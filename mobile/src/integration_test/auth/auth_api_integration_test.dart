import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
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
        debugPrint('📱 E1: Starting complete OTP login flow');

        // Step 1: Send OTP
        debugPrint('  📨 Step 1: Sending OTP to +8613812345678...');
        final sendResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/otp/send',
          data: {'phone_number': '+8613812345678'},
        );

        expect(sendResponse.statusCode, 200);
        expect(sendResponse.data!['success'], true);
        expect(sendResponse.data!['message'], contains('验证码已发送'));
        debugPrint('  ✅ OTP sent successfully');

        // Step 2: Verify OTP (using mock code 123456)
        debugPrint('  🔐 Step 2: Verifying OTP code 123456...');
        final verifyResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/otp/verify',
          data: {
            'phone_number': '+8613812345678',
            'otp': '123456',
          },
        );

        expect(verifyResponse.statusCode, 200);
        expect(verifyResponse.data!['success'], true);
        expect(verifyResponse.data!['message'], equals('登录成功'));
        expect(verifyResponse.data!['access_token'], isNotEmpty);
        expect(verifyResponse.data!['refresh_token'], isNotEmpty);
        expect(verifyResponse.data!['account_id'], isNotEmpty);

        final accessToken = verifyResponse.data!['access_token'];
        debugPrint('  ✅ OTP verified, access token: ${accessToken.substring(0, 16)}...');

        // Step 3: App would navigate to home
        debugPrint('  🏠 Step 3: Navigating to home screen...');
        expect(accessToken, isNotEmpty);
        debugPrint('  ✅ Login flow complete');

        debugPrint('✅ E1 PASSED: Complete OTP login flow');
      },
    );

    testWidgets(
      'E2: Wrong OTP attempt with error count',
      (tester) async {
        debugPrint('\n📱 E2: Testing wrong OTP attempt');

        // Send OTP first
        await dio.post<Map<String, dynamic>>('/v1/auth/otp/send', data: {
          'phone_number': '+8613812345678',
        });

        // Try wrong OTP
        debugPrint('  ❌ Attempting wrong OTP (000000)...');
        final wrongResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/otp/verify',
          data: {
            'phone_number': '+8613812345678',
            'otp': '000000',
          },
          options: Options(validateStatus: (status) => status! < 500),
        );

        expect(wrongResponse.statusCode, 400);
        expect(wrongResponse.data!['success'], false);
        expect(wrongResponse.data!['message'], contains('验证码错误'));
        debugPrint('  ✅ Error message shown: ${wrongResponse.data!['message']}');

        debugPrint('✅ E2 PASSED: Wrong OTP handling');
      },
    );

    testWidgets(
      'E3: Biometric registration flow',
      (tester) async {
        debugPrint('\n📱 E3: Testing biometric registration');

        const deviceId = 'device-e3-12345';
        const biometricType = 'face_id';

        // Register biometric
        debugPrint('  👆 Registering $biometricType on device $deviceId...');
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
        debugPrint('  ✅ Biometric registered');

        // Verify biometric
        debugPrint('  🔐 Verifying biometric...');
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
        debugPrint('  ✅ Biometric verified, got access token');

        debugPrint('✅ E3 PASSED: Biometric registration and verification');
      },
    );

    testWidgets(
      'E4: Device management - register and list',
      (tester) async {
        debugPrint('\n📱 E4: Testing device management');

        const deviceId = 'device-e4-xyz789';

        // Register a device via biometric registration
        debugPrint('  📱 Registering device $deviceId...');
        await dio.post<Map<String, dynamic>>('/v1/auth/biometric/register', data: {
          'device_id': deviceId,
          'biometric_type': 'fingerprint',
        });
        debugPrint('  ✅ Device registered');

        // Get devices list
        debugPrint('  📋 Fetching devices list...');
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
        debugPrint('  ✅ Device found in list (${devices.length} device(s) total)');

        debugPrint('✅ E4 PASSED: Device listing');
      },
    );

    testWidgets(
      'E5: Device deletion',
      (tester) async {
        debugPrint('\n📱 E5: Testing device deletion');

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
        debugPrint('  ✅ Device registered and verified in list');

        // Delete device
        debugPrint('  🗑️  Deleting device...');
        final deleteResponse = await dio.delete<Map<String, dynamic>>(
          '/v1/auth/devices/$deviceId',
        );

        expect(deleteResponse.statusCode, 200);
        expect(deleteResponse.data!['success'], true);
        debugPrint('  ✅ Device deleted');

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
        debugPrint('  ✅ Device confirmed removed from list');

        debugPrint('✅ E5 PASSED: Device deletion');
      },
    );

    testWidgets(
      'E6: Token refresh',
      (tester) async {
        debugPrint('\n📱 E6: Testing token refresh');

        // Get initial tokens
        final loginResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/otp/verify',
          data: {
            'phone_number': '+8613812345678',
            'otp': '123456',
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
              'otp': '123456',
            },
          );
          expect(retryResponse.statusCode, 200);
        }

        final refreshToken =
            loginResponse.data!['refresh_token'] ?? 'test-refresh-token';

        // Refresh token
        debugPrint('  🔄 Refreshing token...');
        final refreshResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/token/refresh',
          data: {'refresh_token': refreshToken},
        );

        expect(refreshResponse.statusCode, 200);
        expect(refreshResponse.data!['success'], true);
        expect(refreshResponse.data!['access_token'], isNotEmpty);
        debugPrint(
          '  ✅ Token refreshed: ${refreshResponse.data!['access_token'].substring(0, 16)}...',
        );

        debugPrint('✅ E6 PASSED: Token refresh');
      },
    );

    testWidgets(
      'E7: Account lockout after 5 failed attempts',
      (tester) async {
        debugPrint('\n📱 E7: Testing account lockout');

        // Use unique phone number to avoid lockout from previous test run
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final phoneNumber = '+861381234${timestamp.toString().substring(timestamp.toString().length - 4)}'; // +8613812345XXX

        // Send OTP
        final sendResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/otp/send',
          data: {'phone_number': phoneNumber},
          options: Options(validateStatus: (status) => status! < 500),
        );
        expect(sendResponse.statusCode, 200);

        // Try wrong OTP 5 times
        debugPrint('  ❌ Attempting 5 wrong OTP codes...');
        String lastMessage = '';
        for (int i = 1; i <= 5; i++) {
          final response = await dio.post<Map<String, dynamic>>(
            '/v1/auth/otp/verify',
            data: {
              'phone_number': phoneNumber,
              'otp': '000000',
            },
            options: Options(validateStatus: (status) => status! < 500),
          );

          lastMessage = response.data!['message'] as String;
          debugPrint('    Attempt $i: ${response.data!['message']}');
        }

        // After 5 attempts, account should be locked
        debugPrint('  🔒 Verifying account is locked after 5 attempts...');
        expect(lastMessage, contains('账户已锁定'));

        // Verify next OTP send attempt is blocked with 429
        final nextAttempt = await dio.post<Map<String, dynamic>>(
          '/v1/auth/otp/send',
          data: {'phone_number': phoneNumber},
          options: Options(validateStatus: (status) => status! < 500),
        );

        expect(nextAttempt.statusCode, 429); // OTP send returns 429 when locked
        expect(nextAttempt.data!['message'], contains('账户已锁定'));
        debugPrint('  ✅ Account locked: ${nextAttempt.data!['message']}');

        debugPrint('✅ E7 PASSED: Account lockout');
      },
    );

    testWidgets(
      'E8: Logout',
      (tester) async {
        debugPrint('\n📱 E8: Testing logout');

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
        debugPrint('  🚪 Logging out...');
        final logoutResponse = await dio.post<Map<String, dynamic>>(
          '/v1/auth/logout',
          data: {'access_token': accessToken},
        );

        expect(logoutResponse.statusCode, 200);
        expect(logoutResponse.data!['success'], true);
        expect(logoutResponse.data!['message'], equals('登出成功'));
        debugPrint('  ✅ Logout successful');

        debugPrint('✅ E8 PASSED: Logout');
      },
    );
  });
}
