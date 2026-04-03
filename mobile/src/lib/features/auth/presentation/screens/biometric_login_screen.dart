import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/auth/token_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../application/auth_notifier.dart';

/// BiometricLoginScreen — cold-start biometric quick login (T05).
///
/// Prototype: mobile/prototypes/01-auth/hifi/biometric-login.html
/// States: idle / verifying / failed-1 / failed-2 / failed-3
///
/// Rules from PRD §6.2:
///   - Display masked phone number (138****8888)
///   - Continuous fail 3 times → auto-switch to OTP
///   - "使用验证码登录" fallback button always visible
class BiometricLoginScreen extends ConsumerStatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  ConsumerState<BiometricLoginScreen> createState() =>
      _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends ConsumerState<BiometricLoginScreen> {
  final _localAuth = LocalAuthentication();
  bool _isVerifying = false;
  int _failureCount = 0; // max 3 before auto-switch
  String? _errorMessage;
  String _maskedPhone = '';

  static const _maxFailures = 3;

  @override
  void initState() {
    super.initState();
    _loadMaskedPhone();
    // Auto-trigger biometric on open per prototype design
    Future.delayed(const Duration(milliseconds: 300), _triggerBiometric);
  }

  Future<void> _loadMaskedPhone() async {
    // Retrieve stored phone for display (masked format)
    // Token-stored accountId doesn't contain phone — we use a locally cached value
    final tokenService = ref.read(tokenServiceProvider);
    final token = await tokenService.getAccessToken();
    if (token != null && mounted) {
      // In production, phone is stored separately or in JWT claims
      // For now show a generic masked placeholder
      setState(() => _maskedPhone = '');
    }
  }

  Future<void> _triggerBiometric() async {
    if (!mounted || _isVerifying || _failureCount >= _maxFailures) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        _switchToOtp();
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: '使用 Face ID 登录 MetaStock',
      );

      if (authenticated) {
        final success = await ref
            .read(authProvider.notifier)
            .loginWithBiometric();

        if (!mounted) return;
        if (success) {
          context.go(RouteNames.market);
        } else {
          _handleFailure();
        }
      } else {
        // User cancelled
        setState(() {
          _isVerifying = false;
          _errorMessage = null;
        });
      }
    } on Object catch (e, st) {
      AppLogger.warning('Biometric prompt error', error: e, stackTrace: st);
      _handleFailure();
    }
  }

  void _handleFailure() {
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _failureCount++;
    });

    if (_failureCount >= _maxFailures) {
      setState(() {
        _errorMessage = '连续识别失败，正在切换至验证码登录...';
      });
      // PRD: auto-switch after 3 failures
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) _switchToOtp();
      });
    } else {
      setState(() {
        _errorMessage = '识别失败（$_failureCount/3），${_failureCount == 2 ? '再次失败将切换至验证码' : '请重试'}';
      });
    }
  }

  void _switchToOtp() {
    if (!mounted) return;
    context.pushReplacement(RouteNames.authLogin);
  }

  @override
  Widget build(BuildContext context) {
    const colors = ColorTokens.greenUp;
    final isFatalFail = _failureCount >= _maxFailures;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          '快捷登录',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          child: Column(
            children: [
              // App logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.show_chart, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 16),
              if (_maskedPhone.isNotEmpty) ...[
                Text(
                  'Hi，$_maskedPhone',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                isFatalFail
                    ? 'Face ID 验证未通过'
                    : _isVerifying
                        ? '正在验证'
                        : '使用 Face ID 登录',
                style: TextStyle(
                  fontSize: 13,
                  color: isFatalFail ? colors.error : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              // Biometric circle button
              GestureDetector(
                onTap: (!_isVerifying && _failureCount < _maxFailures)
                    ? _triggerBiometric
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFatalFail
                          ? colors.error
                          : _isVerifying
                              ? colors.primary
                              : colors.divider,
                      width: 3,
                    ),
                    color: _isVerifying
                        ? colors.primary.withValues(alpha: 0.08)
                        : colors.surfaceVariant,
                  ),
                  child: Icon(
                    Icons.face,
                    size: 48,
                    color: isFatalFail
                        ? colors.error.withValues(alpha: 0.5)
                        : colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isVerifying
                    ? '验证中，请稍候...'
                    : isFatalFail
                        ? '请使用手机号验证码登录'
                        : '点击图标触发 Face ID',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
              ),
              // Error banners
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isFatalFail
                        ? colors.error.withValues(alpha: 0.08)
                        : const Color(0xFFFAAD14).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFatalFail
                          ? colors.error.withValues(alpha: 0.2)
                          : const Color(0xFFFAAD14).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isFatalFail
                          ? colors.error
                          : const Color(0xFFD48806),
                      fontWeight: _failureCount == 2
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Switch to OTP link
              GestureDetector(
                onTap: _switchToOtp,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '使用手机号登录',
                    style: TextStyle(fontSize: 13, color: colors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
