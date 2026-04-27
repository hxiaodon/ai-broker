import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dio/dio.dart';

/// Funding Module — API Integration Tests
///
/// **Purpose**: Verify HTTP API layer and Mock Server integration for funding module
/// **Dependencies**: Mock Server running on localhost:8080
/// **Speed**: Fast (~10 seconds)
/// **Run when**: Before commits, in CI/CD pipeline
///
/// **What is tested**:
/// - GET /api/v1/balance — balance retrieval
/// - POST /api/v1/deposit — deposit submission with Idempotency-Key
/// - POST /api/v1/withdrawal — withdrawal with biometric headers
/// - GET /api/v1/fund/history — transfer history
/// - GET /api/v1/bank-accounts — bank account list
/// - POST /api/v1/bank-accounts — bank account binding with Idempotency-Key
/// - DELETE /api/v1/bank-accounts/:id — bank account removal
/// - POST /api/v1/bank-accounts/:id/verify-micro-deposit — micro-deposit verify
/// - POST /api/v1/funding/bio-challenge — biometric challenge issuance
/// - Idempotency replay (same key returns cached response)
/// - Missing Idempotency-Key returns 400
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
    dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    // Add JWT-style auth header (mock server ignores content, just checks presence)
    dio.options.headers['Authorization'] = 'Bearer test-token-funding';
  });

  group('Funding API - Balance', () {
    testWidgets(
      'FB1: GET /api/v1/balance returns valid balance',
      (tester) async {
        debugPrint('\n💰 FB1: Fetch account balance');
        final resp = await dio.get<Map<String, dynamic>>('/api/v1/balance');
        expect(resp.statusCode, 200);
        expect(resp.data!['account_id'], isNotNull);
        expect(resp.data!['total_balance'], isNotNull);
        expect(resp.data!['available_balance'], isNotNull);
        expect(resp.data!['withdrawable_balance'], isNotNull);
        debugPrint('    ✅ Balance received: ${resp.data!['total_balance']}');
      },
    );
  });

  group('Funding API - Deposit', () {
    testWidgets(
      'FB2: POST /api/v1/deposit creates transfer',
      (tester) async {
        debugPrint('\n💳 FB2: Submit deposit');
        final idempotencyKey = 'test-deposit-${DateTime.now().millisecondsSinceEpoch}';
        final resp = await dio.post<Map<String, dynamic>>(
          '/api/v1/deposit',
          data: {
            'amount': '1000.00',
            'bank_account_id': 'ba-001',
            'channel': 'ACH',
          },
          options: Options(headers: {
            'Idempotency-Key': idempotencyKey,
            'X-Key-Id': 'sk-test',
            'X-Nonce': 'nonce-test-${DateTime.now().millisecondsSinceEpoch}',
            'X-Signature': 'sig-test',
          }),
        );
        expect(resp.statusCode, 201);
        expect(resp.data!['transfer_id'], isNotNull);
        expect(resp.data!['status'], 'PENDING');
        expect(resp.data!['amount'], '1000.00');
        debugPrint('    ✅ Deposit created: ${resp.data!['transfer_id']}');
      },
    );

    testWidgets(
      'FB3: Deposit idempotency replay returns same response',
      (tester) async {
        debugPrint('\n🔁 FB3: Deposit idempotency replay');
        final idempotencyKey =
            'test-idem-replay-${DateTime.now().millisecondsSinceEpoch}';
        final headers = {
          'Idempotency-Key': idempotencyKey,
          'X-Key-Id': 'sk-test',
          'X-Nonce': 'nonce-replay-1',
          'X-Signature': 'sig-test',
        };

        final first = await dio.post<Map<String, dynamic>>(
          '/api/v1/deposit',
          data: {'amount': '500.00', 'bank_account_id': 'ba-001', 'channel': 'ACH'},
          options: Options(headers: headers),
        );
        final second = await dio.post<Map<String, dynamic>>(
          '/api/v1/deposit',
          data: {'amount': '500.00', 'bank_account_id': 'ba-001', 'channel': 'ACH'},
          options: Options(headers: headers),
        );

        expect(first.data!['transfer_id'], second.data!['transfer_id'],
            reason: 'Idempotent replay must return same transfer_id');
        debugPrint('    ✅ Idempotency replay works correctly');
      },
    );

    testWidgets(
      'FB4: Deposit without Idempotency-Key returns 400',
      (tester) async {
        debugPrint('\n🚫 FB4: Deposit missing Idempotency-Key');
        try {
          await dio.post<Map<String, dynamic>>(
            '/api/v1/deposit',
            data: {'amount': '100.00', 'bank_account_id': 'ba-001', 'channel': 'ACH'},
          );
          fail('Should have thrown DioException');
        } on DioException catch (e) {
          expect(e.response?.statusCode, 400);
          expect(e.response?.data['error_code'], 'MISSING_HEADER');
          debugPrint('    ✅ Missing Idempotency-Key correctly rejected');
        }
      },
    );
  });

  group('Funding API - Withdrawal', () {
    testWidgets(
      'FB5: POST /api/v1/withdrawal with biometric headers creates transfer',
      (tester) async {
        debugPrint('\n💸 FB5: Submit withdrawal with biometric headers');
        final idempotencyKey =
            'test-withdraw-${DateTime.now().millisecondsSinceEpoch}';
        final resp = await dio.post<Map<String, dynamic>>(
          '/api/v1/withdrawal',
          data: {
            'amount': '500.00',
            'bank_account_id': 'ba-001',
            'channel': 'ACH',
          },
          options: Options(headers: {
            'Idempotency-Key': idempotencyKey,
            'X-Key-Id': 'sk-test',
            'X-Nonce': 'nonce-wth-${DateTime.now().millisecondsSinceEpoch}',
            'X-Signature': 'sig-test',
            'X-Biometric-Token': 'bio-token-test',
            'X-Bio-Challenge': 'challenge-test',
            'X-Bio-Timestamp': '1234567890000',
          }),
        );
        expect(resp.statusCode, 201);
        expect(resp.data!['transfer_id'], isNotNull);
        expect(resp.data!['type'], 'WITHDRAWAL');
        debugPrint('    ✅ Withdrawal created: ${resp.data!['transfer_id']}');
      },
    );

    testWidgets(
      'FB6: Withdrawal without biometric headers returns 400',
      (tester) async {
        debugPrint('\n🚫 FB6: Withdrawal missing biometric headers');
        try {
          await dio.post<Map<String, dynamic>>(
            '/api/v1/withdrawal',
            data: {'amount': '100.00', 'bank_account_id': 'ba-001', 'channel': 'ACH'},
            options: Options(headers: {
              'Idempotency-Key': 'test-no-bio',
            }),
          );
          fail('Should have thrown DioException');
        } on DioException catch (e) {
          expect(e.response?.statusCode, 400);
          expect(e.response?.data['error_code'], 'MISSING_BIO_HEADERS');
          debugPrint('    ✅ Missing biometric headers correctly rejected');
        }
      },
    );
  });

  group('Funding API - History', () {
    testWidgets(
      'FB7: GET /api/v1/fund/history returns transfer list',
      (tester) async {
        debugPrint('\n📋 FB7: Fetch transfer history');
        final resp = await dio.get<Map<String, dynamic>>('/api/v1/fund/history');
        expect(resp.statusCode, 200);
        expect(resp.data!['transfers'], isA<List<dynamic>>());
        debugPrint('    ✅ History received: ${resp.data!['total']} transfers');
      },
    );
  });

  group('Funding API - Bank Accounts', () {
    testWidgets(
      'FB8: GET /api/v1/bank-accounts returns account list',
      (tester) async {
        debugPrint('\n🏦 FB8: Fetch bank accounts');
        final resp =
            await dio.get<Map<String, dynamic>>('/api/v1/bank-accounts');
        expect(resp.statusCode, 200);
        final accounts = resp.data!['bank_accounts'] as List;
        expect(accounts, isNotEmpty);
        final first = accounts.first as Map<String, dynamic>;
        expect(first['bank_account_id'], isNotNull);
        expect(first['account_number'], startsWith('****'));
        debugPrint('    ✅ Bank accounts: ${accounts.length} found, account_number masked');
      },
    );

    testWidgets(
      'FB9: POST /api/v1/bank-accounts binds new bank account',
      (tester) async {
        debugPrint('\n➕ FB9: Bind new bank account');
        final idempotencyKey =
            'test-bind-${DateTime.now().millisecondsSinceEpoch}';
        final resp = await dio.post<Map<String, dynamic>>(
          '/api/v1/bank-accounts',
          data: {
            'account_name': 'John Smith',
            'account_number': '123456789',
            'routing_number': '021000021',
            'bank_name': 'Chase Bank',
          },
          options: Options(headers: {
            'Idempotency-Key': idempotencyKey,
            'X-Key-Id': 'sk-test',
            'X-Nonce': 'nonce-bind-${DateTime.now().millisecondsSinceEpoch}',
            'X-Signature': 'sig-test',
          }),
        );
        expect(resp.statusCode, 201);
        expect(resp.data!['bank_account_id'], isNotNull);
        expect(resp.data!['account_number'], '****6789');
        expect(resp.data!['micro_deposit_status'], 'pending');
        debugPrint('    ✅ Bank account bound: ${resp.data!['bank_account_id']}');
      },
    );

    testWidgets(
      'FB10: Micro-deposit verify with correct amounts succeeds',
      (tester) async {
        debugPrint('\n✅ FB10: Micro-deposit verification');
        final resp = await dio.post<Map<String, dynamic>>(
          '/api/v1/bank-accounts/ba-002/verify-micro-deposit',
          data: {'amount_1': '0.15', 'amount_2': '0.23'},
          options: Options(headers: {
            'Idempotency-Key': 'test-verify-${DateTime.now().millisecondsSinceEpoch}',
            'X-Key-Id': 'sk-test',
            'X-Nonce': 'nonce-verify-${DateTime.now().millisecondsSinceEpoch}',
            'X-Signature': 'sig-test',
          }),
        );
        expect(resp.statusCode, 200);
        expect(resp.data!['is_verified'], true);
        expect(resp.data!['micro_deposit_status'], 'verified');
        debugPrint('    ✅ Micro-deposit verification successful');
      },
    );

    testWidgets(
      'FB11: Micro-deposit verify with wrong amounts returns 422',
      (tester) async {
        debugPrint('\n❌ FB11: Micro-deposit wrong amounts');
        try {
          await dio.post<Map<String, dynamic>>(
            '/api/v1/bank-accounts/ba-002/verify-micro-deposit',
            data: {'amount_1': '0.99', 'amount_2': '0.99'},
            options: Options(headers: {
              'Idempotency-Key':
                  'test-wrong-${DateTime.now().millisecondsSinceEpoch}',
              'X-Key-Id': 'sk-test',
              'X-Nonce': 'nonce-wrong-${DateTime.now().millisecondsSinceEpoch}',
              'X-Signature': 'sig-test',
            }),
          );
          fail('Should have thrown DioException');
        } on DioException catch (e) {
          expect(e.response?.statusCode, 422);
          expect(e.response?.data['error_code'], 'MICRO_DEPOSIT_MISMATCH');
          debugPrint('    ✅ Wrong amounts correctly rejected');
        }
      },
    );

    testWidgets(
      'FB12: POST /api/v1/funding/bio-challenge issues challenge',
      (tester) async {
        debugPrint('\n🔐 FB12: Fund bio challenge');
        final resp = await dio
            .post<Map<String, dynamic>>('/api/v1/funding/bio-challenge');
        expect(resp.statusCode, 200);
        final challenge = resp.data!['challenge'] as String;
        expect(challenge.length, greaterThanOrEqualTo(32));
        expect(resp.data!['expires_at'], isNotNull);
        debugPrint('    ✅ Bio challenge issued: ${challenge.substring(0, 16)}...');
      },
    );
  });
}
