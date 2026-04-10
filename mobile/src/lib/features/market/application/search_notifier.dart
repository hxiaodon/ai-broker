import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';
import '../data/market_data_repository_impl.dart';
import '../domain/entities/search_result.dart';

part 'search_notifier.freezed.dart';
part 'search_notifier.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kDebounceMs = 300;
const _kMaxHistory = 10;
const _kHistoryKey = 'search_history_symbols';

// ─────────────────────────────────────────────────────────────────────────────
// SearchState
// ─────────────────────────────────────────────────────────────────────────────

/// The UI-visible state for the search screen.
///
/// | query | results | screen shows                                      |
/// |-------|---------|---------------------------------------------------|
/// | empty | —       | search history + hot stocks (initial empty state) |
/// | non-empty, loading | — | loading spinner                           |
/// | non-empty, results non-empty | — | result list                       |
/// | non-empty, results empty | — | "no results" empty state              |
@freezed
abstract class SearchState with _$SearchState {
  const factory SearchState({
    @Default('') String query,
    @Default([]) List<SearchResult> results,

    /// Most-active / hot stocks shown on the initial empty state.
    @Default([]) List<SearchResult> hotStocks,

    /// Error from loading hot stocks (null if successful or not yet loaded).
    Object? hotStocksError,

    /// Recent search terms (max [_kMaxHistory]), newest first.
    @Default([]) List<String> history,

    /// True while a debounced search request is in flight.
    @Default(false) bool isLoading,

    /// Non-null when the latest search call failed.
    Object? error,
  }) = _SearchState;

  const SearchState._();

  /// True when the query is empty — show history + hot stocks.
  bool get isEmptyQuery => query.isEmpty;

  /// True when a query has been entered but there are no results yet
  /// (still loading or search found nothing).
  bool get isEmptyResult => !isEmptyQuery && !isLoading && results.isEmpty && error == null;

  /// True when the query looks like a HK stock symbol or Chinese company name.
  ///
  /// Patterns detected:
  ///   - 1–5 digit numeric string (e.g., "700", "0700", "9988") — HK stock codes
  ///   - Query contains Chinese characters (e.g., "腾讯", "阿里") — likely HK-listed company
  ///
  /// Used by [SearchScreen] to show a "港股行情即将开放" message instead of the
  /// generic "no results" empty state.
  bool get isHkQuery {
    final trimmed = query.trim();
    if (RegExp(r'^\d{1,5}$').hasMatch(trimmed)) return true;
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(trimmed)) return true;
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SharedPreferences provider
// ─────────────────────────────────────────────────────────────────────────────

/// Injectable [SharedPreferences] provider.
///
/// Override in tests with `sharedPreferencesProvider.overrideWithValue(mock)`.
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) =>
    SharedPreferences.getInstance();

// ─────────────────────────────────────────────────────────────────────────────
// SearchNotifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the search screen state.
///
/// ## Usage
/// ```dart
/// // Update query (debounced search triggers automatically)
/// ref.read(searchProvider.notifier).updateQuery('AAPL');
///
/// // Add to history after user taps a result
/// ref.read(searchProvider.notifier).addToHistory('AAPL');
///
/// // Clear history
/// ref.read(searchProvider.notifier).clearHistory();
/// ```
///
/// ## Minimum input length
/// - ASCII-only query (symbol / English name): ≥ 1 character.
/// - Query with non-ASCII characters (Chinese name / Pinyin initials): ≥ 2 characters.
///
/// Queries shorter than the minimum show an empty results list without
/// triggering a network call.
@riverpod
class SearchNotifier extends _$SearchNotifier {
  Timer? _debounceTimer;

  @override
  SearchState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    // Schedule init as microtask so build() returns initial state first.
    // This prevents state writes before the provider is fully initialised.
    Future.microtask(_init);
    return const SearchState();
  }

  // ─── Initialisation ───────────────────────────────────────────────────────

  Future<void> _init() async {
    await Future.wait([
      _loadHistory(),
      _loadHotStocks(),
    ]);
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final raw = prefs.getStringList(_kHistoryKey) ?? [];
      state = state.copyWith(history: raw);
    } on Object catch (e) {
      AppLogger.warning('SearchNotifier: failed to load history: $e');
    }
  }

  Future<void> _loadHotStocks() async {
    try {
      final repo = ref.read(marketDataRepositoryProvider);
      final movers = await repo.getMovers(type: 'most_active', market: 'US');
      // Convert MoverItem to SearchResult-compatible representation.
      // MoverItem has the same quote fields; map price fields accordingly.
      final hot = movers
          .map((m) => SearchResult(
                symbol: m.symbol,
                name: m.name,
                nameZh: m.nameZh,
                market: 'US', // movers are US-only in Phase 1
                price: m.price,
                changePct: m.changePct,
                delayed: false,
              ))
          .toList();
      state = state.copyWith(hotStocks: hot, hotStocksError: null);
      AppLogger.debug('SearchNotifier: loaded ${hot.length} hot stocks');
    } on Object catch (e, stack) {
      AppLogger.error('SearchNotifier: failed to load hot stocks', error: e, stackTrace: stack);
      // Keep existing hot stocks if any, but mark as stale with error
      state = state.copyWith(hotStocksError: e);
    }
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Update the search query and schedule a debounced search.
  ///
  /// Clears results immediately when [query] is empty.
  void updateQuery(String query) {
    _debounceTimer?.cancel();
    state = state.copyWith(query: query, error: null);

    if (query.isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    if (!_meetsMinLength(query)) {
      // Too short — clear results without network call.
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    _debounceTimer = Timer(
      const Duration(milliseconds: _kDebounceMs),
      () => _doSearch(query),
    );
  }

  /// Add [symbol] to the persistent search history.
  ///
  /// Moves [symbol] to the front if already present; trims to [_kMaxHistory].
  Future<void> addToHistory(String symbol) async {
    final updated = [symbol, ...state.history.where((s) => s != symbol)]
        .take(_kMaxHistory)
        .toList();
    state = state.copyWith(history: updated);
    AppLogger.debug('SearchNotifier: added "$symbol" to history');
    await _persistHistory(updated);
  }

  /// Remove [symbol] from the search history.
  Future<void> removeFromHistory(String symbol) async {
    final updated = state.history.where((s) => s != symbol).toList();
    state = state.copyWith(history: updated);
    await _persistHistory(updated);
  }

  /// Clear all search history.
  Future<void> clearHistory() async {
    state = state.copyWith(history: []);
    await _persistHistory([]);
  }

  // ─── Internal helpers ─────────────────────────────────────────────────────

  Future<void> _doSearch(String query) async {
    // Guard: query may have changed since timer fired.
    if (state.query != query) return;

    try {
      final repo = ref.read(marketDataRepositoryProvider);
      AppLogger.debug('SearchNotifier: searching for "$query"');
      final results = await repo.searchStocks(q: query);
      // Guard again: don't overwrite state if query changed while awaiting.
      if (state.query == query) {
        state = state.copyWith(results: results, isLoading: false, error: null);
        AppLogger.debug('SearchNotifier: search "$query" returned ${results.length} results');
      }
    } on Object catch (e) {
      if (state.query == query) {
        AppLogger.warning('SearchNotifier: search "$query" failed: $e');
        state = state.copyWith(isLoading: false, error: e);
      }
    }
  }

  Future<void> _persistHistory(List<String> items) async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setStringList(_kHistoryKey, items);
    } on Object catch (e) {
      AppLogger.warning('SearchNotifier: failed to persist history: $e');
    }
  }

  /// Returns true if [query] meets the minimum input-length requirement.
  ///
  /// ASCII-only queries require ≥ 1 character; queries containing non-ASCII
  /// (Chinese characters, extended Unicode) require ≥ 2 characters.
  static bool _meetsMinLength(String query) {
    final isAsciiOnly = query.codeUnits.every((c) => c < 128);
    return isAsciiOnly ? query.isNotEmpty : query.length >= 2;
  }
}
