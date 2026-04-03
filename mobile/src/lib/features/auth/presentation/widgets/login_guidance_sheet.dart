import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/theme/color_tokens.dart';

/// Shows the login guidance bottom sheet for guest users (T08).
///
/// PRD §4.3: Triggered when a guest taps buy/sell in stock detail.
/// Options:
///   - "立即登录" → OTP login flow
///   - "继续浏览" → dismiss sheet
///
/// Usage:
///   ```dart
///   await showLoginGuidanceSheet(context, trigger: '买入');
///   ```
Future<void> showLoginGuidanceSheet(
  BuildContext context, {
  required String trigger,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: ColorTokens.greenUp.surfaceVariant,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) => _LoginGuidanceSheet(trigger: trigger),
  );
}

/// Internal widget for the login guidance sheet.
class _LoginGuidanceSheet extends StatelessWidget {
  const _LoginGuidanceSheet({required this.trigger});

  final String trigger;

  @override
  Widget build(BuildContext context) {
    const colors = ColorTokens.greenUp;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
            '登录后才能$trigger',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '注册仅需手机号 + 验证码，30 秒完成。\n登录后即可进行真实交易操作。',
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
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
              child: const Text(
                '立即登录',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurface,
                side: BorderSide(color: colors.divider),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('继续浏览'),
            ),
          ),
        ],
      ),
    );
  }
}
