import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/entities/order.dart';

part 'recent_order_banner_provider.g.dart';

/// Minimal snapshot of a just-submitted order, used to render a one-shot
/// banner + highlight on [OrderListScreen] after the user is redirected.
class RecentOrderInfo {
  const RecentOrderInfo({
    required this.orderId,
    required this.symbol,
    required this.side,
    required this.orderType,
    required this.qty,
    required this.submittedAt,
  });

  final String orderId;
  final String symbol;
  final OrderSide side;
  final OrderType orderType;
  final int qty;
  final DateTime submittedAt;
}

/// Holds the most recently submitted order for cross-screen feedback.
/// Consumers dismiss it via [RecentOrderBanner.clear].
@Riverpod(keepAlive: true)
class RecentOrderBanner extends _$RecentOrderBanner {
  @override
  RecentOrderInfo? build() => null;

  void set(RecentOrderInfo info) => state = info;

  void clear() => state = null;
}
