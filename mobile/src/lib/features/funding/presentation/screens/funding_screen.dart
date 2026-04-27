import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/security/screen_protection_service.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../application/account_balance_notifier.dart';
import '../../application/bank_accounts_notifier.dart';
import '../../application/fund_transfer_history_notifier.dart';
import '../widgets/balance_card.dart';
import '../widgets/bank_account_card.dart';
import '../widgets/hkd_placeholder_card.dart';
import '../widgets/transfer_history_tile.dart';

/// 资金中心 — main funding hub page.
///
/// Accessible from the Portfolio tab via the [出入金] button.
/// Displays: USD balance card, HKD placeholder, quick actions,
/// bank account list, and recent transfer history.
class FundingScreen extends ConsumerStatefulWidget {
  const FundingScreen({super.key});

  @override
  ConsumerState<FundingScreen> createState() => _FundingScreenState();
}

class _FundingScreenState extends ConsumerState<FundingScreen>
    with ScreenProtectionMixin {
  static const _colors = ColorTokens.greenUp;

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(accountBalanceProvider);
    final bankAccountsAsync = ref.watch(bankAccountsProvider);
    final historyAsync = ref.watch(fundTransferHistoryProvider);

    return Scaffold(
      backgroundColor: _colors.background,
      appBar: AppBar(
        backgroundColor: _colors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          color: _colors.onSurface,
          onPressed: () => context.pop(),
        ),
        title: Text(
          '资金中心',
          style: TextStyle(
            color: _colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountBalanceProvider);
          ref.invalidate(bankAccountsProvider);
          ref.invalidate(fundTransferHistoryProvider);
        },
        child: ListView(
          children: [
            // USD balance card
            BalanceCard(balanceAsync: balanceAsync),

            // HKD placeholder (Phase 2)
            const HkdPlaceholderCard(),

            // Quick actions
            _QuickActions(
              onDeposit: () => context.push(RouteNames.deposit),
              onWithdraw: () => context.push(RouteNames.withdraw),
            ),

            // Bank accounts
            _SectionHeader(
              title: '我的银行卡',
              trailing: TextButton.icon(
                onPressed: () => context.push(RouteNames.bankAccountBind),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加'),
              ),
            ),
            bankAccountsAsync.when(
              loading: () => const _SectionLoading(),
              error: (e, _) => _SectionError(
                message: '加载银行卡失败',
                onRetry: () => ref.invalidate(bankAccountsProvider),
              ),
              data: (accounts) => accounts.isEmpty
                  ? const _EmptyBankCard()
                  : Column(
                      children: accounts
                          .map((a) => BankAccountCard(
                                account: a,
                                onDelete: () => ref
                                    .read(bankAccountsProvider.notifier)
                                    .removeBankAccount(a.id),
                              ))
                          .toList(),
                    ),
            ),

            // Recent history
            const _SectionHeader(title: '近期流水'),
            historyAsync.when(
              loading: () => const _SectionLoading(),
              error: (e, _) => _SectionError(
                message: '加载流水失败',
                onRetry: () => ref.invalidate(fundTransferHistoryProvider),
              ),
              data: (transfers) => transfers.isEmpty
                  ? const _EmptyHistory()
                  : Column(
                      children: transfers
                          .map((t) => TransferHistoryTile(transfer: t))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onDeposit,
    required this.onWithdraw,
  });

  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.arrow_downward,
              label: '入金',
              color: const Color(0xFF0DC582),
              onTap: onDeposit,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.arrow_upward,
              label: '出金',
              color: const Color(0xFF1A73E8),
              onTap: onWithdraw,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _EmptyBankCard extends StatelessWidget {
  const _EmptyBankCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Text('暂无银行卡，请点击右上角添加',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Text('暂无出入金记录',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
      ),
    );
  }
}
