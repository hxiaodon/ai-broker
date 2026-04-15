import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../application/auth_notifier.dart';
import '../../application/otp_timer_notifier.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/country_code_picker.dart';
import '../widgets/phone_input_widget.dart';

/// LoginScreen — phone number input page (T02).
///
/// Prototype: mobile/prototypes/01-auth/hifi/phone.html
/// States: [input] / [sending]
///
/// Rules from PRD §6.1:
///   - +86 China: 11 digits
///   - +852 HK: 8 digits
///   - 60s resend cooldown (handled in OtpInputScreen)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  CountryCode _selectedCountry = CountryCode.china;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isPhoneValid {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return switch (_selectedCountry) {
      CountryCode.china => digits.length == 11,
      CountryCode.hongKong => digits.length == 8,
    };
  }

  String get _e164Phone {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return '${_selectedCountry.dialCode}$digits';
  }

  Future<void> _sendOtp() async {
    if (!_isPhoneValid) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final idempotencyKey = const Uuid().v4();
    final repo = ref.read(authRepositoryProvider);

    try {
      final result = await repo.sendOtp(
        phoneNumber: _e164Phone,
        idempotencyKey: idempotencyKey,
      );

      // Start OTP countdown timers
      ref.read(otpTimerProvider.notifier).onOtpSent(
            resendAfterSeconds: result.retryAfterSeconds,
            expiresInSeconds: result.expiresInSeconds,
          );

      if (!mounted) return;
      context.push(
        RouteNames.authOtp,
        extra: OtpScreenArgs(
          requestId: result.requestId,
          phoneNumber: _e164Phone,
          maskedPhone: result.maskedPhoneNumber,
          idempotencyKey: idempotencyKey,
        ),
      );
    } on BusinessException catch (e) {
      AppLogger.warning('SendOtp business error: ${e.errorCode}');
      setState(() {
        _errorMessage = _mapErrorCode(e.errorCode) ?? e.message;
      });
    } on NetworkException catch (e) {
      AppLogger.warning('SendOtp network error', error: e);
      setState(() {
        _errorMessage = '网络连接失败，请检查网络后重试';
      });
    } on Object catch (e, st) {
      AppLogger.error('SendOtp unexpected error', error: e, stackTrace: st);
      setState(() {
        _errorMessage = '发送失败，请稍后重试';
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String? _mapErrorCode(String? code) => switch (code) {
        'RATE_LIMIT_EXCEEDED' => '发送过于频繁，请稍后重试',
        'ACCOUNT_SUSPENDED' => '账号已被暂停，请联系客服',
        'INVALID_PHONE_FORMAT' => '手机号格式不正确',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    const colors = ColorTokens.greenUp;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        elevation: 0,
        title: Text(
          '登录 / 注册',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: _isSending ? _buildSendingState(colors) : _buildInputState(colors),
    );
  }

  Widget _buildSendingState(ColorTokens colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '发送中...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '正在发送验证码',
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildInputState(ColorTokens colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '输入手机号',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '新用户将自动创建账号',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                PhoneInputWidget(
                  controller: _phoneController,
                  selectedCountry: _selectedCountry,
                  onCountryChanged: (c) =>
                      setState(() => _selectedCountry = c),
                  onChanged: (_) => setState(() => _errorMessage = null),
                  colors: colors,
                ),
                const SizedBox(height: 8),
                Text(
                  '支持 +86（中国大陆，11 位）· +852（香港，8 位）',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(fontSize: 13, color: colors.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPhoneValid ? _sendOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    disabledBackgroundColor:
                        colors.primary.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '获取验证码',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).enterGuestMode();
                  context.go(RouteNames.market);
                },
                child: const Text('先逛逛'),
              ),
              const SizedBox(height: 4),
              _buildFooterNote(colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterNote(ColorTokens colors) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.5)),
        children: [
          const TextSpan(text: '继续即代表同意'),
          TextSpan(
            text: '《用户协议》',
            style: TextStyle(color: colors.primary),
          ),
          const TextSpan(text: '和'),
          TextSpan(
            text: '《隐私政策》',
            style: TextStyle(color: colors.primary),
          ),
        ],
      ),
    );
  }
}

/// Route extra args passed to OtpInputScreen.
class OtpScreenArgs {
  const OtpScreenArgs({
    required this.requestId,
    required this.phoneNumber,
    required this.maskedPhone,
    required this.idempotencyKey,
  });

  final String requestId;
  final String phoneNumber;
  final String maskedPhone;
  final String idempotencyKey;
}
