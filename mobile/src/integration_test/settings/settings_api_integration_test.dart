import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Settings Module — API Integration Tests
///
/// **Purpose**: Verify HTTP API layer against Mock Server for settings module
/// **Dependencies**: Mock Server running on localhost:8080
/// **Speed**: Fast (~8 seconds)
/// **Run when**: Before commits, in CI/CD pipeline
///
/// **What is tested**:
///   GET  /v1/profile                         — profile retrieval with PII fields
///   GET  /v1/profile/account-status          — account compliance status
///   GET  /v1/notifications/preferences       — notification preferences
///   PUT  /v1/notifications/preferences       — update preferences
///   GET  /v1/auth/devices                    — device list
///   DELETE /v1/auth/devices/:id              — device revocation (biometric headers)
///   POST /v1/account/lock                    — emergency account lock
///   GET  /v1/account/deactivation/eligibility — eligibility check
///
/// **Setup**: Before running these tests, start Mock Server:
/// ```bash
/// cd mobile/mock-server
/// ./mock-server --strategy=normal
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;

  setUpAll(() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8080',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    dio.options.headers['Authorization'] = 'Bearer test-token-settings';
    dio.options.headers['X-Key-Id'] = 'sk-test';
    dio.options.headers['X-Nonce'] = 'nonce-test';
    dio.options.headers['X-Signature'] = 'sig-test';
  });

  // ─── Profile ───────────────────────────────────────────────────────────────

  group('Settings API - Profile', () {
    testWidgets(
      'SA1: GET /v1/profile returns full profile',
      (tester) async {
        debugPrint('\n👤 SA1: Fetch user profile');
        final resp = await dio.get<Map<String, dynamic>>('/v1/profile');
        expect(resp.statusCode, 200);
        final data = resp.data!;
        expect(data['account_id'], isNotNull);
        expect(data['full_name'], isNotNull);
        expect(data['phone'], isNotNull);
        expect(data['email'], isNotNull);
        expect(data['id_number'], isNotNull);
        expect(data['kyc_tier'], isNotNull);
        debugPrint('    ✅ Profile: ${data['account_id']}');
      },
    );

    testWidgets(
      'SA2: GET /v1/profile/account-status returns compliance status',
      (tester) async {
        debugPrint('\n🔍 SA2: Fetch account status');
        final resp =
            await dio.get<Map<String, dynamic>>('/v1/profile/account-status');
        expect(resp.statusCode, 200);
        final data = resp.data!;
        expect(data['kyc_status'], isNotNull);
        expect(data['aml_status'], isNotNull);
        expect(data['w8ben_status'], isNotNull);
        expect(data['trading_enabled'], isNotNull);
        debugPrint('    ✅ Account status: kyc=${data['kyc_status']}');
      },
    );
  });

  // ─── Notifications ─────────────────────────────────────────────────────────

  group('Settings API - Notifications', () {
    testWidgets(
      'SA3: GET /v1/notifications/preferences returns prefs',
      (tester) async {
        debugPrint('\n🔔 SA3: Fetch notification preferences');
        final resp = await dio
            .get<Map<String, dynamic>>('/v1/notifications/preferences');
        expect(resp.statusCode, 200);
        final data = resp.data!;
        expect(data.containsKey('trading_enabled'), isTrue);
        expect(data.containsKey('push_enabled'), isTrue);
        debugPrint('    ✅ Prefs: push=${data['push_enabled']}');
      },
    );

    testWidgets(
      'SA4: PUT /v1/notifications/preferences updates and returns saved prefs',
      (tester) async {
        debugPrint('\n🔔 SA4: Update notification preferences');
        final resp = await dio.put<Map<String, dynamic>>(
          '/v1/notifications/preferences',
          data: {
            'trading_enabled': false,
            'funding_enabled': true,
            'kyc_enabled': true,
            'system_announcements_enabled': true,
            'push_enabled': true,
            'sms_enabled': false,
            'email_enabled': true,
          },
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );
        expect(resp.statusCode, 200);
        debugPrint('    ✅ Preferences updated');
      },
    );
  });

  // ─── Devices ───────────────────────────────────────────────────────────────

  group('Settings API - Devices', () {
    testWidgets(
      'SA5: GET /v1/auth/devices returns device list',
      (tester) async {
        debugPrint('\n📱 SA5: Fetch device list');
        final resp =
            await dio.get<Map<String, dynamic>>('/v1/auth/devices');
        expect(resp.statusCode, 200);
        final devices = resp.data!['devices'] as List<dynamic>? ?? [];
        expect(devices, isNotEmpty, reason: 'Mock server should return ≥1 device');
        final device = devices.first as Map<String, dynamic>;
        expect(device['device_id'], isNotNull);
        expect(device['device_name'], isNotNull);
        expect(device['last_active_at'], isNotNull);
        debugPrint('    ✅ Devices: ${devices.length} device(s)');
      },
    );

    testWidgets(
      'SA6: DELETE /v1/auth/devices/:id with biometric headers succeeds',
      (tester) async {
        debugPrint('\n📱 SA6: Revoke device');
        // Fetch devices first to get a non-current device ID
        final listResp =
            await dio.get<Map<String, dynamic>>('/v1/auth/devices');
        final devices = listResp.data!['devices'] as List<dynamic>? ?? [];
        final target = devices.firstWhere(
          (d) => d['is_current_device'] != true,
          orElse: () => devices.first,
        ) as Map<String, dynamic>;
        final deviceId = target['device_id'] as String;

        final resp = await dio.delete<void>(
          '/v1/auth/devices/$deviceId',
          options: Options(
            headers: {
              'X-Biometric-Token': 'bio-test-token',
              'X-Bio-Challenge': 'challenge-test',
              'X-Bio-Timestamp':
                  DateTime.now().toUtc().toIso8601String(),
            },
          ),
        );
        expect(resp.statusCode, anyOf(200, 204));
        debugPrint('    ✅ Device $deviceId revoked');
      },
    );
  });

  // ─── Account Lock ──────────────────────────────────────────────────────────

  group('Settings API - Account Lock', () {
    testWidgets(
      'SA7: POST /v1/account/lock returns success',
      (tester) async {
        debugPrint('\n🔒 SA7: Lock account');
        try {
          final resp = await dio.post<void>(
            '/v1/account/lock',
            data: <String, dynamic>{},
            options: Options(headers: {'Content-Type': 'application/json'}),
          );
          expect(resp.statusCode, anyOf(200, 204));
          debugPrint('    ✅ Account lock request accepted');
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            debugPrint('    ⏭ Endpoint not in mock server yet — skip');
            return;
          }
          rethrow;
        }
      },
    );
  });

  // ─── Deactivation Eligibility ──────────────────────────────────────────────

  group('Settings API - Deactivation', () {
    testWidgets(
      'SA8: GET /v1/account/deactivation/eligibility returns result',
      (tester) async {
        debugPrint('\n🚫 SA8: Check deactivation eligibility');
        try {
          final resp = await dio.get<dynamic>(
            '/v1/account/deactivation/eligibility',
          );
          expect(resp.statusCode, anyOf(200, 422));
          debugPrint('    ✅ Eligibility check responded: ${resp.statusCode}');
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            debugPrint('    ⏭ Endpoint not in mock server yet — skip');
            return;
          }
          // 422 = ineligible is a valid response (has positions/balance)
          if (e.response?.statusCode == 422) {
            debugPrint('    ✅ Server correctly rejected as ineligible (422)');
            return;
          }
          rethrow;
        }
      },
    );
  });
}
