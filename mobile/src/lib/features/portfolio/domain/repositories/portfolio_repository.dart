import '../entities/position_detail.dart';

abstract class PortfolioRepository {
  Future<PositionDetail> getPositionDetail(String symbol);
}
