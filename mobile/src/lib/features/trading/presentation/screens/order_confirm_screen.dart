import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../application/order_submit_notifier.dart';
import '../../application/portfolio_summary_provider.dart';
import '../../application/recent_order_banner_provider.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/portfolio_summary.dart';

class OrderConfirmScreen extends ConsumerWidget {
  const OrderConfirmScreen({
    super.key,
    required this.symbol,
    required this.market,
    required this.side,
    required this.orderType,
    required this.qty,
    this.limitPrice,
    required this.validity,
    required this.extendedHours,
  });

  final String symbol;
  final String market;
  final OrderSide side;
  final OrderType orderType;
  final int qty;
  final Decimal? limitPrice;
  final OrderValidity validity;
  final bool extendedHours;

  static const _colors = ColorTokens.greenUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submitState = ref.watch(orderSubmitProvider);
    final portfolioAsync = ref.watch(portfolioSummaryProvider);
    final estimatedTotal = _estimatedTotal();
    final buyingPower = portfolioAsync.whenOrNull(
      data: (PortfolioSummary p) => p.buyingPower,
    );
    final isBuyInsufficient = side == OrderSide.buy &&
        estimatedTotal != null &&
        buyingPower != null &&
        estimatedTotal > buyingPower;

    // Navigate to order list on success
    ref.listen(orderSubmitProvider, (_, next) {
      next.maybeWhen(
        success: (orderId, requestId) {
          // Publish snapshot for OrderListScreen's one-shot banner/highlight.
          ref.read(recentOrderBannerProvider.notifier).set(RecentOrderInfo(
                orderId: orderId,
                symbol: symbol,
                side: side,
                orderType: orderType,
                qty: qty,
                submittedAt: DateTime.now().toUtc(),
              ));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('委托已提交，订单号：$orderId'),
              backgroundColor: const Color(0xFF0DC582),
            ),
          );
          context.go(RouteNames.tradingOrders);
        },
        orElse: () {},
      );
    });

    final actionColor = side == OrderSide.buy
        ? const Color(0xFF0DC582)
        : const Color(0xFFFF4747);

    return Scaffold(
      backgroundColor: _colors.background,
      appBar: AppBar(
        backgroundColor: _colors.surface,
        title: Text(
          '确认委托',
          style: TextStyle(
              color: _colors.onSurface, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _colors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary card
            _OrderSummaryCard(
              symbol: symbol,
              side: side,
              orderType: orderType,
              qty: qty,
              limitPrice: limitPrice,
              validity: validity,
              extendedHours: extendedHours,
              estimatedTotal: estimatedTotal,
              buyingPower: buyingPower,
              colors: _colors,
            ),
            const SizedBox(height: 16),

            // Best execution disclosure
            _DisclosureCard(colors: _colors),
            const SizedBox(height: 24),

            // Submit state feedback
            ...submitState.maybeWhen(
              error: (message) => [
                _buildErrorBanner(message),
              ],
              orElse: () => [],
            ),
            if (isBuyInsufficient)
              _buildErrorBanner(
                '可用资金不足：预计总金额 \$${estimatedTotal!.toStringAsFixed(2)}，可用资金 \$${buyingPower!.toStringAsFixed(2)}',
              ),

            const Spacer(),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: submitState.maybeWhen(
                  submitting: () => null,
                  awaitingBiometric: () => null,
                  orElse: () => isBuyInsufficient ? null : () => _submit(ref),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: actionColor.withOpacity(0.4),
                ),
            child: submitState.maybeWhen(
                  submitting: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  awaitingBiometric: () => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.fingerprint, size: 20),
                      SizedBox(width: 8),
                      Text('等待生物识别验证',
                          style: TextStyle(fontSize: 15)),
                    ],
                  ),
                  orElse: () => Text(
                    side == OrderSide.buy ? '确认买入' : '确认卖出',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Decimal? _estimatedTotal() {
    final perShare = switch (orderType) {
      OrderType.limit => limitPrice,
      // Conservative estimate for market order in mock / pre-trade UI:
      // use a placeholder floor of $100 so zero/empty values don't bypass buying power check.
      OrderType.market => Decimal.parse('100.00'),
    };
    if (perShare == null) return null;
    return perShare * Decimal.fromInt(qty);
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _colors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _colors.error.withOpacity(0.4)),
      ),
      child: Text(
        message,
        style: TextStyle(color: _colors.error, fontSize: 13),
      ),
    );
  }

  void _submit(WidgetRef ref) {
    // Biometric gating derives from AuthState — `_isBiometricRegistered()` is
    // resolved on login/session-restore. Guest/unauthenticated users can't
    // reach this screen (router guard), but fall back to `false` defensively.
    final biometricEnabled = ref.read(authProvider).maybeWhen(
          authenticated: (String _, String __, bool biometricEnabled) =>
              biometricEnabled,
          orElse: () => false,
        );
    ref.read(orderSubmitProvider.notifier).submit(
          symbol: symbol,
          market: market,
          side: side,
          orderType: orderType,
          qty: qty,
          limitPrice: limitPrice,
          validity: validity,
          extendedHours: extendedHours,
          biometricEnabled: biometricEnabled,
        );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.symbol,
    required this.side,
    required this.orderType,
    required this.qty,
    this.limitPrice,
    required this.validity,
    required this.extendedHours,
    required this.estimatedTotal,
    required this.buyingPower,
    required this.colors,
  });

  final String symbol;
  final OrderSide side;
  final OrderType orderType;
  final int qty;
  final Decimal? limitPrice;
  final OrderValidity validity;
  final bool extendedHours;
  final Decimal? estimatedTotal;
  final Decimal? buyingPower;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    final sideColor = side == OrderSide.buy
        ? const Color(0xFF0DC582)
        : const Color(0xFFFF4747);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                symbol,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sideColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  side == OrderSide.buy ? '买入' : '卖出',
                  style: TextStyle(
                    color: sideColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: colors.divider, height: 20),
          _row('订单类型', orderType == OrderType.market ? '市价单' : '限价单'),
          const SizedBox(height: 10),
          _row(
            '委托价格',
            orderType == OrderType.market
                ? '市价'
                : '\$${limitPrice?.toStringAsFixed(4) ?? '--'}',
          ),
          const SizedBox(height: 10),
          _row('委托数量', '$qty 股'),
          const SizedBox(height: 10),
          _row(
            '有效期',
            validity == OrderValidity.day ? '当日有效 (DAY)' : '长期有效 (GTC)',
          ),
          if (extendedHours) ...[
            const SizedBox(height: 10),
            _row('盘前盘后', '已开启'),
          ],
          if (side == OrderSide.buy) ...[
            Divider(color: colors.divider, height: 20),
            _row('可用资金', buyingPower != null ? '\$${buyingPower!.toStringAsFixed(2)}' : '--'),
          ],
          if (estimatedTotal != null) ...[
            Divider(color: colors.divider, height: 20),
            _row(
              side == OrderSide.buy ? '预计总金额' : '预计到账',
              '\$${estimatedTotal!.toStringAsFixed(2)}',
              bold: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Row(
        children: [
          Text(label,
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      );
}

class _DisclosureCard extends StatelessWidget {
  const _DisclosureCard({required this.colors});
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '最优执行披露：本平台按照 SEC Reg NMS 规定，将订单路由至能提供最优价格的交易所执行。本平台不接受来自交易所或做市商的价格改善费用（PFOF）。',
        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
      ),
    );
  }
}
