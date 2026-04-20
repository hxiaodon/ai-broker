import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/trading_repository_impl.dart';
import '../domain/entities/order.dart';
import 'trading_ws_notifier.dart';

part 'orders_notifier.g.dart';

@riverpod
class OrdersNotifier extends _$OrdersNotifier {
  StreamSubscription<TradingWsOrderUpdate>? _wsSub;

  @override
  Future<List<Order>> build({OrderStatus? filterStatus}) async {
    ref.onDispose(() => _wsSub?.cancel());
    final orders = await ref
        .watch(tradingRepositoryProvider)
        .getOrders(status: filterStatus);

    // Listen for WS updates and patch the list in-place
    _wsSub?.cancel();
    final wsNotifier = ref.read<TradingWsNotifier>(tradingWsProvider.notifier);
    _wsSub = wsNotifier.orderUpdates.listen(_onOrderUpdate);

    return orders;
  }

  void _onOrderUpdate(TradingWsOrderUpdate update) {
    final current = state.value;
    if (current == null) return;
    final idx = current.indexWhere((o) => o.orderId == update.orderId);
    if (idx == -1) {
      // New order arrived — refresh full list
      ref.invalidateSelf();
      return;
    }
    final updated = current[idx].copyWith(status: update.status);
    state = AsyncData([
      ...current.sublist(0, idx),
      updated,
      ...current.sublist(idx + 1),
    ]);
  }
}
