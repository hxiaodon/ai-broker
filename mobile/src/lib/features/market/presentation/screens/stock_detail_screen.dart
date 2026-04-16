import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/widgets/error/error_view.dart';
import '../../../../shared/widgets/loading/skeleton_loader.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/presentation/widgets/login_guidance_sheet.dart';
import '../../application/stock_detail_notifier.dart';
import '../../application/watchlist_notifier.dart';
import '../../domain/entities/quote.dart';
import '../../domain/entities/stock_detail.dart';
import '../widgets/kline_chart_widget.dart';
import '../widgets/market_status_indicator.dart';
import '../widgets/stale_quote_warning_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StockDetailScreen (T04)
// ─────────────────────────────────────────────────────────────────────────────

/// Stock detail page — price hero + K-line chart + fundamental grid.
///
/// Prototype: prototypes/03-market/hifi/stock-detail.html
class StockDetailScreen extends ConsumerWidget {
  const StockDetailScreen({super.key, required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stockDetailProvider(symbol));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(symbol),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        actions: [
          _WatchlistToggleButton(symbol: symbol),
          const SizedBox(width: 8),
        ],
      ),
      body: detailAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => ErrorView(
          message: '加载失败，请重试',
          onRetry: () => ref.invalidate(stockDetailProvider(symbol)),
        ),
        data: (detail) => _DetailBody(detail: detail),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Watchlist star button
// ─────────────────────────────────────────────────────────────────────────────

class _WatchlistToggleButton extends ConsumerWidget {
  const _WatchlistToggleButton({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(authProvider).maybeWhen(
      guest: () => true,
      orElse: () => false,
    );
    final watchlistAsync = ref.watch(watchlistProvider);
    final inWatchlist = watchlistAsync.asData?.value
            .any((Quote q) => q.symbol == symbol) ??
        false;

    return IconButton(
      icon: Icon(
        inWatchlist ? Icons.star_rounded : Icons.star_border_rounded,
        color: inWatchlist
            ? const Color(0xFFFFC107)
            : Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () async {
        if (isGuest) {
          await showLoginGuidanceSheet(context, trigger: '添加自选');
          return;
        }
        final notifier = ref.read(watchlistProvider.notifier);
        if (inWatchlist) {
          await notifier.remove(symbol);
        } else {
          await notifier.add(symbol: symbol, market: 'US');
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final StockDetail detail;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.showStaleWarning) const StaleQuoteWarningBanner(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PriceHero(detail: detail),
                const SizedBox(height: 16),
                KLineChartWidget(symbol: detail.symbol),
                const SizedBox(height: 16),
                _ActionButtons(detail: detail),
                const SizedBox(height: 16),
                _QuoteGrid(detail: detail),
                const SizedBox(height: 16),
                _FundamentalGrid(detail: detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Price Hero
// ─────────────────────────────────────────────────────────────────────────────

class _PriceHero extends StatelessWidget {
  const _PriceHero({required this.detail});

  final StockDetail detail;

  @override
  Widget build(BuildContext context) {
    final isPos = detail.changePct >= Decimal.zero;
    final changeColor = isPos
        ? const Color(0xFF0DC582)
        : const Color(0xFFFF4747);

    final nameDisplay = detail.exchange.isNotEmpty
        ? '${detail.name} · ${detail.exchange}'
        : detail.name;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.symbol,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  nameDisplay,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              MarketStatusIndicator(status: detail.marketStatus),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${detail.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'USD · ${detail.session}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPos ? '+' : ''}${detail.changePct.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isPos ? '+' : ''}${detail.change.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 14,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.detail});

  final StockDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(authProvider).maybeWhen(
      guest: () => true,
      orElse: () => false,
    );
    final isHalted = detail.marketStatus.name == 'halted';

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: isHalted
                ? null
                : isGuest
                    ? () => showLoginGuidanceSheet(context, trigger: '买入')
                    : () => context.push(
                          '${RouteNames.orderEntry}?symbol=${detail.symbol}&side=BUY',
                        ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0DC582),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '买入',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: isHalted
                ? null
                : isGuest
                    ? () => showLoginGuidanceSheet(context, trigger: '卖出')
                    : () => context.push(
                          '${RouteNames.orderEntry}?symbol=${detail.symbol}&side=SELL',
                        ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF4747),
              side: const BorderSide(color: Color(0xFFFF4747)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '卖出',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quote data grid (today's figures)
// ─────────────────────────────────────────────────────────────────────────────

class _QuoteGrid extends StatelessWidget {
  const _QuoteGrid({required this.detail});

  final StockDetail detail;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _GridRow('今开', '\$${detail.open.toStringAsFixed(2)}'),
      _GridRow('昨收', '\$${detail.prevClose.toStringAsFixed(2)}'),
      _GridRow('最高', '\$${detail.high.toStringAsFixed(2)}'),
      _GridRow('最低', '\$${detail.low.toStringAsFixed(2)}'),
      _GridRow('成交量', _formatVolume(detail.volume)),
      _GridRow('成交额', detail.turnover),
      if (detail.bid != null)
        _GridRow('买一价', '\$${detail.bid!.toStringAsFixed(2)}'),
      if (detail.ask != null)
        _GridRow('卖一价', '\$${detail.ask!.toStringAsFixed(2)}'),
    ];

    return _DataCard(
      title: '今日行情',
      rows: rows,
    );
  }

  static String _formatVolume(int vol) {
    if (vol >= 1000000000) return '${(vol / 1000000000).toStringAsFixed(2)}B';
    if (vol >= 1000000) return '${(vol / 1000000).toStringAsFixed(2)}M';
    if (vol >= 1000) return '${(vol / 1000).toStringAsFixed(1)}K';
    return vol.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fundamental data grid
// ─────────────────────────────────────────────────────────────────────────────

class _FundamentalGrid extends StatelessWidget {
  const _FundamentalGrid({required this.detail});

  final StockDetail detail;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _GridRow('市值', detail.marketCap),
      _GridRow('市盈率 (TTM)', detail.peRatio),
      _GridRow('市净率', detail.pbRatio),
      _GridRow('股息率', '${detail.dividendYield}%'),
      _GridRow('52周最高', '\$${detail.week52High.toStringAsFixed(2)}'),
      _GridRow('52周最低', '\$${detail.week52Low.toStringAsFixed(2)}'),
      _GridRow('换手率', '${detail.turnoverRate.toStringAsFixed(2)}%'),
      _GridRow('所属板块', detail.sector),
    ];

    return _DataCard(
      title: '基本面',
      rows: rows,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card + row widgets
// ─────────────────────────────────────────────────────────────────────────────

class _GridRow {
  const _GridRow(this.label, this.value);
  final String label;
  final String value;
}

class _DataCard extends StatelessWidget {
  const _DataCard({required this.title, required this.rows});

  final String title;
  final List<_GridRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...rows.map(
            (row) => Column(
              children: [
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        row.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        row.value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonLoader(width: double.infinity, height: 140, borderRadius: 12),
          SizedBox(height: 16),
          SkeletonLoader(width: double.infinity, height: 220, borderRadius: 12),
          SizedBox(height: 16),
          SkeletonLoader(width: double.infinity, height: 56, borderRadius: 8),
          SizedBox(height: 16),
          SkeletonLoader(width: double.infinity, height: 200, borderRadius: 12),
        ],
      ),
    );
  }
}
