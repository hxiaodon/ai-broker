import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../../shared/widgets/loading/skeleton_loader.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../application/account_status_notifier.dart';
import '../../application/user_profile_notifier.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/entities/user_profile.dart';
import '../../../trading/application/portfolio_summary_provider.dart';
import '../../../trading/domain/entities/portfolio_summary.dart';

/// "我的" tab root screen.
///
/// Shows: user card (avatar + name + KYC badge) + asset summary card + menu sections.
class SettingsHomeScreen extends ConsumerWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final statusAsync = ref.watch(accountStatusProvider);
    final summaryAsync = ref.watch(portfolioSummaryProvider);

    return Scaffold(
      backgroundColor: ColorTokens.greenUp.background,
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: ColorTokens.greenUp.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(accountStatusProvider);
          ref.invalidate(portfolioSummaryProvider);
        },
        child: ListView(
          children: [
            _ProfileHeader(profileAsync: profileAsync, statusAsync: statusAsync),
            _AssetSummaryCard(summaryAsync: summaryAsync),
            const SizedBox(height: 16),
            _MenuSection(
              title: '资金',
              items: [
                _MenuItem(
                  icon: Icons.credit_card_outlined,
                  title: '银行卡管理',
                  subtitle: '管理绑定的银行卡',
                  onTap: () => context.push(RouteNames.bankAccountBind),
                ),
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: '资金流水',
                  subtitle: '查看账户收支记录',
                  onTap: () => context.push(RouteNames.funding),
                ),
              ],
            ),
            _MenuSection(
              title: '账户',
              items: [
                _MenuItem(
                  icon: Icons.person_outline,
                  title: '个人资料',
                  subtitle: 'KYC 信息、税务表单',
                  onTap: () => context.push(RouteNames.profile),
                ),
                _MenuItem(
                  icon: Icons.security_outlined,
                  title: '安全设置',
                  subtitle: '生物识别、设备管理、换号',
                  onTap: () => context.push(RouteNames.securitySettings),
                ),
                _MenuItem(
                  icon: Icons.tune_outlined,
                  title: '通用设置',
                  subtitle: '涨跌色方案、推送通知',
                  onTap: () => context.push(RouteNames.generalSettings),
                ),
                _MenuItem(
                  icon: Icons.candlestick_chart_outlined,
                  title: '交易设置',
                  subtitle: '默认订单类型、确认方式',
                  onTap: () => context.push(RouteNames.tradeSettings),
                ),
              ],
            ),
            _MenuSection(
              title: '帮助',
              items: [
                _MenuItem(
                  icon: Icons.help_outline,
                  title: '帮助中心',
                  subtitle: '常见问题和操作指引',
                  onTap: () => context.push(RouteNames.helpCenter),
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  title: '关于',
                  subtitle: '版本信息、法律声明',
                  onTap: () => context.push(RouteNames.helpCenter),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorTokens.greenUp.error,
                  side: BorderSide(color: ColorTokens.greenUp.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _confirmLogout(context, ref),
                child: const Text('退出登录'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: Text('退出', style: TextStyle(color: ColorTokens.greenUp.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profileAsync,
    required this.statusAsync,
  });

  final AsyncValue<UserProfile> profileAsync;
  final AsyncValue<AccountStatus> statusAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorTokens.greenUp.primary, ColorTokens.greenUp.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: profileAsync.when(
        loading: () => const SkeletonLoader(width: double.infinity, height: 80),
        error: (_, _) => const SizedBox(height: 80),
        data: (profile) => Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                profile.fullName.isNotEmpty ? profile.fullName[0] : '?',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  statusAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (status) => _KycBadge(
                      tier: profile.kycTier,
                      accountId: profile.accountId,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KycBadge extends StatelessWidget {
  const _KycBadge({required this.tier, required this.accountId});
  final KycTier tier;
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final isTier2 = tier == KycTier.tier2;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: isTier2
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.orange.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isTier2 ? Colors.green : Colors.orange,
              width: 1,
            ),
          ),
          child: Text(
            isTier2 ? '已认证 ✓' : 'KYC 审核中',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'ID: $accountId',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
        ),
      ],
    );
  }
}

// ─── Asset Summary Card ───────────────────────────────────────────────────────

class _AssetSummaryCard extends StatelessWidget {
  const _AssetSummaryCard({required this.summaryAsync});
  final AsyncValue<PortfolioSummary> summaryAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorTokens.greenUp.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: summaryAsync.when(
        loading: () => const SkeletonLoader(width: double.infinity, height: 60),
        error: (_, _) => const SizedBox(height: 60),
        data: (summary) => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '总资产 (USD)',
                    style: TextStyle(
                      color: ColorTokens.greenUp.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${summary.totalEquity.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Builder(
              builder: (context) => Row(
                children: [
                  _QuickActionButton(
                    label: '入金',
                    icon: Icons.add_circle_outline,
                    onTap: () => context.push(RouteNames.deposit),
                  ),
                  const SizedBox(width: 12),
                  _QuickActionButton(
                    label: '出金',
                    icon: Icons.remove_circle_outline,
                    onTap: () => context.push(RouteNames.withdraw),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: ColorTokens.greenUp.primary, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: ColorTokens.greenUp.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu Section ─────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});
  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: ColorTokens.greenUp.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          color: ColorTokens.greenUp.surface,
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ColorTokens.greenUp.divider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ColorTokens.greenUp.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: ColorTokens.greenUp.onSurface),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: ColorTokens.greenUp.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ColorTokens.greenUp.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}
