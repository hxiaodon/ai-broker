import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/screen_protection_service.dart';
import '../../../../shared/extensions/decimal_extensions.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/inputs/decimal_input_field.dart';
import '../../application/bank_accounts_notifier.dart';
import '../../application/deposit_form_notifier.dart';
import '../../domain/entities/bank_account.dart';

/// 入金流程 — 3-step: 金额 → 确认 → 完成
class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen>
    with ScreenProtectionMixin {
  static const _colors = ColorTokens.greenUp;
  Decimal? _amount;
  String _channel = 'ACH';
  String? _selectedBankAccountId;

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(depositFormProvider);
    final bankAccounts = ref.watch(bankAccountsProvider).value ?? [];
    final usableBanks = bankAccounts.where((a) => a.isUsable).toList();

    return Scaffold(
      backgroundColor: _colors.background,
      appBar: AppBar(
        backgroundColor: _colors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 20),
          color: _colors.onSurface,
          onPressed: () {
            ref.read(depositFormProvider.notifier).reset();
            context.pop();
          },
        ),
        title: Text('入金',
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
          onAmountChanged: (v) => setState(() => _amount = v),
          onChannelChanged: (v) => setState(() => _channel = v),
          onBankChanged: (v) => setState(() => _selectedBankAccountId = v),
          onNext: () {
            final amount = _amount;
            final bankId = _selectedBankAccountId;
            if (amount == null || bankId == null) return;
            ref.read(depositFormProvider.notifier).confirm(
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
          onBack: () => ref.read(depositFormProvider.notifier).backToIdle(),
          onConfirm: () => ref
              .read(depositFormProvider.notifier)
              .authenticateAndSubmit(),
        ),
        awaitingBiometric: () =>
            const _LoadingStep(label: '等待生物识别验证...'),
        submitting: () => const _LoadingStep(label: '提交入金申请中...'),
        success: (transferId) => _SuccessStep(
          colors: _colors,
          transferId: transferId,
          channel: _channel,
          onDone: () {
            ref.read(depositFormProvider.notifier).reset();
            context.pop();
          },
        ),
        error: (message) => _ErrorStep(
          colors: _colors,
          message: message,
          onRetry: () => ref
              .read(depositFormProvider.notifier)
              .authenticateAndSubmit(),
          onCancel: () {
            ref.read(depositFormProvider.notifier).reset();
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
  final ValueChanged<Decimal?> onAmountChanged;
  final ValueChanged<String> onChannelChanged;
  final ValueChanged<String?> onBankChanged;
  final VoidCallback onNext;

  static final _minDepositAch = Decimal.parse('1.00');
  static final _minDepositWire = Decimal.parse('100.00');

  bool get _canProceed {
    final a = amount;
    if (a == null || selectedBankAccountId == null) return false;
    final min = channel == 'WIRE' ? _minDepositWire : _minDepositAch;
    return a >= min;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick amounts
          Row(
            children: ['1000', '5000', '10000'].map((v) {
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
            label: '入金金额 (USD)',
            onChanged: onAmountChanged,
            initialValue: amount,
            prefix: const Text('\$'),
            decimalPlaces: 2,
          ),
          const SizedBox(height: 20),
          // Channel selector — DropdownButton avoids deprecated FormField.value
          InputDecorator(
            decoration: const InputDecoration(labelText: '入金方式'),
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
          // Bank selector
          if (usableBanks.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Text(
                '没有可用的银行卡。请先绑定并验证银行卡后再入金。',
                style: TextStyle(color: Colors.orange, fontSize: 13),
              ),
            )
          else
            InputDecorator(
              decoration: const InputDecoration(labelText: '出账银行卡'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedBankAccountId,
                  isDense: true,
                  items: usableBanks
                      .map((b) => DropdownMenuItem(
                            value: b.id,
                            child: Text('${b.bankName} ${b.accountNumberMasked}'),
                          ))
                      .toList(),
                  onChanged: onBankChanged,
                ),
              ),
            ),
          if (amount != null && amount! > Decimal.zero) ...[
            const SizedBox(height: 20),
            _FeeSummary(amount: amount!, channel: channel),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: '下一步',
              enabled: _canProceed,
              onPressed: _canProceed ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeSummary extends StatelessWidget {
  const _FeeSummary({required this.amount, required this.channel});
  final Decimal amount;
  final String channel;

  @override
  Widget build(BuildContext context) {
    final fee = channel == 'WIRE' ? Decimal.parse('25') : Decimal.zero;
    final credit = amount - fee;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _FeeRow(label: '手续费', value: fee == Decimal.zero ? '免费' : fee.toAmount()),
          const SizedBox(height: 4),
          _FeeRow(
            label: '预计入账',
            value: credit.toAmount(),
            valueStyle: const TextStyle(
                color: Color(0xFF0DC582),
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.label, required this.value, this.valueStyle});
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 13)),
        Text(value,
            style: valueStyle ??
                const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}

// ─── Biometric step (mirrors WithdrawScreen._BiometricStep) ──────────────────

class _BiometricStep extends StatefulWidget {
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
  State<_BiometricStep> createState() => _BiometricStepState();
}

class _BiometricStepState extends State<_BiometricStep> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            widget.amount.toAmount(),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '入金至 ${widget.bank.bankName} ${widget.bank.accountNumberMasked}',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            widget.channel == 'WIRE' ? '预计当日到账' : '预计 3-5 个工作日到账',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF242638),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.fingerprint, size: 56, color: widget.colors.primary),
                const SizedBox(height: 12),
                const Text('请进行生物识别验证',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('使用 Face ID 或 Touch ID 确认入金',
                    style: TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : widget.onBack,
                  child: const Text('返回'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: '开始验证',
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() => _isSubmitting = true);
                          widget.onConfirm();
                        },
                ),
              ),
            ],
          ),
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
  const _SuccessStep({
    required this.colors,
    required this.transferId,
    required this.channel,
    required this.onDone,
  });

  final ColorTokens colors;
  final String transferId;
  final String channel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final arrivalText = channel == 'WIRE' ? '资金预计当日到账' : '资金将在 3-5 个工作日内到账';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                color: Color(0xFF0DC582), size: 64),
            const SizedBox(height: 16),
            const Text('入金申请已提交',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(arrivalText,
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
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
    required this.colors,
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });

  final ColorTokens colors;
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
            const Text('入金失败',
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
