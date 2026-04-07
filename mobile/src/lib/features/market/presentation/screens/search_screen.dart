import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../application/search_notifier.dart';
import '../../domain/entities/search_result.dart';
import '../widgets/stock_row_tile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SearchScreen (T06)
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen stock search (T06).
///
/// 3 states driven by [SearchState]:
///   - empty query → history list + hot stocks
///   - has query, loading → spinner row under search bar
///   - has query, results → result list
///   - has query, no results, not loading → "no results" empty state
///
/// Prototype: prototypes/03-market/hifi/search.html
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Restore query from notifier state (e.g. after hot-reload).
    final currentQuery = ref.read(searchProvider).query;
    if (currentQuery.isNotEmpty) {
      _controller.text = currentQuery;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    ref.read(searchProvider.notifier).updateQuery(value);
  }

  void _clearQuery() {
    _controller.clear();
    ref.read(searchProvider.notifier).updateQuery('');
    _focusNode.requestFocus();
  }

  void _onResultTap(String symbol) {
    ref.read(searchProvider.notifier).addToHistory(symbol);
    context.push(RouteNames.stockDetail.replaceAll(':symbol', symbol));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: _SearchBar(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onQueryChanged,
          onClear: _clearQuery,
          hasText: state.query.isNotEmpty,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SearchState state) {
    if (state.isEmptyQuery) {
      return _EmptyQueryView(
        history: state.history,
        hotStocks: state.hotStocks,
        onTap: _onResultTap,
        onRemoveHistory: (s) =>
            ref.read(searchProvider.notifier).removeFromHistory(s),
        onClearHistory: () =>
            ref.read(searchProvider.notifier).clearHistory(),
      );
    }

    if (state.isLoading) {
      return const _LoadingView();
    }

    if (state.error != null) {
      return _ErrorView(query: state.query);
    }

    if (state.isEmptyResult) {
      return _NoResultsView(query: state.query, isHkQuery: state.isHkQuery);
    }

    return _ResultsView(
      results: state.results,
      onTap: _onResultTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar widget
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.hasText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(
            Icons.search_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: '输入股票代码或名称…',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          if (hasText)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyQueryView extends StatelessWidget {
  const _EmptyQueryView({
    required this.history,
    required this.hotStocks,
    required this.onTap,
    required this.onRemoveHistory,
    required this.onClearHistory,
  });

  final List<String> history;
  final List<SearchResult> hotStocks;
  final void Function(String) onTap;
  final void Function(String) onRemoveHistory;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (history.isNotEmpty) ...[
            _SectionHeader(
              title: '历史搜索',
              trailing: TextButton(
                onPressed: onClearHistory,
                child: Text(
                  '清除',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            ...history.map((symbol) => _HistoryRow(
              symbol: symbol,
              onTap: () => onTap(symbol),
              onRemove: () => onRemoveHistory(symbol),
            )),
            const SizedBox(height: 8),
          ],
          if (hotStocks.isNotEmpty) ...[
            _SectionHeader(title: '热门搜索'),
            ...hotStocks.map((r) => Column(
              children: [
                StockRowTile(
                  symbol: r.symbol,
                  name: r.name,
                  price: r.price,
                  changePct: r.changePct,
                  market: r.market,
                  delayed: r.delayed,
                  onTap: () => onTap(r.symbol),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ],
            )),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.symbol,
    required this.onTap,
    required this.onRemove,
  });

  final String symbol;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                symbol,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.results, required this.onTap});

  final List<SearchResult> results;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: results.length,
      separatorBuilder: (_, i) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      itemBuilder: (context, i) {
        final r = results[i];
        return StockRowTile(
          symbol: r.symbol,
          name: r.name,
          price: r.price,
          changePct: r.changePct,
          market: r.market,
          delayed: r.delayed,
          onTap: () => onTap(r.symbol),
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 48),
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView({required this.query, this.isHkQuery = false});

  final String query;
  final bool isHkQuery;

  @override
  Widget build(BuildContext context) {
    final title = isHkQuery ? '港股行情即将开放' : '无搜索结果';
    final subtitle = isHkQuery
        ? '港股功能将在下一版本推出，您可先浏览美股行情'
        : '未找到与 "$query" 相关的股票';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHkQuery ? Icons.flag_outlined : Icons.search_off_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '搜索失败，请检查网络',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
