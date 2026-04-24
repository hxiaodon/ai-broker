import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/extensions/decimal_extensions.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../trading/domain/entities/order.dart';
import '../../application/position_detail_provider.dart';
import '../../domain/entities/position_detail.dart';
import '../../domain/entities/trade_record.dart';

class PositionDetailScreen extends ConsumerWidget {
  const PositionDetailScreen({super.key, required this.symbol});

  final String symbol;

  static const _colors = ColorTokens.greenUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(positionDetailProvider(symbol));

    return Scaffold(
      backgroundColor: _colors.background,
      appBar: AppBar(
        backgroundColor: _colors.surface,
        iconTheme: IconThemeData(color: _colors.onSurface),
        title: Text(
          symbol,
          style: TextStyle(
            color: _colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: _colors.error),
                const SizedBox(height: 12),
                Text(
                  '加载持仓详情失败',
                  style: TextStyle(color: _colors.onSurface, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        data: (detail) => _DetailBody(detail: detail, colors: _colors),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.colors});

  final PositionDetail detail;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company name
          Text(
            detail.companyName,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // P&L overview card
          _SectionCard(
            colors: colors,
            child: Column(
              children: [
                _MetricRow(
                  label: '当前市值',
                  value: detail.marketValue.toAmount(),
                  valueColor: colors.onSurface,
                  colors: colors,
                ),
                _MetricRow(
                  label: '浮动盈亏',
                  value:
                      '${detail.unrealizedPnl.isPositive ? '+' : ''}${detail.unrealizedPnl.toAmount()} '
                      '(${detail.unrealizedPnlPct.toPercentChange()})',
                  valueColor: detail.unrealizedPnl.isPositive
                      ? colors.priceUp
                      : detail.unrealizedPnl.isNegative
                          ? colors.priceDown
                          : colors.onSurface,
                  colors: colors,
                ),
                _MetricRow(
                  label: '今日盈亏',
                  value:
                      '${detail.todayPnl.isPositive ? '+' : ''}${detail.todayPnl.toAmount()} '
                      '(${detail.todayPnlPct.toPercentChange()})',
                  valueColor: detail.todayPnl.isPositive
                      ? colors.priceUp
                      : detail.todayPnl.isNegative
                          ? colors.priceDown
                          : colors.onSurface,
                  colors: colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Position details card
          _SectionCard(
            colors: colors,
            child: Column(
              children: [
                _MetricRow(
                  label: '持有股数',
                  value: '${detail.qty} 股',
                  valueColor: colors.onSurface,
                  colors: colors,
                ),
                _MetricRow(
                  label: '持仓均价',
                  value: detail.avgCost.toUsPrice(),
                  valueColor: colors.onSurface,
                  colors: colors,
                ),
                _MetricRow(
                  label: '当前价格',
                  value: detail.currentPrice.toUsPrice(),
                  valueColor: colors.onSurface,
                  colors: colors,
                ),
                _MetricRow(
                  label: '成本基础',
                  value: detail.costBasis.toAmount(),
                  valueColor: colors.onSurface,
                  colors: colors,
                ),
                _MetricRow(
                  label: '已实现盈亏',
                  value:
                      '${detail.realizedPnl.isPositive ? '+' : ''}${detail.realizedPnl.toAmount()}',
                  valueColor: detail.realizedPnl.isPositive
                      ? colors.priceUp
                      : detail.realizedPnl.isNegative
                          ? colors.priceDown
                          : colors.onSurface,
                  colors: colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Wash sale warning
          if (detail.washSaleFlagged)
            _WashSaleWarning(colors: colors),

          // Settlement info
          if (detail.pendingSettlements.isNotEmpty) ...[
            _SettlementCard(
              detail: detail,
              colors: colors,
            ),
            const SizedBox(height: 12),
          ],

          // Recent trades
          _SectionHeader(title: '交易记录', colors: colors),
          const SizedBox(height: 8),
          if (detail.recentTrades.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  '暂无交易记录',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            _SectionCard(
              colors: colors,
              child: Column(
                children: detail.recentTrades
                    .map((t) => _TradeRow(trade: t, colors: colors))
                    .toList(),
              ),
            ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push(
                    RouteNames.orderEntry,
                    extra: {
                      'symbol': detail.symbol,
                      'market': detail.market,
                      'side': OrderSide.buy,
                    },
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.priceUp,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('买入'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: detail.availableQty > 0
                      ? () => context.push(
                            RouteNames.orderEntry,
                            extra: {
                              'symbol': detail.symbol,
                              'market': detail.market,
                              'side': OrderSide.sell,
                              'prefillQty': detail.availableQty,
                            },
                          )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.priceDown,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        colors.priceDown.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    detail.availableQty > 0
                        ? '卖出（${detail.availableQty} 股可卖）'
                        : '卖出（待结算）',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.colors, required this.child});

  final ColorTokens colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.colors});

  final String title;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: colors.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.colors,
  });

  final String label;
  final String value;
  final Color valueColor;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }
}

class _WashSaleWarning extends StatelessWidget {
  const _WashSaleWarning({required this.colors});

  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '该仓位可能涉及 Wash Sale 规则，相关已实现亏损不可抵税。'
              '具体税务影响请咨询税务顾问。',
              style: TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.detail, required this.colors});

  final PositionDetail detail;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    final pending = detail.pendingSettlements;
    final pendingQty = pending.fold(0, (acc, s) => acc + s.qty);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '结算信息',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: '可卖出（已结算）',
            value: '${detail.availableQty} 股',
            valueColor: colors.onSurface,
            colors: colors,
          ),
          _MetricRow(
            label: '待结算',
            value: '$pendingQty 股',
            valueColor: colors.onSurfaceVariant,
            colors: colors,
          ),
          if (pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '预计 ${_formatDate(pending.first.settleDate)} 结算后可卖',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _TradeRow extends StatelessWidget {
  const _TradeRow({required this.trade, required this.colors});

  final TradeRecord trade;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    final isBuy = trade.side == TradeSide.buy;
    final sideColor = isBuy ? colors.priceUp : colors.priceDown;
    final d = trade.executedAt;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: sideColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isBuy ? '买入' : '卖出',
              style: TextStyle(
                color: sideColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${trade.qty} 股 @ ${trade.price.toUsPrice()}',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13,
                  fontFamily: 'Courier',
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trade.amount.toAmount(),
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13,
                  fontFamily: 'Courier',
                ),
              ),
              Text(
                '手续费 ${trade.fee.toAmount()}',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              if (trade.washSale)
                const Text(
                  '⚠️ Wash Sale',
                  style: TextStyle(color: Colors.amber, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
