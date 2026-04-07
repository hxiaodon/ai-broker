import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../auth/application/auth_notifier.dart';

/// Displays a "15-minute delayed quote" banner in guest mode.
///
/// Shown at the top of MarketHomeScreen and SearchScreen when the user
/// is a guest. Hides automatically once the user is authenticated.
///
/// Prototype: prototypes/03-market/hifi/index.html [STATE: guest]
class DelayedQuoteBanner extends ConsumerWidget {
  const DelayedQuoteBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(authProvider).maybeWhen(
      guest: () => true,
      orElse: () => false,
    );

    if (!isGuest) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push(RouteNames.authLogin),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: const Color(0xFF1A3A5C),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF90CAF9)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '当前为延迟行情（15分钟），登录后查看实时数据',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF90CAF9),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '去登录',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF1A73E8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
