import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../shared/extensions/decimal_extensions.dart';
import '../../../../shared/theme/color_tokens.dart';

class AssetSummaryCard extends StatelessWidget {
  const AssetSummaryCard({
    super.key,
    required this.totalEquity,
    required this.dayPnl,
    required this.dayPnlPct,
    required this.totalPnl,
    required this.totalPnlPct,
    required this.cashBalance,
    required this.unsettledCash,
    required this.colors,
  });

  final Decimal totalEquity;
  final Decimal dayPnl;
  final Decimal dayPnlPct;
  final Decimal totalPnl;
  final Decimal totalPnlPct;
  final Decimal cashBalance;
  final Decimal unsettledCash;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '账户总资产（USD）',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            totalEquity.toAmount(),
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _PnlItem(
                label: '今日盈亏',
                value: dayPnl,
                pct: dayPnlPct,
              ),
              const SizedBox(width: 20),
              _PnlItem(
                label: '累计盈亏',
                value: totalPnl,
                pct: totalPnlPct,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _BalanceItem(label: '可用现金', value: cashBalance),
              const SizedBox(width: 20),
              _UnsettledItem(unsettledCash: unsettledCash),
            ],
          ),
        ],
      ),
    );
  }
}

class _PnlItem extends StatelessWidget {
  const _PnlItem({
    required this.label,
    required this.value,
    required this.pct,
  });

  final String label;
  final Decimal value;
  final Decimal pct;

  @override
  Widget build(BuildContext context) {
    final isPos = value.isPositive;
    final isNeg = value.isNegative;
    final pnlColor = isPos
        ? const Color(0xFF0DC582)
        : isNeg
            ? const Color(0xFFFF4747)
            : Colors.white70;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${isPos ? '+' : ''}${value.toAmount()}',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: pnlColor,
          ),
        ),
        Text(
          pct.toPercentChange(),
          style: TextStyle(fontSize: 11, color: pnlColor),
        ),
      ],
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem({required this.label, required this.value});

  final String label;
  final Decimal value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.toAmount(),
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _UnsettledItem extends StatelessWidget {
  const _UnsettledItem({required this.unsettledCash});

  final Decimal unsettledCash;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '待结算资金',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showSettlementInfo(context),
              child: Icon(
                Icons.info_outline,
                size: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          unsettledCash.toAmount(),
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showSettlementInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('待结算资金说明'),
        content: const Text(
          '美股实行 T+1 结算制度——您卖出股票所得的资金，将在下一个工作日完成清算后才可提现或再次购买。\n\n'
          '例如：今日卖出，明日结算，明日可用。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
