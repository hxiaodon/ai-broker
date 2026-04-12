import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../data/market_data_repository_impl.dart';
import '../domain/entities/quote.dart';

/// Provides real-time quotes for market index ETFs (SPY, QQQ, DIA).
///
/// Independent of [watchlistProvider] to avoid loading delays.
/// These are always fetched on app startup for the index banner.
final indexQuotesProvider = FutureProvider<Map<String, Quote>>((ref) async {
  final repo = ref.watch(marketDataRepositoryProvider);

  final symbols = ['SPY', 'QQQ', 'DIA'];
  AppLogger.debug('IndexQuotesProvider: fetching ${symbols.length} index quotes');

  try {
    // Fetch all three at once — returns Map<String, dynamic> with Quote values
    final batch = await repo.getQuotes(symbols);
    AppLogger.debug('IndexQuotesProvider: batch returned, type=${batch.runtimeType}, entries=${batch.length}');

    // Cast values to Quote (they are already domain objects from repo)
    final quotes = <String, Quote>{};
    for (final entry in batch.entries) {
      AppLogger.debug('IndexQuotesProvider: checking entry ${entry.key}, valueType=${entry.value.runtimeType}');
      if (entry.value is Quote) {
        quotes[entry.key] = entry.value as Quote;
        AppLogger.debug('IndexQuotesProvider: added ${entry.key} to quotes');
      } else {
        AppLogger.warning('IndexQuotesProvider: entry ${entry.key} is not Quote type, got ${entry.value.runtimeType}');
      }
    }

    AppLogger.info('IndexQuotesProvider: loaded ${quotes.length} index quotes (SPY=${quotes.containsKey("SPY")}, QQQ=${quotes.containsKey("QQQ")}, DIA=${quotes.containsKey("DIA")})');
    return quotes;
  } catch (e, stack) {
    AppLogger.error(
      'IndexQuotesProvider: failed to load index quotes',
      error: e,
      stackTrace: stack,
    );
    rethrow;
  }
});
