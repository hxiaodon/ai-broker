import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/screen_protection_service.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../application/change_phone_notifier.dart';

/// Change phone number screen — PRD §6.3.
///
/// Flow: enter new phone → verify old OTP → verify new OTP → success.
class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen>
    with ScreenProtectionMixin {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePhoneProvider);

    ref.listen<ChangePhoneState>(changePhoneProvider, (_, next) {
      next.maybeWhen(
        success: () => _showSuccessAndPop(context, ref),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: ColorTokens.greenUp.background,
      appBar: AppBar(
        title: const Text('更换手机号'),
        backgroundColor: ColorTokens.greenUp.surface,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            ref.read(changePhoneProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: state.when(
        idle: () => _EnterNewPhoneView(
          onSubmit: (phone) => ref
              .read(changePhoneProvider.notifier)
              .startFlow(newPhone: phone),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        step: (ChangePhoneStep step, String newPhone) => switch (step) {
          ChangePhoneStep.enterNewPhone => _EnterNewPhoneView(
              onSubmit: (phone) => ref
                  .read(changePhoneProvider.notifier)
                  .startFlow(newPhone: phone),
            ),
          ChangePhoneStep.verifyOldOtp => _OtpView(
              title: '验证当前手机号',
              subtitle: '请输入发送至您当前手机的验证码',
              onSubmit: (otp) =>
                  ref.read(changePhoneProvider.notifier).submitOldOtp(otp),
            ),
          ChangePhoneStep.verifyNewOtp => _OtpView(
              title: '验证新手机号',
              subtitle: '请输入发送至 $newPhone 的验证码',
              onSubmit: (otp) =>
                  ref.read(changePhoneProvider.notifier).submitNewOtp(otp),
            ),
          ChangePhoneStep.success => const Center(child: CircularProgressIndicator()),
        },
        error: (String message) => _ErrorView(
          message: message,
          onRetry: () =>
              ref.read(changePhoneProvider.notifier).reset(),
        ),
        success: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showSuccessAndPop(BuildContext context, WidgetRef ref) {
    ref.read(changePhoneProvider.notifier).reset();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('更换成功'),
        content: const Text('手机号已成功更换。为保障账户安全，所有已登录设备将需要重新登录。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _EnterNewPhoneView extends StatefulWidget {
  const _EnterNewPhoneView({required this.onSubmit});
  final ValueChanged<String> onSubmit;

  @override
  State<_EnterNewPhoneView> createState() => _EnterNewPhoneViewState();
}

class _EnterNewPhoneViewState extends State<_EnterNewPhoneView> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请输入新手机号',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '我们将向您当前绑定的手机号发送验证码，确认身份后再更换为新号码。',
              style: TextStyle(color: ColorTokens.greenUp.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '新手机号（含区号，如 +86 138...）',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入手机号';
                if (!RegExp(r'^\+\d{7,15}$').hasMatch(v.trim())) {
                  return '请输入有效的国际格式手机号（如 +861381234...）';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSubmit(_controller.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTokens.greenUp.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  '下一步',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpView extends StatefulWidget {
  const _OtpView({
    required this.title,
    required this.subtitle,
    required this.onSubmit,
  });

  final String title;
  final String subtitle;
  final ValueChanged<String> onSubmit;

  @override
  State<_OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<_OtpView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            style: TextStyle(color: ColorTokens.greenUp.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
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
            child: ElevatedButton(
              onPressed: () {
                if (_controller.text.trim().length == 6) {
                  widget.onSubmit(_controller.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorTokens.greenUp.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                '验证',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: ColorTokens.greenUp.error, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('重新开始'),
          ),
        ],
      ),
    );
  }
}
