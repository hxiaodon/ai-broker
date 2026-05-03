import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/color_tokens.dart';
import '../../../../shared/theme/trading_color_scheme.dart';
import '../../application/display_settings_notifier.dart';
import '../../application/notification_preferences_notifier.dart';
import '../../domain/entities/display_settings.dart';
import '../../domain/entities/notification_preferences.dart';

/// General settings — colour scheme, push notifications, language (PRD §7).
class GeneralSettingsScreen extends ConsumerWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayAsync = ref.watch(displaySettingsProvider);
    final notifAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      backgroundColor: ColorTokens.greenUp.background,
      appBar: AppBar(
        title: const Text('通用设置'),
        backgroundColor: ColorTokens.greenUp.surface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // ── Colour Scheme ───────────────────────────────────────────────
          _SectionHeader('涨跌颜色方案'),
          displayAsync.when(
            loading: () => const SizedBox(height: 48),
            error: (_, _) => const SizedBox.shrink(),
            data: (DisplaySettings display) => Column(
              children: [
                _ColorSchemeOption(
                  label: '绿涨红跌',
                  description: '+86 大陆用户默认',
                  scheme: TradingColorScheme.greenUp,
                  selected: display.colorScheme == TradingColorScheme.greenUp,
                  onTap: () => ref
                      .read(displaySettingsProvider.notifier)
                      .setColorScheme(TradingColorScheme.greenUp),
                ),
                _ColorSchemeOption(
                  label: '红涨绿跌',
                  description: '+852 香港用户默认',
                  scheme: TradingColorScheme.redUp,
                  selected: display.colorScheme == TradingColorScheme.redUp,
                  onTap: () => ref
                      .read(displaySettingsProvider.notifier)
                      .setColorScheme(TradingColorScheme.redUp),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorTokens.greenUp.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '颜色方案更改立即生效，全 App 同步。平盘（0.00%）始终显示灰色。',
              style: TextStyle(
                color: ColorTokens.greenUp.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),

          // ── Push Notifications ──────────────────────────────────────────
          _SectionHeader('推送通知'),
          notifAsync.when(
            loading: () => const SizedBox(height: 200),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '加载失败，请下拉刷新',
                style: TextStyle(color: ColorTokens.greenUp.onSurfaceVariant),
              ),
            ),
            data: (NotificationPreferences prefs) => Column(
              children: [
                _NotifToggle(
                  label: '交易通知',
                  description: '成交、撤单、拒绝、GTC 到期',
                  value: prefs.tradingEnabled,
                  mutable: true,
                  onChanged: (v) => ref
                      .read(notificationPreferencesProvider.notifier)
                      .toggle(category: NotificationCategory.trading, enabled: v),
                ),
                _NotifToggle(
                  label: '资金通知',
                  description: '入金、出金、微存款验证',
                  value: prefs.fundingEnabled,
                  mutable: true,
                  onChanged: (v) => ref
                      .read(notificationPreferencesProvider.notifier)
                      .toggle(category: NotificationCategory.funding, enabled: v),
                ),
                _NotifToggle(
                  label: '开户通知',
                  description: 'KYC 结果、W-8BEN 提醒',
                  value: prefs.kycEnabled,
                  mutable: true,
                  onChanged: (v) => ref
                      .read(notificationPreferencesProvider.notifier)
                      .toggle(category: NotificationCategory.kyc, enabled: v),
                ),
                _NotifToggle(
                  label: '系统公告',
                  description: '维护通知、时间变更',
                  value: prefs.systemAnnouncementsEnabled,
                  mutable: true,
                  onChanged: (v) => ref
                      .read(notificationPreferencesProvider.notifier)
                      .toggle(
                        category: NotificationCategory.systemAnnouncements,
                        enabled: v,
                      ),
                ),
                _NotifToggle(
                  label: '安全通知',
                  description: '新设备登录、异常活动 — 不可关闭',
                  value: true,
                  mutable: false,
                  onChanged: null,
                ),
              ],
            ),
          ),

          // ── Language ────────────────────────────────────────────────────
          _SectionHeader('语言'),
          Container(
            color: ColorTokens.greenUp.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '语言',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '目前仅支持中文，更多语言即将支持',
                        style: TextStyle(
                          color: ColorTokens.greenUp.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '简体中文',
                  style: TextStyle(
                    color: ColorTokens.greenUp.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Colour Scheme Option ─────────────────────────────────────────────────────

class _ColorSchemeOption extends StatelessWidget {
  const _ColorSchemeOption({
    required this.label,
    required this.description,
    required this.scheme,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final TradingColorScheme scheme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gainColor = scheme == TradingColorScheme.greenUp
        ? Colors.green
        : ColorTokens.greenUp.error;
    final lossColor = scheme == TradingColorScheme.greenUp
        ? ColorTokens.greenUp.error
        : Colors.green;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: ColorTokens.greenUp.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 1),
        child: Row(
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: gainColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '涨',
                      style: TextStyle(
                        color: gainColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: lossColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '跌',
                      style: TextStyle(
                        color: lossColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: ColorTokens.greenUp.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: ColorTokens.greenUp.primary, size: 22)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: ColorTokens.greenUp.onSurfaceVariant,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  const _NotifToggle({
    required this.label,
    required this.description,
    required this.value,
    required this.mutable,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final bool mutable;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.greenUp.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    description,
                    style: TextStyle(
                      color: ColorTokens.greenUp.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Opacity(
            opacity: mutable ? 1.0 : 0.5,
            child: Switch(
              value: value,
              onChanged: mutable ? onChanged : null,
              activeThumbColor: ColorTokens.greenUp.primary,
            ),
          ),
        ],
      ),
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
