import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/local_auth_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../domain/entities/bank_account.dart';

/// Displays a single linked bank account with verification status badge.
///
/// Interactions:
///  - Tap on PENDING_MICRO_DEPOSIT card → navigate to micro-deposit verify screen
///  - Long press (or swipe) → biometric confirm → delete
class BankAccountCard extends ConsumerWidget {
  const BankAccountCard({
    super.key,
    required this.account,
    required this.onDelete,
  });

  final BankAccount account;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(account.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, ref),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF242638),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance, color: Colors.white54, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.bankName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.accountNumberMasked,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(account: account),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (account.microDepositStatus == MicroDepositStatus.pending ||
        account.microDepositStatus == MicroDepositStatus.verifying) {
      context.push(
        RouteNames.fundingMicroDeposit
            .replaceFirst(':bankId', account.id),
      );
    }
  }

  Future<bool?> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C2A),
        title: const Text('删除银行卡',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除 ${account.bankName} ${account.accountNumberMasked} 吗？',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    // Require biometric re-verification before removing a withdrawal channel.
    return ref.read(localAuthServiceProvider).authenticate(
          localizedReason: '删除银行卡需要身份验证',
        );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.account});
  final BankAccount account;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolveStatus();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  (String, Color) _resolveStatus() {
    if (account.microDepositStatus == MicroDepositStatus.failed) {
      return ('验证失败', Colors.red);
    }
    if (account.microDepositStatus == MicroDepositStatus.pending ||
        account.microDepositStatus == MicroDepositStatus.verifying) {
      return ('等待微存款', const Color(0xFFFFA940));
    }
    if (account.isInCooldown) {
      final days = account.cooldownEndsAt!
          .difference(DateTime.now().toUtc())
          .inDays + 1;
      return ('冷却期 $days 天', const Color(0xFFFFA940));
    }
    if (account.isVerified) {
      return ('✓ 已验证', const Color(0xFF0DC582));
    }
    return ('未验证', Colors.grey);
  }
}
