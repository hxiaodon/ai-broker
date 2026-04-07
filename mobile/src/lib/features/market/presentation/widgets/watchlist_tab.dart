import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error/error_view.dart';
import '../../../../shared/widgets/loading/skeleton_loader.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/presentation/widgets/login_guidance_sheet.dart';
import '../../application/watchlist_notifier.dart';
import '../../domain/entities/quote.dart';
import 'stock_row_tile.dart';

/// The "自选" (Watchlist) tab panel inside MarketHomeScreen.
///
/// Displays the user's saved stocks with real-time prices.
/// In guest mode: tapping a stock is allowed (navigates to detail),
/// but tapping the star/add button shows a login sheet.
///
/// Prototype: prototypes/03-market/hifi/index.html [PANEL: WATCHLIST]
class WatchlistTab extends ConsumerWidget {
  const WatchlistTab({
    super.key,
    required this.onStockTap,
    this.onEditTap,
  });

  final void Function(String symbol) onStockTap;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(authProvider).maybeWhen(
      guest: () => true,
      orElse: () => false,
    );
    final watchlistAsync = ref.watch(watchlistProvider);

    return watchlistAsync.when(
      loading: () => const _WatchlistSkeleton(),
      error: (e, _) => ErrorView(
        message: '加载自选股失败',
        onRetry: () => ref.invalidate(watchlistProvider),
      ),
      data: (quotes) {
        if (quotes.isEmpty) {
          return _WatchlistEmpty(isGuest: isGuest);
        }
        return _WatchlistList(
          quotes: quotes,
          isGuest: isGuest,
          onStockTap: onStockTap,
          onEditTap: onEditTap,
        );
      },
    );
  }
}

class _WatchlistList extends StatelessWidget {
  const _WatchlistList({
    required this.quotes,
    required this.isGuest,
    required this.onStockTap,
    this.onEditTap,
  });

  final List<Quote> quotes;
  final bool isGuest;
  final void Function(String symbol) onStockTap;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '自选股',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: onEditTap,
                child: Text(
                  '编辑',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        ...quotes.map((q) => Column(
          children: [
            StockRowTile(
              symbol: q.symbol,
              name: q.name,
              price: q.price,
              changePct: q.changePct,
              market: q.market,
              delayed: q.delayed,
              onTap: () => onStockTap(q.symbol),
            ),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ],
        )),
      ],
    );
  }
}

class _WatchlistEmpty extends StatelessWidget {
  const _WatchlistEmpty({required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '还没有自选股',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '搜索股票并添加，随时跟踪价格',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isGuest
                  ? () => showLoginGuidanceSheet(context, trigger: '添加自选股')
                  : null, // handled by parent via navigator
              child: const Text('去搜索添加'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistSkeleton extends StatelessWidget {
  const _WatchlistSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const SkeletonLoader(width: 44, height: 44, borderRadius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoader.text(width: 60),
                    SizedBox(height: 6),
                    SkeletonLoader.text(width: 120),
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
