import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/security/screen_protection_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../data/settings_repository_impl.dart';

/// Account deactivation screen — PRD §6.4.
///
/// States: pre-check → eligibility failed | eligible → OTP confirm → final confirm → done.
class AccountDeactivationScreen extends ConsumerStatefulWidget {
  const AccountDeactivationScreen({super.key});

  @override
  ConsumerState<AccountDeactivationScreen> createState() =>
      _AccountDeactivationScreenState();
}

class _AccountDeactivationScreenState
    extends ConsumerState<AccountDeactivationScreen>
    with ScreenProtectionMixin {
  _DeactivationStep _step = _DeactivationStep.initial;
  String? _errorMessage;
  bool _loading = false;
  final _otpController = TextEditingController();
  // Persisted idempotency key — reused on retries for the deactivation call
  String? _deactivationIdemKey;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _step == _DeactivationStep.done;
    return PopScope(
      // Prevent back navigation after deactivation — user must close app or be routed out
      canPop: !isDone,
      child: Scaffold(
        backgroundColor: ColorTokens.greenUp.background,
        appBar: AppBar(
          title: const Text('注销账户'),
          backgroundColor: ColorTokens.greenUp.surface,
          elevation: 0,
          automaticallyImplyLeading: !isDone,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : switch (_step) {
                _DeactivationStep.initial => _InitialView(onStart: _checkEligibility),
                _DeactivationStep.ineligible => _IneligibleView(
                    message: _errorMessage ?? '账户不满足注销条件',
                    onBack: () => context.pop(),
                  ),
              _DeactivationStep.eligible => _EligibleView(
                  onConfirm: _showWarningDialog,
                ),
              _DeactivationStep.otpVerify => _OtpVerifyView(
                  controller: _otpController,
                  onSubmit: _submitDeactivation,
                ),
              _DeactivationStep.done => _DoneView(),
            },
      ),
    );
  }

  Future<void> _checkEligibility() async {
    setState(() => _loading = true);
    try {
      await ref.read(settingsRepositoryProvider).checkDeactivationEligibility();
      setState(() {
        _step = _DeactivationStep.eligible;
        _loading = false;
      });
    } on BusinessException catch (e) {
      setState(() {
        _errorMessage = _mapEligibilityError(e);
        _step = _DeactivationStep.ineligible;
        _loading = false;
      });
    } on Object catch (e) {
      AppLogger.warning('checkDeactivationEligibility failed: $e');
      setState(() {
        _errorMessage = '检查失败，请稍后重试';
        _step = _DeactivationStep.ineligible;
        _loading = false;
      });
    }
  }

  void _showWarningDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('注意事项'),
        content: const Text(
          '注销后，您的账户将被关闭。\n\n'
          '• 根据法规要求，您的账户数据将被保留 7 年用于合规审计\n'
          '• 数据不会用于任何商业目的\n'
          '• 注销后无法使用相同手机号重新注册\n\n'
          '此操作不可撤销，是否继续？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              setState(() => _step = _DeactivationStep.otpVerify);
            },
            child: Text('确认注销', style: TextStyle(color: ColorTokens.greenUp.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitDeactivation() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入 6 位验证码')),
      );
      return;
    }
    // Final irreversible confirmation dialog
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('最终确认'),
        content: const Text('您的账户将被立即关闭，此操作不可撤销。确定要注销吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('立即注销', style: TextStyle(color: ColorTokens.greenUp.error)),
          ),
        ],
      ),
    );
    if (finalConfirm != true || !mounted) return;

    setState(() => _loading = true);
    // Generate key once; reuse on network retries (financial-coding-standards Rule 8)
    _deactivationIdemKey ??= const Uuid().v4();
    try {
      await ref.read(settingsRepositoryProvider).deactivateAccount(
            otpCode: otp,
            idempotencyKey: _deactivationIdemKey!,
          );
      // Clear all stored credentials before logout (security-compliance §Mobile Security)
      await ref.read(secureStorageServiceProvider).deleteAll();
      ref.read(authProvider.notifier).logout();
      if (mounted) setState(() => _step = _DeactivationStep.done);
    } on Object catch (e) {
      AppLogger.warning('deactivateAccount failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注销失败，请稍后重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapEligibilityError(BusinessException e) {
    return switch (e.errorCode) {
      'OPEN_POSITIONS' => '您还有未清仓的持仓，请先清仓再申请注销',
      'NON_ZERO_BALANCE' => '您的账户余额不为零，请先提现再申请注销',
      'PENDING_TRANSFERS' => '您有未完成的资金申请，请等待处理完成后再申请注销',
      'OPEN_ORDERS' => '您有未成交的委托订单，请先撤单再申请注销',
      _ => '账户不满足注销条件，请处理后重试',
    };
  }
}

enum _DeactivationStep { initial, ineligible, eligible, otpVerify, done }

class _InitialView extends StatelessWidget {
  const _InitialView({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: ColorTokens.greenUp.error, size: 48),
          const SizedBox(height: 16),
          const Text(
            '注销账户',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '注销账户需满足以下全部条件：\n\n'
            '• 无持仓（持仓市值 = \$0）\n'
            '• 无余额（可用现金 = \$0）\n'
            '• 无待处理资金（无未完成入/出金）\n'
            '• 无未成交委托订单',
            style: TextStyle(color: ColorTokens.greenUp.onSurfaceVariant, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorTokens.greenUp.error,
                side: BorderSide(color: ColorTokens.greenUp.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onStart,
              child: const Text('检查注销条件', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _IneligibleView extends StatelessWidget {
  const _IneligibleView({required this.message, required this.onBack});
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, color: ColorTokens.greenUp.error, size: 56),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onBack,
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}

class _EligibleView extends StatelessWidget {
  const _EligibleView({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          const Text(
            '账户符合注销条件',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '您的账户已满足所有注销前置条件，可以继续注销流程。',
            style: TextStyle(color: ColorTokens.greenUp.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorTokens.greenUp.error,
                side: BorderSide(color: ColorTokens.greenUp.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onConfirm,
              child: const Text('继续注销', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpVerifyView extends StatelessWidget {
  const _OtpVerifyView({required this.controller, required this.onSubmit});
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '身份验证',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '请输入发送至您手机的 6 位验证码以确认身份',
            style: TextStyle(color: ColorTokens.greenUp.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: '6 位验证码',
              prefixIcon: Icon(Icons.lock_outline),
              counterText: '',
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorTokens.greenUp.error,
                side: BorderSide(color: ColorTokens.greenUp.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onSubmit,
              child: const Text('确认注销', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 64),
          SizedBox(height: 16),
          Text(
            '账户已注销',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('感谢您的使用，再见。'),
        ],
      ),
    );
  }
}
