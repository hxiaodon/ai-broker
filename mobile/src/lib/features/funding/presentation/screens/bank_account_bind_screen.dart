import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/screen_protection_service.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../kyc/application/kyc_session_notifier.dart';
import '../../application/bank_bind_notifier.dart';

/// 绑定银行卡 — US ACH bank account binding flow.
///
/// Steps:
///   1. Fill account details (name pre-filled from KYC, not editable)
///   2. Submit → server initiates micro-deposit
///   3. Success state: "等待微存款到账" with cooldown end date
///
/// Micro-deposit verification happens separately via MicroDepositVerifyScreen
/// (accessed from FundingScreen bank card list when status is pending).
class BankAccountBindScreen extends ConsumerStatefulWidget {
  const BankAccountBindScreen({super.key});

  @override
  ConsumerState<BankAccountBindScreen> createState() =>
      _BankAccountBindScreenState();
}

class _BankAccountBindScreenState
    extends ConsumerState<BankAccountBindScreen>
    with ScreenProtectionMixin {
  static const _colors = ColorTokens.greenUp;
  final _formKey = GlobalKey<FormState>();
  final _routingNumberCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();

  @override
  void dispose() {
    _routingNumberCtrl.dispose();
    _accountNumberCtrl.dispose();
    _bankNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bindState = ref.watch(bankBindProvider);
    // KYC-verified legal name — same-name account principle (同名账户原则)
    final kycName = ref.watch(kycSessionProvider).maybeWhen(
          active: (s) => s.accountHolderName ?? '',
          orElse: () => '',
        );

    return Scaffold(
      backgroundColor: _colors.background,
      appBar: AppBar(
        backgroundColor: _colors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 20),
          color: _colors.onSurface,
          onPressed: () {
            ref.read(bankBindProvider.notifier).reset();
            context.pop();
          },
        ),
        title: Text('绑定银行卡',
            style: TextStyle(
                color: _colors.onSurface, fontWeight: FontWeight.w700)),
      ),
      body: bindState.when(
        idle: () => _FormStep(
          formKey: _formKey,
          routingCtrl: _routingNumberCtrl,
          accountCtrl: _accountNumberCtrl,
          bankNameCtrl: _bankNameCtrl,
          colors: _colors,
          kycName: kycName,
          onSubmit: () {
            if (_formKey.currentState?.validate() ?? false) {
              ref.read(bankBindProvider.notifier).submit(
                    accountName: kycName,
                    accountNumber: _accountNumberCtrl.text.trim(),
                    routingNumber: _routingNumberCtrl.text.trim(),
                    bankName: _bankNameCtrl.text.trim(),
                  );
            }
          },
        ),
        submitting: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('提交绑卡申请...', style: TextStyle(color: Colors.white60)),
            ],
          ),
        ),
        pendingMicroDeposit: (bankAccountId, cooldownEndsAt) =>
            _PendingMicroDepositStep(
          cooldownEndsAt: cooldownEndsAt,
          onDone: () {
            ref.read(bankBindProvider.notifier).reset();
            context.pop();
          },
        ),
        error: (message) => _ErrorStep(
          message: message,
          onRetry: () => ref.read(bankBindProvider.notifier).reset(),
        ),
      ),
    );
  }
}

class _FormStep extends StatelessWidget {
  const _FormStep({
    required this.formKey,
    required this.routingCtrl,
    required this.accountCtrl,
    required this.bankNameCtrl,
    required this.colors,
    required this.kycName,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController routingCtrl;
  final TextEditingController accountCtrl;
  final TextEditingController bankNameCtrl;
  final ColorTokens colors;
  final String kycName;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Text(
                '⚠️ 银行账户名称必须与 KYC 认证时的姓名一致（同名账户原则），否则绑定将被拒绝。',
                style: TextStyle(color: Colors.amber, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
            // Account name — read-only, from KYC verified name
            TextFormField(
              initialValue: kycName,
              enabled: false,
              decoration: const InputDecoration(
                labelText: '账户持有人姓名',
                helperText: '与 KYC 认证姓名一致，不可修改',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: routingCtrl,
              keyboardType: TextInputType.number,
              maxLength: 9,
              decoration: const InputDecoration(
                labelText: 'Routing Number',
                helperText: '9 位美国银行路由号码',
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.length != 9) return '请输入 9 位 Routing Number';
                if (!RegExp(r'^\d{9}$').hasMatch(v)) return '只能包含数字';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: accountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                helperText: '银行账户号码（不会明文保存）',
              ),
              validator: (v) {
                if (v == null || v.length < 4) return '请输入账户号码';
                if (!RegExp(r'^\d+$').hasMatch(v)) return '只能包含数字';
                return null;
              },
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: bankNameCtrl,
              decoration: const InputDecoration(
                labelText: '银行名称',
                hintText: '如：Chase, Bank of America',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入银行名称';
                return null;
              },
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ℹ️ 绑卡后，平台将向您的银行账户发送 2 笔小额存款（通常 1-3 个工作日）。'
                '请在 App 内确认这 2 笔金额以完成验证。验证通过后有 3 天冷却期，之后方可入/出金。',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(label: '提交绑卡申请', onPressed: onSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingMicroDepositStep extends StatelessWidget {
  const _PendingMicroDepositStep({
    required this.cooldownEndsAt,
    required this.onDone,
  });

  final DateTime cooldownEndsAt;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final local = cooldownEndsAt.toLocal();
    final dateStr =
        '${local.year}-${_p(local.month)}-${_p(local.day)} ${_p(local.hour)}:${_p(local.minute)}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: Color(0xFFFFA940), size: 64),
            const SizedBox(height: 16),
            const Text('绑卡申请已提交',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              '平台将在 1-3 个工作日内向您的银行账户发送 2 笔小额存款。\n'
              '收到后，请回到此页面点击银行卡进行验证。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA940).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '预计激活时间：$dateStr（完成微存款验证后）',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFFFA940), fontSize: 12),
              ),
            ),
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

  String _p(int v) => v.toString().padLeft(2, '0');
}

class _ErrorStep extends StatelessWidget {
  const _ErrorStep({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

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
            const Text('绑卡失败',
                style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 32),
            PrimaryButton(label: '重试', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
