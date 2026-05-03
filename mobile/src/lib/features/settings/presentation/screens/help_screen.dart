import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/color_tokens.dart';

/// Help & Support screen — PRD §9.
///
/// Phase 1: static list with help center (WebView), customer service,
/// and about (version info + legal links).
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ColorTokens.greenUp.background,
      appBar: AppBar(
        title: const Text('帮助与支持'),
        backgroundColor: ColorTokens.greenUp.surface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _SectionHeader('帮助'),
          _NavItem(
            icon: Icons.help_outline,
            title: '帮助中心',
            subtitle: '常见问题、操作指引',
            onTap: () => _openHelpCenter(context),
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline,
            title: '联系客服',
            subtitle: '工作时间 09:00–18:00 ET',
            onTap: () => _openCustomerService(context),
          ),
          _SectionHeader('关于'),
          _NavItem(
            icon: Icons.info_outline,
            title: '关于我们',
            subtitle: '版本 1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
          _NavItem(
            icon: Icons.privacy_tip_outlined,
            title: '隐私政策',
            subtitle: '了解我们如何保护您的数据',
            onTap: () => _openPrivacyPolicy(context),
          ),
          _NavItem(
            icon: Icons.gavel_outlined,
            title: '服务条款',
            subtitle: '用户协议与法律声明',
            onTap: () => _openTermsOfService(context),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _openHelpCenter(BuildContext context) {
    // H5 WebView — help center URL from environment config
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('帮助中心（WebView）— Phase 1 占位')),
    );
  }

  void _openCustomerService(BuildContext context) {
    final now = DateTime.now().toUtc();
    // 09:00–18:00 ET = 14:00–23:00 UTC
    final isServiceHours = now.hour >= 14 && now.hour < 23;
    if (!isServiceHours) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('客服不在线'),
          content: const Text(
            '客服工作时间为 09:00–18:00 ET（北京时间 22:00–次日 07:00）。\n\n'
            '请在工作时间内再次联系，或在帮助中心查找常见问题解答。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
      return;
    }
    // Phase 1: in-app chat placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('在线客服（Phase 2 实现）')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '跨境证券',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Trading App. All rights reserved.',
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('隐私政策（WebView）— Phase 1 占位')),
    );
  }

  Future<void> _openTermsOfService(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('服务条款（WebView）— Phase 1 占位')),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: ColorTokens.greenUp.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
        color: ColorTokens.greenUp.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 1),
        child: Row(
          children: [
            Icon(icon, size: 22, color: ColorTokens.greenUp.onSurface),
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
