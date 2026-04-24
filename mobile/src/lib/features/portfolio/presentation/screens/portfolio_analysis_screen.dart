import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../application/pnl_ranking_provider.dart';
import '../../application/sector_allocation_provider.dart';
import '../widgets/pnl_ranking_item.dart';
import '../widgets/sector_allocation_bar.dart';

class PortfolioAnalysisScreen extends ConsumerWidget {
  const PortfolioAnalysisScreen({super.key, required this.colors});

  final ColorTokens colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectorAsync = ref.watch(sectorAllocationProvider);
    final pnlAsync = ref.watch(pnlRankingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sector distribution ─────────────────────────────────────────
          Text(
            '板块分布',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          sectorAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              '板块数据加载失败',
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
            data: (allocations) {
              if (allocations.isEmpty) {
                return Text(
                  '暂无持仓数据',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                );
              }
              return Column(
                children: allocations
                    .map((a) => SectorAllocationBar(
                          allocation: a,
                          colors: colors,
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── P&L ranking ──────────────────────────────────────────────────
          Text(
            '盈亏排行',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          pnlAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              '盈亏数据加载失败',
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
            data: (positions) {
              if (positions.isEmpty) {
                return Text(
                  '暂无持仓数据',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                );
              }
              return Column(
                children: positions
                    .asMap()
                    .entries
                    .map((entry) => PnlRankingItem(
                          rank: entry.key + 1,
                          position: entry.value,
                          colors: colors,
                          onTap: () => context.push(
                            RouteNames.positionDetail.replaceFirst(
                                ':symbol', entry.value.symbol),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
