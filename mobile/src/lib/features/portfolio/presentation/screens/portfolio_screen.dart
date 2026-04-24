import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/extensions/decimal_extensions.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../trading/application/portfolio_summary_provider.dart';
import '../../../trading/application/positions_provider.dart';
import '../../../trading/domain/entities/order.dart';
import '../../../trading/domain/entities/position.dart';
import '../../presentation/widgets/asset_summary_card.dart';
import '../../presentation/widgets/empty_portfolio_widget.dart';
import '../../presentation/widgets/position_list_card.dart';
import 'portfolio_analysis_screen.dart';

enum _SortMode { marketValue, pnlAbs, todayChange, addedTime }

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _SortMode _sortMode = _SortMode.marketValue;

  static const _colors = ColorTokens.greenUp;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colors.background,
      appBar: AppBar(
        backgroundColor: _colors.surface,
        title: Text(
          '持仓',
          style: TextStyle(
            color: _colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _colors.primary,
          unselectedLabelColor: _colors.onSurfaceVariant,
          indicatorColor: _colors.primary,
          tabs: const [Tab(text: '持仓'), Tab(text: '分析')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PositionsTab(colors: _colors, sortMode: _sortMode,
              onSortChanged: (mode) => setState(() => _sortMode = mode)),
          const PortfolioAnalysisScreen(colors: _colors),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Positions Tab
// ---------------------------------------------------------------------------

class _PositionsTab extends ConsumerWidget {
  const _PositionsTab({
    required this.colors,
    required this.sortMode,
    required this.onSortChanged,
  });

  final ColorTokens colors;
  final _SortMode sortMode;
  final ValueChanged<_SortMode> onSortChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(portfolioSummaryProvider);
    final positionsAsync = ref.watch(positionsProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(error: e, colors: colors),
      data: (summary) => positionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(error: e, colors: colors),
        data: (positions) {
          // Empty states
          if (positions.isEmpty && summary.cashBalance == Decimal.zero) {
            return EmptyPortfolioWidget(
              colors: colors,
              onDeposit: () => context.go('/funding/deposit'),
              onBrowseMarket: () => context.go(RouteNames.market),
            );
          }
          if (positions.isEmpty) {
            return CashOnlyPortfolioWidget(
              cashBalance: summary.cashBalance.toAmount(),
              colors: colors,
              onBrowseMarket: () => context.go(RouteNames.market),
            );
          }

          final totalMv = positions.fold<Decimal>(
            Decimal.zero,
            (Decimal acc, p) => acc + p.marketValue,
          );
          final sorted = _sorted(positions, sortMode);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: AssetSummaryCard(
                    totalEquity: summary.totalEquity,
                    dayPnl: summary.dayPnl,
                    dayPnlPct: summary.dayPnlPct,
                    totalPnl: summary.totalPnl,
                    totalPnlPct: summary.totalPnlPct,
                    cashBalance: summary.cashBalance,
                    unsettledCash: summary.unsettledCash,
                    colors: colors,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '持仓（${positions.length}）',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      _SortButton(
                        current: sortMode,
                        colors: colors,
                        onChanged: onSortChanged,
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final pos = sorted[i];
                      final weight = totalMv > Decimal.zero
                          ? Decimal.parse((pos.marketValue / totalMv).toDecimal(scaleOnInfinitePrecision: 6).toString())
                          : Decimal.zero;
                      return PositionListCard(
                        position: pos,
                        portfolioWeight: weight,
                        colors: colors,
                        onTap: () => ctx.push(
                          RouteNames.positionDetail.replaceFirst(
                              ':symbol', pos.symbol),
                        ),
                        onBuy: () => ctx.push(
                          RouteNames.orderEntry,
                          extra: {
                            'symbol': pos.symbol,
                            'market': pos.market,
                            'side': OrderSide.buy,
                          },
                        ),
                        onSell: () => ctx.push(
                          RouteNames.orderEntry,
                          extra: {
                            'symbol': pos.symbol,
                            'market': pos.market,
                            'side': OrderSide.sell,
                            'prefillQty': pos.availableQty,
                          },
                        ),
                      );
                    },
                    childCount: sorted.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Position> _sorted(List<Position> positions, _SortMode mode) {
    final list = [...positions];
    switch (mode) {
      case _SortMode.marketValue:
        list.sort((a, b) => b.marketValue.compareTo(a.marketValue));
      case _SortMode.pnlAbs:
        list.sort((a, b) =>
            b.unrealizedPnl.abs().compareTo(a.unrealizedPnl.abs()));
      case _SortMode.todayChange:
        list.sort((a, b) => b.todayPnlPct.compareTo(a.todayPnlPct));
      case _SortMode.addedTime:
        break; // server order preserved
    }
    return list;
  }
}

// ---------------------------------------------------------------------------
// Sort button
// ---------------------------------------------------------------------------

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.current,
    required this.colors,
    required this.onChanged,
  });

  final _SortMode current;
  final ColorTokens colors;
  final ValueChanged<_SortMode> onChanged;

  static const _labels = {
    _SortMode.marketValue: '市值',
    _SortMode.pnlAbs: '浮盈亏',
    _SortMode.todayChange: '今日涨跌',
    _SortMode.addedTime: '加入时间',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<_SortMode>(
          context: context,
          builder: (_) => _SortSheet(
            current: current,
            colors: colors,
            labels: _labels,
          ),
        );
        if (result != null) onChanged(result);
      },
      child: Row(
        children: [
          Text(
            _labels[current]!,
            style: TextStyle(color: colors.primary, fontSize: 13),
          ),
          const SizedBox(width: 4),
          Icon(Icons.unfold_more, size: 16, color: colors.primary),
        ],
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({
    required this.current,
    required this.colors,
    required this.labels,
  });

  final _SortMode current;
  final ColorTokens colors;
  final Map<_SortMode, String> labels;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(
            '排序方式',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          ...labels.entries.map(
            (e) => ListTile(
              title: Text(e.value,
                  style: TextStyle(color: colors.onSurface, fontSize: 14)),
              trailing: current == e.key
                  ? Icon(Icons.check, color: colors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(e.key),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.colors});

  final Object error;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 12),
            Text(
              '加载失败，请重试',
              style: TextStyle(color: colors.onSurface, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
