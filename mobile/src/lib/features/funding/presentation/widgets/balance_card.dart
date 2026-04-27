import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/extensions/decimal_extensions.dart';
import '../../../../shared/widgets/loading/skeleton_loader.dart';
import '../../domain/entities/account_balance.dart';

/// Displays the user's USD account balance with 4 breakdown fields.
///
/// Shows skeleton while loading, retry button on error.
class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key, required this.balanceAsync});

  final AsyncValue<AccountBalance> balanceAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1557B0), Color(0xFF1A73E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: balanceAsync.when(
        loading: () => const _BalanceCardSkeleton(),
        error: (e, _) => _BalanceCardError(onRetry: () {}),
        data: (balance) => _BalanceCardContent(balance: balance),
      ),
    );
  }
}

class _BalanceCardContent extends StatelessWidget {
  const _BalanceCardContent({required this.balance});
  final AccountBalance balance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '账户余额',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            balance.totalBalance.toAmount(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalanceItem(
                  label: '可用现金',
                  value: balance.availableBalance.toAmount(),
                ),
              ),
              Expanded(
                child: _BalanceItem(
                  label: '待结算',
                  value: balance.unsettledAmount.toAmount(),
                  hint: 'T+1',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BalanceItem(
            label: '可提现金额',
            value: balance.withdrawableBalance.toAmount(),
            valueStyle: const TextStyle(
              color: Color(0xFF0DC582),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem({
    required this.label,
    required this.value,
    this.hint,
    this.valueStyle,
  });

  final String label;
  final String value;
  final String? hint;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (hint != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white38),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(hint!,
                    style: const TextStyle(color: Colors.white60, fontSize: 9)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
        ),
      ],
    );
  }
}

class _BalanceCardSkeleton extends StatelessWidget {
  const _BalanceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: 60, height: 13),
          SizedBox(height: 8),
          SkeletonLoader(width: 180, height: 28),
          SizedBox(height: 20),
          SkeletonLoader(width: double.infinity, height: 1),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SkeletonLoader(width: double.infinity, height: 36)),
              SizedBox(width: 16),
              Expanded(child: SkeletonLoader(width: double.infinity, height: 36)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceCardError extends StatelessWidget {
  const _BalanceCardError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('余额加载失败',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('重试',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
