import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/widgets/loading/skeleton_loader.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/presentation/widgets/login_guidance_sheet.dart';
import '../../application/index_quotes_notifier.dart';
import '../../application/movers_provider.dart';
import '../widgets/delayed_quote_banner.dart';
import '../widgets/movers_tab.dart';
import '../widgets/watchlist_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MarketHomeScreen (T01)
// ─────────────────────────────────────────────────────────────────────────────

/// The main market screen with 5 tabs + search bar + index banner.
///
/// Prototype: prototypes/03-market/hifi/index.html
///
/// Tabs: 自选 | 热门 | 涨幅榜 | 跌幅榜 | 港股
/// - 港股 shows a "coming soon" placeholder (Phase 1).
class MarketHomeScreen extends ConsumerStatefulWidget {
  const MarketHomeScreen({super.key});

  @override
  ConsumerState<MarketHomeScreen> createState() => _MarketHomeScreenState();
}

class _MarketHomeScreenState extends ConsumerState<MarketHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['自选', '热门', '涨幅榜', '跌幅榜', '港股'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onStockTap(String symbol) {
    context.push(
      RouteNames.stockDetail.replaceAll(':symbol', symbol),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(authProvider).maybeWhen(
      guest: () => true,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('行情'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: Column(
        children: [
          const DelayedQuoteBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: 自选
                _TabScrollView(
                  children: [
                    _IndexBanner(onStockTap: _onStockTap),
                    const SizedBox(height: 16),
                    WatchlistTab(
                      onStockTap: _onStockTap,
                      onEditTap: isGuest
                          ? () => showLoginGuidanceSheet(context, trigger: '编辑自选股')
                          : null,
                    ),
                  ],
                ),
                // Tab 1: 热门
                _TabScrollView(
                  children: [
                    MoversTab(
                      type: MoverType.mostActive,
                      onStockTap: _onStockTap,
                    ),
                  ],
                ),
                // Tab 2: 涨幅榜
                _TabScrollView(
                  children: [
                    MoversTab(
                      type: MoverType.gainers,
                      onStockTap: _onStockTap,
                    ),
                  ],
                ),
                // Tab 3: 跌幅榜
                _TabScrollView(
                  children: [
                    MoversTab(
                      type: MoverType.losers,
                      onStockTap: _onStockTap,
                    ),
                  ],
                ),
                // Tab 4: 港股 — Phase 1 coming soon
                const _HkComingSoon(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Index Banner — SPY / QQQ / DIA cards
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontally scrollable index ETF cards (SPY, QQQ, DIA).
///
/// Tapping a card navigates to the stock detail page.
class _IndexBanner extends ConsumerWidget {
  const _IndexBanner({required this.onStockTap});

  final void Function(String symbol) onStockTap;

  static const _indexes = [
    _IndexInfo('SPY', 'S&P 500'),
    _IndexInfo('QQQ', 'NASDAQ 100'),
    _IndexInfo('DIA', 'Dow Jones'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ETF 数据独立加载，不依赖 watchlist
    final indexQuotesAsync = ref.watch(indexQuotesProvider);

    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '大盘指数 (ETF 代理)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 85,
            child: indexQuotesAsync.when(
              data: (quoteMap) => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _indexes.length,
                separatorBuilder: (_, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final info = _indexes[i];
                  final quote = quoteMap[info.symbol];

                  return _IndexCard(
                    info: info,
                    price: quote?.price,
                    changePct: quote?.changePct,
                    onTap: () => onStockTap(info.symbol),
                  );
                },
              ),
              loading: () => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _indexes.length,
                separatorBuilder: (_, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) => Container(
                  width: 104,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _indexes[i].symbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SkeletonLoader(width: 70, height: 14, borderRadius: 3),
                      const SkeletonLoader(width: 48, height: 12, borderRadius: 3),
                    ],
                  ),
                ),
              ),
              error: (error, stack) => Center(
                child: Text(
                  '加载失败',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexInfo {
  const _IndexInfo(this.symbol, this.tracking);
  final String symbol;
  final String tracking;
}

class _IndexCard extends StatelessWidget {
  const _IndexCard({
    required this.info,
    required this.onTap,
    this.price,
    this.changePct,
  });

  final _IndexInfo info;
  final Decimal? price;
  final Decimal? changePct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = changePct;
    final isPos = pct != null && pct > Decimal.zero;
    final isNeg = pct != null && pct < Decimal.zero;
    final pctColor = isPos
        ? const Color(0xFF0DC582)
        : isNeg
            ? const Color(0xFFFF4747)
            : Colors.white70;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              info.symbol,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (price == null)
              const SkeletonLoader(width: 70, height: 14, borderRadius: 3)
            else
              Text(
                '\$${price!.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            if (pct == null)
              const SkeletonLoader(width: 48, height: 12, borderRadius: 3)
            else
              Text(
                '${isPos ? '+' : ''}${pct.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: pctColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HK coming soon placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _HkComingSoon extends StatelessWidget {
  const _HkComingSoon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🇭🇰', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              '港股交易即将开放',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '敬请期待，港股功能将在下一版本推出',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────

class _TabScrollView extends StatelessWidget {
  const _TabScrollView({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
