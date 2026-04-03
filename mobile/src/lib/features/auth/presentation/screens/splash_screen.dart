import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../auth/application/auth_notifier.dart';

/// SplashScreen — cold start routing (T01).
///
/// Four scenarios per PRD §4.1:
///   1. No session         → stay on splash (show login CTAs)
///   2. Session + biometric → show biometric login entry
///   3. Session, no biometric → silent refresh → go to market
///   4. Session expired    → show "登录已过期" sheet
///
/// Back-from-background rule (PRD §6.6):
///   > 30 min → go to market tab root
///   ≤ 30 min → resume last page (handled by GoRouter initial location)
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _showExpiredSheet = false;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes to trigger navigation
    Future.microtask(() {
      ref.listenManual(
        authProvider,
        (previous, next) => _handleAuthStateChange(next),
        fireImmediately: true,
      );
    });
  }

  void _handleAuthStateChange(AuthState authState) {
    if (!mounted || _didNavigate) return;

    authState.map(
      unauthenticated: (_) {
        // Stay on splash — user must tap login
      },
      authenticating: (_) {
        // Show loading (biometric login in progress)
      },
      authenticated: (s) {
        if (s.biometricEnabled) {
          // Has biometric — show biometric login entry
          _didNavigate = true;
          context.go(RouteNames.authBiometricLogin);
        } else {
          // No biometric — go straight to market
          _didNavigate = true;
          context.go(RouteNames.market);
        }
      },
      guest: (_) {
        _didNavigate = true;
        context.go(RouteNames.market);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const colors = ColorTokens.greenUp;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          _buildSplashContent(context, colors),
          if (_showExpiredSheet) _buildExpiredSheet(context, colors),
        ],
      ),
    );
  }

  Widget _buildSplashContent(BuildContext context, ColorTokens colors) {
    return SafeArea(
      child: Column(
        children: [
          // Logo area
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.show_chart,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MetaStock',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '美港股跨境交易平台',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push(RouteNames.authLogin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '手机号登录 / 注册',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    ref.read(authProvider.notifier).enterGuestMode();
                    context.go(RouteNames.market);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '先逛逛 →',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '访客行情为延迟 15 分钟数据',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredSheet(BuildContext context, ColorTokens colors) {
    return Container(
      color: Colors.black54,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '登录已过期',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '您的登录状态已过期，请重新登录以继续使用',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _showExpiredSheet = false);
                    context.push(RouteNames.authLogin);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('重新登录'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
