import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../application/portfolio_summary_provider.dart';
import '../../application/positions_provider.dart';
import '../../domain/entities/order.dart';
import '../widgets/slide_to_confirm_widget.dart';

class OrderEntryScreen extends ConsumerStatefulWidget {
  const OrderEntryScreen({
    super.key,
    required this.symbol,
    required this.market,
    this.initialSide = OrderSide.buy,
    this.prefillQty,
  });

  final String symbol;
  final String market;
  final OrderSide initialSide;
  final int? prefillQty;

  @override
  ConsumerState<OrderEntryScreen> createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends ConsumerState<OrderEntryScreen> {
  late OrderSide _side;
  OrderType _orderType = OrderType.limit;
  OrderValidity _validity = OrderValidity.day;
  bool _extendedHours = false;
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  bool _showExtHoursWarning = false;

  static const _colors = ColorTokens.greenUp;

  @override
  void initState() {
    super.initState();
    _side = widget.initialSide;
    if (widget.prefillQty != null) {
      _qtyController.text = widget.prefillQty.toString();
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  int get _qty => int.tryParse(_qtyController.text) ?? 0;
  Decimal? get _limitPrice {
    final t = _priceController.text;
    if (t.isEmpty) return null;
    return Decimal.tryParse(t);
  }

  bool get _canSubmit {
    if (_qty <= 0) return false;
    if (_orderType == OrderType.limit && _limitPrice == null) return false;
    return true;
  }

  void _onSlideConfirmed() {
    if (!_canSubmit) return;
    context.push(
      RouteNames.tradingOrderConfirm,
      extra: {
        'symbol': widget.symbol,
        'market': widget.market,
        'side': _side,
        'orderType': _orderType,
        'qty': _qty,
        'limitPrice': _limitPrice,
        'validity': _validity,
        'extendedHours': _extendedHours,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolioAsync = ref.watch(portfolioSummaryProvider);
    final positionsAsync = ref.watch(positionsProvider);

    // Fixed buy=green, sell=red per PRD §6.7
    final actionColor = _side == OrderSide.buy
        ? const Color(0xFF0DC582)
        : const Color(0xFFFF4747);

    return Scaffold(
      backgroundColor: _colors.background,
      appBar: AppBar(
        backgroundColor: _colors.surface,
        title: Text(
          widget.symbol,
          style: TextStyle(color: _colors.onSurface, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: _colors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buy / Sell toggle
            _BuySellToggle(
              side: _side,
              onChanged: (s) => setState(() => _side = s),
            ),
            const SizedBox(height: 16),

            // Available balance / shares
            _BalanceCard(
              side: _side,
              portfolioAsync: portfolioAsync,
              positionsAsync: positionsAsync,
              symbol: widget.symbol,
              colors: _colors,
            ),
            const SizedBox(height: 16),

            // Order type
            _SectionLabel('订单类型', _colors),
            const SizedBox(height: 8),
            _OrderTypeSelector(
              selected: _orderType,
              onChanged: (t) => setState(() {
                _orderType = t;
                if (t == OrderType.market) _priceController.clear();
              }),
              colors: _colors,
            ),
            const SizedBox(height: 16),

            // Quantity
            _SectionLabel('数量（股）', _colors),
            const SizedBox(height: 8),
            _QtyInput(
              controller: _qtyController,
              colors: _colors,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Limit price (only for limit orders)
            if (_orderType == OrderType.limit) ...[
              _SectionLabel('委托价格', _colors),
              const SizedBox(height: 8),
              _PriceInput(
                controller: _priceController,
                colors: _colors,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
            ],

            // Validity
            _SectionLabel('有效期', _colors),
            const SizedBox(height: 8),
            _ValiditySelector(
              selected: _validity,
              onChanged: (v) => setState(() => _validity = v),
              colors: _colors,
            ),
            const SizedBox(height: 16),

            // Extended hours (limit orders only)
            if (_orderType == OrderType.limit)
              _ExtendedHoursRow(
                enabled: _extendedHours,
                onChanged: (v) {
                  setState(() {
                    _extendedHours = v;
                    if (v) _showExtHoursWarning = true;
                  });
                },
                colors: _colors,
              ),

            // Extended hours warning banner
            if (_extendedHours || _showExtHoursWarning)
              _ExtHoursWarningBanner(colors: _colors),

            const SizedBox(height: 24),

            // Fee estimate
            _FeeEstimateCard(
              side: _side,
              qty: _qty,
              limitPrice: _limitPrice,
              colors: _colors,
            ),
            const SizedBox(height: 24),

            // Slide to confirm
            Opacity(
              opacity: _canSubmit ? 1.0 : 0.4,
              child: SlideToConfirmWidget(
                label: _side == OrderSide.buy ? '滑动确认买入' : '滑动确认卖出',
                thumbColor: actionColor,
                onConfirmed: _canSubmit ? _onSlideConfirmed : () {},
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _BuySellToggle extends StatelessWidget {
  const _BuySellToggle({required this.side, required this.onChanged});
  final OrderSide side;
  final ValueChanged<OrderSide> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _tab(OrderSide.buy, '买入', const Color(0xFF0DC582))),
        const SizedBox(width: 8),
        Expanded(child: _tab(OrderSide.sell, '卖出', const Color(0xFFFF4747))),
      ],
    );
  }

  Widget _tab(OrderSide s, String label, Color color) {
    final selected = side == s;
    return GestureDetector(
      onTap: () => onChanged(s),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : const Color(0xFF1A1C2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : const Color(0xFF2C2E3E),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : const Color(0xFFB0B3C8),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.side,
    required this.portfolioAsync,
    required this.positionsAsync,
    required this.symbol,
    required this.colors,
  });

  final OrderSide side;
  final AsyncValue<dynamic> portfolioAsync;
  final AsyncValue<dynamic> positionsAsync;
  final String symbol;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: side == OrderSide.buy
          ? portfolioAsync.when(
              loading: () => _label('可用资金', '加载中...', colors),
              error: (_, _) => _label('可用资金', '--', colors),
              data: (p) => _label(
                '可用资金',
                '\$${p.buyingPower.toStringAsFixed(2)}',
                colors,
              ),
            )
          : positionsAsync.when(
              loading: () => _label('可卖数量', '加载中...', colors),
              error: (_, _) => _label('可卖数量', '--', colors),
              data: (positions) {
                final pos = (positions as List).cast<dynamic>().firstWhere(
                      (p) => p.symbol == symbol,
                      orElse: () => null,
                    );
                return _label(
                  '可卖数量',
                  pos != null ? '${pos.availableQty} 股' : '0 股',
                  colors,
                );
              },
            ),
    );
  }

  Widget _label(String title, String value, ColorTokens c) => Row(
        children: [
          Text(title, style: TextStyle(color: c.onSurfaceVariant, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: c.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.colors);
  final String text;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
}

class _OrderTypeSelector extends StatelessWidget {
  const _OrderTypeSelector({
    required this.selected,
    required this.onChanged,
    required this.colors,
  });
  final OrderType selected;
  final ValueChanged<OrderType> onChanged;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip(OrderType.market, '市价单'),
        const SizedBox(width: 8),
        _chip(OrderType.limit, '限价单'),
      ],
    );
  }

  Widget _chip(OrderType t, String label) {
    final sel = selected == t;
    return GestureDetector(
      onTap: () => onChanged(t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? colors.primary.withValues(alpha: 0.15) : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? colors.primary : colors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? colors.primary : colors.onSurfaceVariant,
            fontSize: 13,
            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _QtyInput extends StatelessWidget {
  const _QtyInput({
    required this.controller,
    required this.colors,
    required this.onChanged,
  });
  final TextEditingController controller;
  final ColorTokens colors;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(color: colors.onSurface, fontSize: 16),
      decoration: InputDecoration(
        hintText: '请输入数量',
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        filled: true,
        fillColor: colors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixText: '股',
        suffixStyle: TextStyle(color: colors.onSurfaceVariant),
      ),
    );
  }
}

class _PriceInput extends StatelessWidget {
  const _PriceInput({
    required this.controller,
    required this.colors,
    required this.onChanged,
  });
  final TextEditingController controller;
  final ColorTokens colors;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: colors.onSurface, fontSize: 16),
      decoration: InputDecoration(
        hintText: '请输入委托价',
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        filled: true,
        fillColor: colors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixText: '\$ ',
        prefixStyle: TextStyle(color: colors.onSurfaceVariant),
      ),
    );
  }
}

class _ValiditySelector extends StatelessWidget {
  const _ValiditySelector({
    required this.selected,
    required this.onChanged,
    required this.colors,
  });
  final OrderValidity selected;
  final ValueChanged<OrderValidity> onChanged;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip(OrderValidity.day, '当日有效 (DAY)'),
        const SizedBox(width: 8),
        _chip(OrderValidity.gtc, '长期有效 (GTC)'),
      ],
    );
  }

  Widget _chip(OrderValidity v, String label) {
    final sel = selected == v;
    return GestureDetector(
      onTap: () => onChanged(v),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? colors.primary.withValues(alpha: 0.15) : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? colors.primary : colors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? colors.primary : colors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ExtendedHoursRow extends StatelessWidget {
  const _ExtendedHoursRow({
    required this.enabled,
    required this.onChanged,
    required this.colors,
  });
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('允许盘前盘后交易',
            style: TextStyle(color: colors.onSurface, fontSize: 14)),
        const Spacer(),
        Switch(
          value: enabled,
          onChanged: onChanged,
          activeThumbColor: colors.primary,
        ),
      ],
    );
  }
}

class _ExtHoursWarningBanner extends StatelessWidget {
  const _ExtHoursWarningBanner({required this.colors});
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFF9800), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '盘前盘后流动性较低，价差可能较大，仅支持限价单，可能无法成交',
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeEstimateCard extends StatelessWidget {
  const _FeeEstimateCard({
    required this.side,
    required this.qty,
    required this.limitPrice,
    required this.colors,
  });
  final OrderSide side;
  final int qty;
  final Decimal? limitPrice;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    if (qty <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _row('佣金', '\$0.00（免佣）', colors),
          const SizedBox(height: 6),
          _row('交易所费用', '约 \$0.30', colors),
          if (side == OrderSide.sell) ...[
            const SizedBox(height: 6),
            _row('SEC 费用', '按成交金额计算', colors),
            const SizedBox(height: 6),
            _row('FINRA 费用', '按股数计算', colors),
          ],
          Divider(color: colors.divider, height: 16),
          _row(
            side == OrderSide.buy ? '预计总金额' : '预计到账',
            limitPrice != null
                ? '\$${(limitPrice! * Decimal.fromInt(qty)).toStringAsFixed(2)}'
                : '--',
            colors,
            bold: true,
          ),
          const SizedBox(height: 4),
          Text(
            '以上费用为预估，以实际成交时的费用为准',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, ColorTokens c, {bool bold = false}) =>
      Row(
        children: [
          Text(label,
              style: TextStyle(color: c.onSurfaceVariant, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      );
}
