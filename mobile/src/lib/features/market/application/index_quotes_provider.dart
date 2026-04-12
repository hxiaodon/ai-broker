import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../data/market_data_repository_impl.dart';
import '../domain/entities/quote.dart';

part 'index_quotes_provider.g.dart';

/// Provides real-time quotes for market index ETFs (SPY, QQQ, DIA).
///
/// Independent of [watchlistProvider] to avoid loading delays.
/// These are always fetched on app startup for the index banner.
@riverpod
Future<List<Quote>> indexQuotes(Ref ref) async {
  final repo = ref.watch(marketDataRepositoryProvider);

  try {
    final symbols = ['SPY', 'QQQ', 'DIA'];
    AppLogger.debug('IndexQuotesProvider: fetching ${symbols.length} index quotes');

    // Fetch all three at once
    final batch = await repo.getQuotes(symbols);
    final quotes = <Quote>[
      for (final s in symbols)
        if (batch.containsKey(s))
          batch[s]!
    ];

    AppLogger.info('IndexQuotesProvider: loaded ${quotes.length} index quotes');
    return quotes;
  } catch (e, stack) {
    AppLogger.error(
      'IndexQuotesProvider: failed to load index quotes',
      error: e,
      stackTrace: stack,
    );
    rethrow;
  }
}
