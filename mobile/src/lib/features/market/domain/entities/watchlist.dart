import 'quote.dart';

/// Ordered list of a user's watched stocks, each with a live [Quote].
///
/// Guest watchlists are stored locally in Hive.
/// Registered-user watchlists are persisted server-side and synced via
/// GET/POST/DELETE /v1/watchlist (market-api-spec §10–12).
typedef Watchlist = List<Quote>;
