import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/device_info_service.dart';
import '../../../core/auth/local_auth_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/security/bio_challenge_service.dart';
import '../../../core/security/session_key_service.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/trading_repository_impl.dart';
import '../domain/entities/order.dart';
import 'orders_notifier.dart';

part 'order_submit_notifier.freezed.dart';
part 'order_submit_notifier.g.dart';

@freezed
sealed class OrderSubmitState with _$OrderSubmitState {
  const factory OrderSubmitState.idle() = _Idle;
  const factory OrderSubmitState.awaitingBiometric() = _AwaitingBiometric;
  const factory OrderSubmitState.submitting() = _Submitting;
  const factory OrderSubmitState.success({
    required String orderId,
    // Correlation ID from X-Request-ID header — links client log to server
    // audit record (SEC Rule 17a-4 traceability requirement).
    String? requestId,
  }) = _Success;
  const factory OrderSubmitState.error({required String message}) = _Error;
}

@riverpod
class OrderSubmitNotifier extends _$OrderSubmitNotifier {
  // Idempotency key is generated once per submit attempt and persisted until
  // reset() is called. This ensures network-timeout retries reuse the same key
  // and don't create duplicate orders.
  String? _pendingIdempotencyKey;

  @override
  OrderSubmitState build() => const OrderSubmitState.idle();

  Future<void> submit({
    required String symbol,
    required String market,
    required OrderSide side,
    required OrderType orderType,
    required int qty,
    Decimal? limitPrice,
    required OrderValidity validity,
    required bool extendedHours,
    required bool biometricEnabled,
  }) async {
    // C2: idle guard — reject concurrent calls before the first async gap.
    // Protects against rapid double-tap on the confirm button.
    if (state != const OrderSubmitState.idle()) return;

    // C2: generate idempotency key before any await so all retries within
    // the same submit attempt reuse the same key.
    _pendingIdempotencyKey ??= const Uuid().v4();

    // Prevent autoDispose from firing mid-submit (can have 5+ async gaps in
    // the biometric path). keepAlive is released at the end of this method.
    final keepAlive = ref.keepAlive();
    state = const OrderSubmitState.awaitingBiometric();

    String biometricToken = '';
    String bioChallenge = '';
    String bioTimestamp = '';

    if (biometricEnabled) {
      try {
        // Fetch challenge before prompting — 30s TTL starts now
        bioChallenge =
            await ref.read(bioChallengeServiceProvider).fetchChallenge();

        final authenticated = await ref
            .read(localAuthServiceProvider)
            .authenticate(
              localizedReason: side == OrderSide.buy
                  ? '确认买入 $qty 股 $symbol'
                  : '确认卖出 $qty 股 $symbol',
            );
        if (!authenticated) {
          state = const OrderSubmitState.error(message: '生物识别验证失败，请重试');
          keepAlive.close();
          return;
        }

        bioTimestamp =
            DateTime.now().toUtc().millisecondsSinceEpoch.toString();
        final sessionKey =
            await ref.read(sessionKeyServiceProvider).getSessionKey();
        final deviceId =
            await ref.read(deviceInfoServiceProvider).getDeviceId();
        final actionHash = BioChallengeService.computeActionHash(
          side: side.name,
          symbol: symbol,
          qty: qty,
          price: limitPrice?.toString() ?? '',
          accountId: ref.read(authProvider).maybeWhen(
                authenticated: (accountId, _, _) => accountId,
                orElse: () => '',
              ),
        );
        biometricToken = ref
            .read(bioChallengeServiceProvider)
            .computeBioToken(
              sessionSecret: sessionKey.secret,
              challenge: bioChallenge,
              timestamp: bioTimestamp,
              deviceId: deviceId,
              actionHash: actionHash,
            );
      } on Object catch (e) {
        AppLogger.warning('Biometric auth failed: $e');
        state = const OrderSubmitState.error(message: '生物识别不可用，请重试');
        keepAlive.close();
        return;
      }
    }

    state = const OrderSubmitState.submitting();
    // Key already generated before first await — safe to use directly.
    final idempotencyKey = _pendingIdempotencyKey!;

    try {
      final (order, requestId) =
          await ref.read(tradingRepositoryProvider).submitOrder(
                symbol: symbol,
                market: market,
                side: side,
                orderType: orderType,
                qty: qty,
                limitPrice: limitPrice,
                validity: validity,
                extendedHours: extendedHours,
                idempotencyKey: idempotencyKey,
                biometricToken: biometricToken,
                bioChallenge: bioChallenge,
                bioTimestamp: bioTimestamp,
              );

      ref.invalidate(ordersProvider);
      _pendingIdempotencyKey = null; // order reached terminal state
      state = OrderSubmitState.success(orderId: order.orderId, requestId: requestId);
    } on BusinessException catch (e) {
      AppLogger.warning('Order submit business error: ${e.errorCode}');
      state = OrderSubmitState.error(message: _mapBusinessError(e.errorCode) ?? e.message);
    } on NetworkException catch (_) {
      state = const OrderSubmitState.error(message: '网络异常，请检查网络后重试');
    } on AuthException catch (_) {
      state = const OrderSubmitState.error(message: '会话已过期，请重新登录');
    } on ServerException catch (_) {
      state = const OrderSubmitState.error(message: '服务暂时不可用，请稍后重试');
    } on Object catch (e) {
      AppLogger.warning('Order submit failed: $e');
      state = const OrderSubmitState.error(message: '提交委托失败，请稍后重试');
    } finally {
      keepAlive.close();
    }
  }

  void reset() {
    _pendingIdempotencyKey = null;
    state = const OrderSubmitState.idle();
  }

  static String? _mapBusinessError(String? code) => switch (code) {
        'INSUFFICIENT_BUYING_POWER' => '可用资金不足',
        'MARKET_CLOSED' => '当前市场已收盘',
        'SYMBOL_NOT_TRADABLE' => '该股票暂不可交易',
        'ORDER_SIZE_EXCEEDED' => '委托数量超出限额',
        'PRICE_OUT_OF_RANGE' => '委托价格超出范围',
        'DUPLICATE_ORDER' => '重复委托，请勿重复提交',
        'NONCE_ALREADY_USED' => '请求已被处理，请勿重复提交',
        _ => null,
      };
}
