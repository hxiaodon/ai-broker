import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/device_info_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/security/bio_challenge_service.dart';
import '../../../core/security/session_key_service.dart';
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
  const factory OrderSubmitState.success({required String orderId}) = _Success;
  const factory OrderSubmitState.error({required String message}) = _Error;
}

@riverpod
class OrderSubmitNotifier extends _$OrderSubmitNotifier {
  final _localAuth = LocalAuthentication();

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
    state = const OrderSubmitState.awaitingBiometric();

    String biometricToken = '';
    String bioChallenge = '';
    String bioTimestamp = '';

    if (biometricEnabled) {
      try {
        // Fetch challenge before prompting — 30s TTL starts now
        bioChallenge =
            await ref.read(bioChallengeServiceProvider).fetchChallenge();

        final authenticated = await _localAuth.authenticate(
          localizedReason: side == OrderSide.buy
              ? '确认买入 $qty 股 $symbol'
              : '确认卖出 $qty 股 $symbol',
          biometricOnly: true,
        );
        if (!authenticated) {
          state = const OrderSubmitState.error(message: '生物识别验证失败，请重试');
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
        return;
      }
    }

    state = const OrderSubmitState.submitting();
    final idempotencyKey = const Uuid().v4();

    try {
      final order = await ref.read(tradingRepositoryProvider).submitOrder(
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
      state = OrderSubmitState.success(orderId: order.orderId);
    } on Object catch (e) {
      AppLogger.warning('Order submit failed: $e');
      state = OrderSubmitState.error(message: e.toString());
    }
  }

  void reset() => state = const OrderSubmitState.idle();
}
