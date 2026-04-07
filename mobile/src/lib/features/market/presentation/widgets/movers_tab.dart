import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error/error_view.dart';
import '../../../../shared/widgets/loading/skeleton_loader.dart';
import '../../application/movers_provider.dart';
import '../../domain/entities/mover_item.dart';
import 'stock_row_tile.dart';

/// Displays a ranked list of stocks (hot / gainers / losers).
///
/// Used for the "热门", "涨幅榜", and "跌幅榜" tab panels.
///
/// Prototype: prototypes/03-market/hifi/index.html [PANEL: HOT/GAINERS/LOSERS]
class MoversTab extends ConsumerWidget {
  const MoversTab({
    super.key,
    required this.type,
    required this.onStockTap,
    this.market = 'US',
  });

  /// Mover list type — one of [MoverType] constants.
  final String type;
  final String market;
  final void Function(String symbol) onStockTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moversAsync = ref.watch(
      moversProvider(type: type, market: market),
    );

    return moversAsync.when(
      loading: () => const _MoversSkeleton(),
      error: (e, _) => ErrorView(
        message: '加载失败，请重试',
        onRetry: () => ref.invalidate(
          moversProvider(type: type, market: market),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                '暂无数据',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        return Column(
          children: items.map((item) => _MoverRow(item: item, onTap: onStockTap)).toList(),
        );
      },
    );
  }
}

class _MoverRow extends StatelessWidget {
  const _MoverRow({required this.item, required this.onTap});

  final MoverItem item;
  final void Function(String symbol) onTap;

  @override
  Widget build(BuildContext context) {
    final volumeLabel = _formatVolume(item.volume);

    return Column(
      children: [
        StockRowTile(
          symbol: item.symbol,
          name: item.name,
          price: item.price,
          changePct: item.changePct,
          rank: item.rank,
          subtitle: '成交量 $volumeLabel',
          onTap: () => onTap(item.symbol),
        ),
        Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ],
    );
  }

  static String _formatVolume(int vol) {
    if (vol >= 1000000000) return '${(vol / 1000000000).toStringAsFixed(1)}B';
    if (vol >= 1000000) return '${(vol / 1000000).toStringAsFixed(1)}M';
    if (vol >= 1000) return '${(vol / 1000).toStringAsFixed(1)}K';
    return vol.toString();
  }
}

class _MoversSkeleton extends StatelessWidget {
  const _MoversSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const SkeletonLoader(width: 44, height: 16, borderRadius: 4),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoader.text(width: 60),
                    SizedBox(height: 6),
                    SkeletonLoader.text(width: 100),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  SkeletonLoader(width: 64, height: 16, borderRadius: 4),
                  SizedBox(height: 6),
                  SkeletonLoader(width: 52, height: 20, borderRadius: 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
