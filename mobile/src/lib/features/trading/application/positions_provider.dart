import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/trading_repository_impl.dart';
import '../domain/entities/position.dart';
import 'trading_ws_notifier.dart';

part 'positions_provider.g.dart';

@riverpod
class PositionsNotifier extends _$PositionsNotifier {
  StreamSubscription<TradingWsPositionUpdate>? _wsSub;

  @override
  Future<List<Position>> build() async {
    ref.onDispose(() => _wsSub?.cancel());
    final positions =
        await ref.watch(tradingRepositoryProvider).getPositions();

    _wsSub?.cancel();
    final wsNotifier = ref.read<TradingWsNotifier>(tradingWsProvider.notifier);
    _wsSub = wsNotifier.positionUpdates.listen(_onPositionUpdate);

    return positions;
  }

  void _onPositionUpdate(TradingWsPositionUpdate update) {
    final current = state.value;
    if (current == null) return;
    final idx =
        current.indexWhere((p) => p.symbol == update.position.symbol);
    if (idx == -1) {
      state = AsyncData([...current, update.position]);
      return;
    }
    state = AsyncData([
      ...current.sublist(0, idx),
      update.position,
      ...current.sublist(idx + 1),
    ]);
  }
}
