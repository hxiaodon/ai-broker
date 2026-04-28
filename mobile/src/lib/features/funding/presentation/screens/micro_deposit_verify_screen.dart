import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/security/screen_protection_service.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/inputs/decimal_input_field.dart';
import '../../application/bank_accounts_notifier.dart';
import '../../domain/entities/bank_account.dart';

/// Micro-deposit verification screen.
///
/// Navigated to from FundingScreen when user taps on a bank account card
/// with status [MicroDepositStatus.pending] or [MicroDepositStatus.verifying].
///
/// The user confirms the 2 small amounts sent by the bank.
/// Validation errors (wrong amounts) show remaining attempts.
/// After 5 failed attempts, the card is invalidated — user must re-bind.
class MicroDepositVerifyScreen extends ConsumerStatefulWidget {
  const MicroDepositVerifyScreen({super.key, required this.bankAccountId});

  final String bankAccountId;

  @override
  ConsumerState<MicroDepositVerifyScreen> createState() =>
      _MicroDepositVerifyScreenState();
}

class _MicroDepositVerifyScreenState
    extends ConsumerState<MicroDepositVerifyScreen>
    with ScreenProtectionMixin {
  static const _colors = ColorTokens.greenUp;

  Decimal? _amount1;
  Decimal? _amount2;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final bankAccountsAsync = ref.watch(bankAccountsProvider);
    final account = bankAccountsAsync.value?.firstWhereOrNull(
      (a) => a.id == widget.bankAccountId,
    );

    return Scaffold(
      backgroundColor: _colors.background,
      appBar: AppBar(
        backgroundColor: _colors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          color: _colors.onSurface,
          onPressed: () => context.pop(),
        ),
        title: Text('验证微存款',
            style: TextStyle(
                color: _colors.onSurface, fontWeight: FontWeight.w700)),
      ),
      body: account == null
          ? const Center(
              child: Text('未找到银行卡', style: TextStyle(color: Colors.white60)))
          : account.microDepositStatus == MicroDepositStatus.failed
              ? _FailedState(
                  account: account,
                  onDelete: () async {
                    await ref
                        .read(bankAccountsProvider.notifier)
                        .removeBankAccount(account.id);
                    if (context.mounted) context.pop();
                  },
                )
              : _VerifyForm(
                  account: account,
                  amount1: _amount1,
                  amount2: _amount2,
                  isSubmitting: _isSubmitting,
                  errorMessage: _errorMessage,
                  onAmount1Changed: (v) => setState(() => _amount1 = v),
                  onAmount2Changed: (v) => setState(() => _amount2 = v),
                  onSubmit: _submit,
                ),
    );
  }

  Future<void> _submit() async {
    final a1 = _amount1;
    final a2 = _amount2;
    if (a1 == null || a2 == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(bankAccountsProvider.notifier)
          .verifyMicroDeposit(
            bankAccountId: widget.bankAccountId,
            amount1: a1,
            amount2: a2,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证成功！银行卡已绑定。')),
        );
        context.pop();
      }
    } on Object catch (e) {
      final msg = e is ValidationException
          ? e.message
          : e is BusinessException
              ? e.message
              : '验证失败，请稍后重试';
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _VerifyForm extends StatelessWidget {
  const _VerifyForm({
    required this.account,
    required this.amount1,
    required this.amount2,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onAmount1Changed,
    required this.onAmount2Changed,
    required this.onSubmit,
  });

  final BankAccount account;
  final Decimal? amount1;
  final Decimal? amount2;
  final bool isSubmitting;
  final String? errorMessage;
  final ValueChanged<Decimal?> onAmount1Changed;
  final ValueChanged<Decimal?> onAmount2Changed;
  final VoidCallback onSubmit;

  bool get _canSubmit =>
      amount1 != null &&
      amount1! > Decimal.zero &&
      amount2 != null &&
      amount2! > Decimal.zero &&
      !isSubmitting;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF242638),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.white54, size: 20),
                const SizedBox(width: 12),
                Text(
                  '${account.bankName} ${account.accountNumberMasked}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '请输入您银行账户收到的 2 笔小额存款金额。\n'
            '这两笔存款通常在 \$0.01 ~ \$0.99 之间，绑卡申请后 1-3 个工作日到账。',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 24),
          DecimalInputField(
            label: '第一笔金额 (USD)',
            onChanged: onAmount1Changed,
            initialValue: amount1,
            prefix: const Text('\$'),
            decimalPlaces: 2,
          ),
          const SizedBox(height: 16),
          DecimalInputField(
            label: '第二笔金额 (USD)',
            onChanged: onAmount2Changed,
            initialValue: amount2,
            prefix: const Text('\$'),
            decimalPlaces: 2,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4747).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFFF4747).withValues(alpha: 0.3)),
              ),
              child: Text(errorMessage!,
                  style: const TextStyle(color: Color(0xFFFF7070), fontSize: 12)),
            ),
          ],
          // Remaining attempts warning
          if (account.remainingVerifyAttempts <= 2) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠️ 剩余验证次数：${account.remainingVerifyAttempts} 次。'
                '超过 5 次将需要删除并重新绑卡。',
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: '确认验证',
              enabled: _canSubmit,
              isLoading: isSubmitting,
              onPressed: _canSubmit ? onSubmit : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _FailedState extends StatelessWidget {
  const _FailedState({required this.account, required this.onDelete});
  final BankAccount account;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, color: Color(0xFFFF4747), size: 64),
            const SizedBox(height: 16),
            const Text('验证失败次数已达上限',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '请删除此银行卡后重新绑定，并确认银行账户中的微存款金额。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4747)),
                onPressed: onDelete,
                child: const Text('删除此银行卡',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
