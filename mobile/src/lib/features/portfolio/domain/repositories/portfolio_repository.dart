import '../entities/position.dart';

/// Repository interface for portfolio data.
abstract class PortfolioRepository {
  /// Get all current positions.
  Future<List<Position>> getPositions();

  /// Get position detail for a specific symbol.
  Future<Position?> getPosition(String symbol);

  /// Get total portfolio summary (total value, total P&L, etc.)
  Future<Map<String, String>> getPortfolioSummary();

  /// Get realised P&L history.
  Future<List<Map<String, dynamic>>> getRealisedPnlHistory({
    DateTime? from,
    DateTime? to,
  });
}
