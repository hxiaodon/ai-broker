import 'package:flutter/material.dart';

import '../../../../shared/theme/color_tokens.dart';

class EmptyPortfolioWidget extends StatelessWidget {
  const EmptyPortfolioWidget({
    super.key,
    required this.colors,
    required this.onDeposit,
    required this.onBrowseMarket,
  });

  final ColorTokens colors;
  final VoidCallback onDeposit;
  final VoidCallback onBrowseMarket;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              '账户还没有资产',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '先入金，再买入您感兴趣的股票',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDeposit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('立即入金'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onBrowseMarket,
              child: Text(
                '浏览行情',
                style: TextStyle(color: colors.primary, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CashOnlyPortfolioWidget extends StatelessWidget {
  const CashOnlyPortfolioWidget({
    super.key,
    required this.cashBalance,
    required this.colors,
    required this.onBrowseMarket,
  });

  final String cashBalance;
  final ColorTokens colors;
  final VoidCallback onBrowseMarket;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 64, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              '可用现金',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              cashBalance,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '您有可用资金，买入您的第一只股票吧',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBrowseMarket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('浏览热门股票'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
