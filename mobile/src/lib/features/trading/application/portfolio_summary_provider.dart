import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/trading_repository_impl.dart';
import '../domain/entities/portfolio_summary.dart';
import 'trading_ws_notifier.dart';

part 'portfolio_summary_provider.g.dart';

@riverpod
class PortfolioSummaryNotifier extends _$PortfolioSummaryNotifier {
  StreamSubscription<TradingWsPortfolioUpdate>? _wsSub;

  @override
  Future<PortfolioSummary> build() async {
    ref.onDispose(() => _wsSub?.cancel());
    final summary =
        await ref.watch(tradingRepositoryProvider).getPortfolioSummary();

    _wsSub?.cancel();
    final wsNotifier = ref.read<TradingWsNotifier>(tradingWsProvider.notifier);
    _wsSub = wsNotifier.portfolioUpdates
        .listen((TradingWsPortfolioUpdate update) =>
            state = AsyncData(update.summary));

    return summary;
  }
}
