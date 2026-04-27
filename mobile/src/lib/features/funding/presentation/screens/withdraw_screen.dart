import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/screen_protection_service.dart';
import '../../../../shared/extensions/decimal_extensions.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/inputs/decimal_input_field.dart';
import '../../application/account_balance_notifier.dart';
import '../../application/bank_accounts_notifier.dart';
import '../../application/withdraw_form_notifier.dart';
import '../../domain/entities/bank_account.dart';

/// 出金流程 — 3-step: 金额 → 生物识别 → 完成
///
/// Biometric authentication is mandatory before submission per security rules.
class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen>
    with ScreenProtectionMixin {
  static const _colors = ColorTokens.greenUp;
  Decimal? _amount;
  String _channel = 'ACH';
  String? _selectedBankAccountId;

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(withdrawFormProvider);
    final bankAccountsAsync = ref.watch(bankAccountsProvider);
    final balanceAsync = ref.watch(accountBalanceProvider);
    final usableBanks =
        bankAccountsAsync.value?.where((a) => a.isUsable).toList() ?? [];

    return Scaffold(
      backgroundColor: _colors.background,
      appBar: AppBar(
        backgroundColor: _colors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 20),
          color: _colors.onSurface,
          onPressed: () {
            ref.read(withdrawFormProvider.notifier).reset();
            context.pop();
          },
        ),
        title: Text('出金',
            style: TextStyle(
                color: _colors.onSurface, fontWeight: FontWeight.w700)),
      ),
      body: formState.when(
        idle: () => _AmountStep(
          colors: _colors,
          amount: _amount,
          channel: _channel,
          selectedBankAccountId: _selectedBankAccountId,
          usableBanks: usableBanks,
          withdrawableBalance:
              balanceAsync.value?.withdrawableBalance,
          onAmountChanged: (v) => setState(() => _amount = v),
          onChannelChanged: (v) => setState(() => _channel = v),
          onBankChanged: (v) => setState(() => _selectedBankAccountId = v),
          onNext: () {
            final amount = _amount;
            final bankId = _selectedBankAccountId;
            if (amount == null || bankId == null) return;
            ref.read(withdrawFormProvider.notifier).confirm(
                  amount: amount,
                  bankAccountId: bankId,
                  channel: _channel,
                );
          },
        ),
        confirming: (amount, bankAccountId, channel) => _BiometricStep(
          colors: _colors,
          amount: amount,
          channel: channel,
          bank: usableBanks.firstWhere((b) => b.id == bankAccountId,
              orElse: () => usableBanks.first),
          onBack: () =>
              ref.read(withdrawFormProvider.notifier).backToIdle(),
          onConfirm: () => ref
              .read(withdrawFormProvider.notifier)
              .authenticateAndSubmit(),
        ),
        awaitingBiometric: () =>
            const _LoadingStep(label: '等待生物识别验证...'),
        submitting: () => const _LoadingStep(label: '提交出金申请中...'),
        success: (transferId) => _SuccessStep(
          transferId: transferId,
          onDone: () {
            ref.read(withdrawFormProvider.notifier).reset();
            context.pop();
          },
        ),
        error: (message) => _ErrorStep(
          message: message,
          onRetry: () => ref
              .read(withdrawFormProvider.notifier)
              .authenticateAndSubmit(),
          onCancel: () {
            ref.read(withdrawFormProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
    );
  }
}

// ─── Step widgets ─────────────────────────────────────────────────────────────

class _AmountStep extends StatelessWidget {
  const _AmountStep({
    required this.colors,
    required this.amount,
    required this.channel,
    required this.selectedBankAccountId,
    required this.usableBanks,
    required this.withdrawableBalance,
    required this.onAmountChanged,
    required this.onChannelChanged,
    required this.onBankChanged,
    required this.onNext,
  });

  final ColorTokens colors;
  final Decimal? amount;
  final String channel;
  final String? selectedBankAccountId;
  final List<BankAccount> usableBanks;
  final Decimal? withdrawableBalance;
  final ValueChanged<Decimal?> onAmountChanged;
  final ValueChanged<String> onChannelChanged;
  final ValueChanged<String?> onBankChanged;
  final VoidCallback onNext;

  bool get _isAmountValid {
    final a = amount;
    final max = withdrawableBalance;
    if (a == null || a <= Decimal.zero) return false;
    if (max != null && a > max) return false;
    return true;
  }

  bool get _canProceed => _isAmountValid && selectedBankAccountId != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available balance display
          if (withdrawableBalance != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF242638),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('可提现金额',
                      style:
                          TextStyle(color: Colors.white60, fontSize: 13)),
                  Text(
                    withdrawableBalance!.toAmount(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: ['2000', '5000', '10000'].map((v) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: () => onAmountChanged(Decimal.parse(v)),
                  child: Text('\$$v'),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          DecimalInputField(
            label: '出金金额 (USD)',
            onChanged: onAmountChanged,
            initialValue: amount,
            prefix: const Text('\$'),
            decimalPlaces: 2,
            validator: (v) {
              final a = Decimal.tryParse(v ?? '');
              final max = withdrawableBalance;
              if (a == null || a <= Decimal.zero) return '请输入有效金额';
              if (max != null && a > max) return '不能超过可提现金额';
              return null;
            },
          ),
          const SizedBox(height: 20),
          InputDecorator(
            decoration: const InputDecoration(labelText: '出金方式'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: channel,
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 'ACH', child: Text('ACH 转账（免费，3-5 工作日）')),
                  DropdownMenuItem(value: 'WIRE', child: Text('Wire 电汇（\$25，当日到账）')),
                ],
                onChanged: (v) => onChannelChanged(v ?? 'ACH'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (usableBanks.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Text(
                '没有可用的银行卡。银行卡需验证通过且冷却期结束后方可出金。',
                style: TextStyle(color: Colors.orange, fontSize: 13),
              ),
            )
          else
            InputDecorator(
              decoration: const InputDecoration(labelText: '收款银行卡'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedBankAccountId,
                  isDense: true,
                  items: usableBanks
                      .map((b) => DropdownMenuItem(
                            value: b.id,
                            child: Text('\${b.bankName} \${b.accountNumberMasked}'),
                          ))
                      .toList(),
                  onChanged: onBankChanged,
                ),
              ),
            ),
          // Arrival time notice
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4747).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFFF4747).withValues(alpha: 0.2)),
            ),
            child: Text(
              '⏱️ 出金到账：${channel == 'WIRE' ? '当日（工作日 14:00 ET 前）' : '1-3 个工作日'}。'
              '出金需通过生物识别验证。',
              style: const TextStyle(
                  color: Color(0xFFFF7070), fontSize: 12),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: '下一步：生物识别确认',
              enabled: _canProceed,
              onPressed: _canProceed ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _BiometricStep extends StatelessWidget {
  const _BiometricStep({
    required this.colors,
    required this.amount,
    required this.channel,
    required this.bank,
    required this.onBack,
    required this.onConfirm,
  });

  final ColorTokens colors;
  final Decimal amount;
  final String channel;
  final BankAccount bank;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            amount.toAmount(),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _InfoRow(label: '收款银行',
              value: '${bank.bankName} ${bank.accountNumberMasked}'),
          _InfoRow(
              label: '预计到账',
              value: channel == 'WIRE' ? '当日' : '1-3 个工作日'),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF242638),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.fingerprint,
                    size: 56, color: colors.primary),
                const SizedBox(height: 12),
                const Text('请进行生物识别验证',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('使用 Face ID 或 Touch ID 确认出金',
                    style: TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('返回'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: '开始验证',
                  onPressed: onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}

class _LoadingStep extends StatelessWidget {
  const _LoadingStep({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({required this.transferId, required this.onDone});
  final String transferId;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                color: Color(0xFF1A73E8), size: 64),
            const SizedBox(height: 16),
            const Text('出金申请已提交',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('1-3 个工作日内到账',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 8),
            Text('订单号：$transferId',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(label: '完成', onPressed: onDone),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorStep extends StatelessWidget {
  const _ErrorStep({
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF4747), size: 64),
            const SizedBox(height: 16),
            const Text('出金失败',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(label: '重试', onPressed: onRetry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
