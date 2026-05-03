import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/color_tokens.dart';
import '../../application/trade_settings_notifier.dart';
import '../../domain/entities/trade_settings.dart';

/// Trading preferences screen — PRD §8.
///
/// All settings stored locally in SharedPreferences.
class TradeSettingsScreen extends ConsumerWidget {
  const TradeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(tradeSettingsProvider);

    return Scaffold(
      backgroundColor: ColorTokens.greenUp.background,
      appBar: AppBar(
        title: const Text('交易设置'),
        backgroundColor: ColorTokens.greenUp.surface,
        elevation: 0,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('加载失败')),
        data: (TradeSettings settings) => _SettingsBody(settings: settings),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});
  final TradeSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void save(TradeSettings updated) =>
        ref.read(tradeSettingsProvider.notifier).saveSettings(updated);

    return ListView(
      children: [
        // ── Default Order Type ──────────────────────────────────────────
        _SegmentedItem<DefaultOrderType>(
          title: '默认订单类型',
          subtitle: '新建委托时的默认类型',
          options: {
            DefaultOrderType.limit: '限价单',
            DefaultOrderType.market: '市价单',
          },
          selected: settings.defaultOrderType,
          onChanged: (v) => save(settings.copyWith(defaultOrderType: v)),
        ),
        // ── Default Validity ────────────────────────────────────────────
        _SegmentedItem<DefaultOrderValidity>(
          title: '默认有效期',
          subtitle: '当日 (DAY) 或 GTC',
          options: {
            DefaultOrderValidity.day: '当日 DAY',
            DefaultOrderValidity.gtc: 'GTC',
          },
          selected: settings.defaultValidity,
          onChanged: (v) => save(settings.copyWith(defaultValidity: v)),
        ),
        // ── Confirmation Method ─────────────────────────────────────────
        _SegmentedItem<OrderConfirmationMethod>(
          title: '委托确认方式',
          subtitle: '下单时的验证方式',
          options: {
            OrderConfirmationMethod.slideAndBiometric: '滑动 + 生物识别',
            OrderConfirmationMethod.slideOnly: '仅滑动',
          },
          selected: settings.confirmationMethod,
          onChanged: (v) => save(settings.copyWith(confirmationMethod: v)),
        ),
        // ── Large Order Threshold ───────────────────────────────────────
        _SegmentedItem<LargeOrderThreshold>(
          title: '大额委托提醒',
          subtitle: '超过此金额时弹出确认',
          options: {
            LargeOrderThreshold.usd5000: '\$5,000',
            LargeOrderThreshold.usd10000: '\$10,000',
            LargeOrderThreshold.usd20000: '\$20,000',
          },
          selected: settings.largeOrderThreshold,
          onChanged: (v) => save(settings.copyWith(largeOrderThreshold: v)),
        ),
        // ── Price Deviation ─────────────────────────────────────────────
        _SegmentedItem<PriceDeviationWarning>(
          title: '价格偏离警告',
          subtitle: '委托价偏离市价超过此比例时警告',
          options: {
            PriceDeviationWarning.pct3: '3%',
            PriceDeviationWarning.pct5: '5%',
            PriceDeviationWarning.pct10: '10%',
            PriceDeviationWarning.disabled: '关闭',
          },
          selected: settings.priceDeviationWarning,
          onChanged: (v) => save(settings.copyWith(priceDeviationWarning: v)),
        ),
        // ── Extended Hours ──────────────────────────────────────────────
        _ExtendedHoursItem(settings: settings, onSave: save),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _SegmentedItem<T> extends StatelessWidget {
  const _SegmentedItem({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.greenUp.surface,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          Text(
            subtitle,
            style: TextStyle(color: ColorTokens.greenUp.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: options.entries.map((e) {
              final isSelected = e.key == selected;
              return ChoiceChip(
                label: Text(e.value),
                selected: isSelected,
                selectedColor: ColorTokens.greenUp.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected ? ColorTokens.greenUp.primary : ColorTokens.greenUp.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => onChanged(e.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ExtendedHoursItem extends StatelessWidget {
  const _ExtendedHoursItem({required this.settings, required this.onSave});
  final TradeSettings settings;
  final ValueChanged<TradeSettings> onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.greenUp.surface,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '允许盘前盘后交易',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '首次开启需确认风险说明',
                      style: TextStyle(
                        color: ColorTokens.greenUp.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: settings.extendedHoursEnabled,
                onChanged: (v) => _handleToggle(context, v),
                activeThumbColor: ColorTokens.greenUp.primary,
              ),
            ],
          ),
          if (settings.extendedHoursEnabled)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '盘前盘后交易流动性较低，价格波动可能较大，请谨慎操作。',
                style: TextStyle(
                  color: ColorTokens.greenUp.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleToggle(BuildContext context, bool enable) async {
    if (!enable) {
      onSave(settings.copyWith(extendedHoursEnabled: false));
      return;
    }
    // First-time enable: show risk disclosure
    if (!settings.extendedHoursRiskAccepted) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('盘前盘后交易风险说明'),
          content: const Text(
            '盘前（Pre-Market）和盘后（After-Hours）交易存在以下风险：\n\n'
            '• 流动性较低，可能无法成交\n'
            '• 价格波动比正常交易时段更剧烈\n'
            '• 仅支持限价单\n\n'
            '继续操作即代表您已了解并接受上述风险。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('我已了解，继续'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
    }
    onSave(
      settings.copyWith(
        extendedHoursEnabled: true,
        extendedHoursRiskAccepted: true,
      ),
    );
  }
}
