import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../application/auth_notifier.dart';

/// GuestPlaceholderScreen — shown for order / portfolio / profile tab
/// when the user is in guest mode (T07).
///
/// PRD §6.4: Tab 'ords', 'portfolio', 'profile' are blocked for guests.
/// Displays a login CTA and a brief explanatory copy.
class GuestPlaceholderScreen extends ConsumerWidget {
  const GuestPlaceholderScreen({
    super.key,
    required this.tabName,
  });

  /// Human-readable tab name shown in the copy text.
  final String tabName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const colors = ColorTokens.greenUp;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 36,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '登录后查看$tabName',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '注册仅需手机号 + 验证码，30 秒完成',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
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
                    '立即登录 / 注册',
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
                  // Stay in guest mode but go back to market tab
                  ref.read(authProvider.notifier).enterGuestMode();
                  context.go(RouteNames.market);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '继续访客浏览',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
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
