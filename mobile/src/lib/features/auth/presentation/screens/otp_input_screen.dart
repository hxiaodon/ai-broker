import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/platform/sms_autofill_service.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../application/auth_notifier.dart';
import '../../application/otp_timer_notifier.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/otp_input_widget.dart';
import 'login_screen.dart';

/// OtpInputScreen — 6-digit OTP verification (T03).
///
/// Prototype: mobile/prototypes/01-auth/hifi/otp.html
/// States: filling / verifying / error / lockout / expired
///
/// Rules from PRD §6.1 and §八:
///   - 6-box autofocus, auto-submit when complete
///   - iOS system SMS autofill via AutofillHints.oneTimeCode
///   - Android SMS Retriever (smart_auth package)
///   - Error: show remaining attempts; bold warning at 1 attempt left
///   - Lockout: countdown timer (30 min), no unlock CTA (防社工)
///   - Expiry: clear boxes, show re-send prompt
class OtpInputScreen extends ConsumerStatefulWidget {
  const OtpInputScreen({
    super.key,
    required this.args,
  });

  final OtpScreenArgs args;

  @override
  ConsumerState<OtpInputScreen> createState() => _OtpInputScreenState();
}

class _OtpInputScreenState extends ConsumerState<OtpInputScreen> {
  final _otpController = TextEditingController();
  final _smsAutofill = SmsAutofillService();
  bool _isVerifying = false;
  String? _errorMessage;
  bool _isLastAttemptWarning = false;

  @override
  void initState() {
    super.initState();
    // Android: start SMS Retriever listener (T16)
    _smsAutofill.startListening(_onSmsOtpReceived);
  }

  void _onSmsOtpReceived(String code) {
    if (!mounted || _isVerifying) return;
    _otpController.text = code;
    _verifyOtp(code);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _smsAutofill.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp(String code) async {
    if (code.length != 6 || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final idempotencyKey = const Uuid().v4();
    final repo = ref.read(authRepositoryProvider);

    try {
      final result = await repo.verifyOtp(
        requestId: widget.args.requestId,
        otpCode: code,
        phoneNumber: widget.args.phoneNumber,
        idempotencyKey: idempotencyKey,
      );

      if (!mounted) return;

      if (result.status == OtpVerifyStatus.existingUser && result.token != null) {
        await ref
            .read(authProvider.notifier)
            .loginWithToken(token: result.token!);

        if (!mounted) return;

        // Navigate based on account_status from PRD §4.1
        switch (result.accountStatus) {
          case 'PENDING_KYC':
            context.go(RouteNames.kycRoot);
          case 'ACTIVE':
          default:
            context.go(RouteNames.authBiometricSetup);
        }
      } else {
        // New user — account created, guide to biometric setup
        context.go(RouteNames.authBiometricSetup);
      }
    } on OtpAuthException catch (e) {
      final timerNotifier = ref.read(otpTimerProvider.notifier);

      switch (e.errorCode) {
        case 'OTP_MAX_ATTEMPTS_EXCEEDED':
          timerNotifier.onOtpError(
            remainingAttempts: 0,
            lockoutUntil: e.lockoutUntil,
          );
        case 'OTP_EXPIRED':
          // Handled by timer expiry — clear boxes
          setState(() {
            _errorMessage = null;
            _otpController.clear();
          });
        default:
          final remaining = e.remainingAttempts ?? 0;
          timerNotifier.onOtpError(remainingAttempts: remaining);
          setState(() {
            _otpController.clear();
            _isLastAttemptWarning = remaining == 1;
            _errorMessage = remaining > 0
                ? '验证码不正确，还可重试 $remaining 次'
                : '验证失败';
          });
      }
      AppLogger.warning('OTP verify error: ${e.errorCode}');
    } on Object catch (e, st) {
      AppLogger.error('OTP verify unexpected error', error: e, stackTrace: st);
      setState(() => _errorMessage = '验证失败，请重试');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    final timerState = ref.read(otpTimerProvider);
    if (timerState.resendCountdownSeconds > 0) return;

    final idempotencyKey = const Uuid().v4();
    final repo = ref.read(authRepositoryProvider);

    try {
      final result = await repo.sendOtp(
        phoneNumber: widget.args.phoneNumber,
        idempotencyKey: idempotencyKey,
      );
      ref.read(otpTimerProvider.notifier).onOtpSent(
            resendAfterSeconds: result.retryAfterSeconds,
            expiresInSeconds: result.expiresInSeconds,
          );
      setState(() {
        _otpController.clear();
        _errorMessage = null;
      });
    } on Object catch (e, st) {
      AppLogger.error('OTP resend failed', error: e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    const colors = ColorTokens.greenUp;
    final timerState = ref.watch(otpTimerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        elevation: 0,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            '‹ 修改号码',
            style: TextStyle(fontSize: 15, color: colors.onSurface),
          ),
        ),
        leadingWidth: 100,
        title: Text(
          '验证码',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: _isVerifying
          ? _buildVerifyingState(colors)
          : timerState.isLockedOut
              ? _buildLockoutState(context, colors, timerState)
              : timerState.expiryCountdownSeconds == 0
                  ? _buildExpiredState(context, colors)
                  : _buildFillingState(context, colors, timerState),
    );
  }

  Widget _buildVerifyingState(ColorTokens colors) {
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
            '验证中',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '请稍候...',
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildFillingState(
    BuildContext context,
    ColorTokens colors,
    OtpTimerState timerState,
  ) {
    final canResend = timerState.resendCountdownSeconds == 0;

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
                  '验证手机号',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '已发送 6 位验证码至 ${widget.args.maskedPhone}',
                  style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                OtpInputWidget(
                  controller: _otpController,
                  hasError: _errorMessage != null,
                  onCompleted: _verifyOtp,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAAD14).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFAAD14).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '⚠ $_errorMessage',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFFD48806),
                        fontWeight: _isLastAttemptWarning
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      canResend
                          ? ' '
                          : '${timerState.resendCountdownSeconds} 秒后可重发',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    GestureDetector(
                      onTap: canResend ? _resendOtp : null,
                      child: Text(
                        '重新发送',
                        style: TextStyle(
                          fontSize: 13,
                          color: canResend
                              ? colors.primary
                              : colors.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
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
          child: ElevatedButton(
            onPressed: _otpController.text.length == 6 ? () => _verifyOtp(_otpController.text) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              disabledBackgroundColor: colors.primary.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '验证',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockoutState(
    BuildContext context,
    ColorTokens colors,
    OtpTimerState timerState,
  ) {
    final remaining = timerState.lockoutRemainingSeconds;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    final countdownText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colors.onSurface),
              const SizedBox(height: 16),
              Text(
                '登录失败次数过多',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '账号已暂时锁定，请等待后重试',
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                countdownText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '锁定期间无法登录（防暴力破解）',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          child: OutlinedButton(
            onPressed: () => context.go(RouteNames.authSplash),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurface,
              side: BorderSide(color: colors.divider),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('返回首页'),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredState(BuildContext context, ColorTokens colors) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '验证手机号',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '已发送 6 位验证码至 ${widget.args.maskedPhone}',
                  style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                OtpInputWidget(
                  controller: _otpController,
                  hasError: false,
                  onCompleted: (_) {},
                  colors: colors,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAAD14).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFAAD14).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '验证码已过期',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),
                            Text(
                              'OTP 有效期为 5 分钟，请重新获取',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
          child: ElevatedButton(
            onPressed: _resendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '重新获取验证码',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
