import '../entities/watchlist.dart';

/// Abstract repository for the user's personal watchlist.
///
/// Behaviour differs by auth state:
///   - **Registered users** — CRUD is mirrored to the server via the
///     market-data service (GET/POST/DELETE /v1/watchlist). The local Hive
///     copy is kept in sync as an offline cache.
///   - **Guest users** — operations are local-only (Hive).  No server calls
///     are made.  The local list is preserved after the user logs in; the app
///     prompts to import it into the server watchlist (T11 concern).
///
/// All methods throw [AppException] subtypes on failure:
///   - [NetworkException] — connectivity or timeout
///   - [AuthException] — token invalid/expired (registered users only)
///   - [BusinessException] — server-side rule violation (e.g. 100-symbol limit)
abstract class WatchlistRepository {
  /// Fetch the current watchlist with live quote snapshots.
  ///
  /// Registered: fetches from server (authoritative), updates local mirror.
  /// Guest: reads local symbol list, fetches quote snapshots via REST.
  Future<Watchlist> getWatchlist();

  /// Add [symbol] (e.g. "AAPL") from [market] ("US" or "HK") to the list.
  ///
  /// No-op if the symbol is already in the list.
  /// Registered: calls POST /v1/watchlist, then updates local mirror.
  /// Guest: updates local only.
  Future<void> addToWatchlist({required String symbol, required String market});

  /// Remove [symbol] from the list.
  ///
  /// Registered: calls DELETE /v1/watchlist/{symbol}, then updates local.
  /// Guest: updates local only.
  Future<void> removeFromWatchlist(String symbol);

  /// Persist a new display order for the watchlist.
  ///
  /// [orderedSymbols] must be a permutation of the currently stored symbols;
  /// unknown symbols are silently dropped.
  ///
  /// Server has no reorder endpoint — local-only for both guest and registered.
  Future<void> reorderWatchlist(List<String> orderedSymbols);
}
