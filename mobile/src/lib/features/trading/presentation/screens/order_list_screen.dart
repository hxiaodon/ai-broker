import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/color_tokens.dart';
import '../../application/orders_notifier.dart';
import '../../application/recent_order_banner_provider.dart';
import '../../data/trading_repository_impl.dart';
import '../../domain/entities/order.dart';
import '../widgets/order_card_widget.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _colors = ColorTokens.greenUp;

  static const _tabs = [
    (label: '全部', status: null),
    (label: '待成交', status: OrderStatus.pending),
    (label: '已成交', status: OrderStatus.filled),
    (label: '已撤销', status: OrderStatus.cancelled),
  ];

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

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(recentOrderBannerProvider);
    return Scaffold(
      backgroundColor: _colors.background,
      appBar: AppBar(
        backgroundColor: _colors.surface,
        title: Text(
          '订单',
          style: TextStyle(
              color: _colors.onSurface, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _colors.primary,
          unselectedLabelColor: _colors.onSurfaceVariant,
          indicatorColor: _colors.primary,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: Column(
        children: [
          if (recent != null)
            _RecentOrderBanner(
              info: recent,
              colors: _colors,
              onDismiss: () =>
                  ref.read(recentOrderBannerProvider.notifier).clear(),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((t) => _OrderTab(
                        filterStatus: t.status,
                        colors: _colors,
                        highlightOrderId: recent?.orderId,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTab extends ConsumerWidget {
  const _OrderTab({
    required this.filterStatus,
    required this.colors,
    this.highlightOrderId,
  });

  final OrderStatus? filterStatus;
  final ColorTokens colors;
  final String? highlightOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync =
        ref.watch(ordersProvider(filterStatus: filterStatus));

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败',
                style: TextStyle(color: colors.onSurface, fontSize: 16)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(
                  ordersProvider(filterStatus: filterStatus)),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    color: colors.onSurfaceVariant, size: 48),
                const SizedBox(height: 12),
                Text('暂无订单',
                    style: TextStyle(
                        color: colors.onSurfaceVariant, fontSize: 15)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(
              ordersProvider(filterStatus: filterStatus)),
          child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final order = orders[i];
              return OrderCardWidget(
                order: order,
                colors: colors,
                isHighlighted:
                    highlightOrderId != null && order.orderId == highlightOrderId,
                onTap: () => _showOrderDetail(context, ref, order),
                onCancel: order.isCancellable
                    ? () => _confirmCancel(context, ref, order)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  void _confirmCancel(
      BuildContext context, WidgetRef ref, Order order) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('确认撤单',
            style: TextStyle(color: colors.onSurface)),
        content: Text(
          '撤销 ${order.side == OrderSide.buy ? "买入" : "卖出"} '
          '${order.symbol} × ${order.qty} 股的委托？\n'
          '已成交：${order.filledQty} 股，待撤：${order.remainingQty} 股',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: colors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(tradingRepositoryProvider)
                  .cancelOrder(order.orderId);
              ref.invalidate(
                  ordersProvider(filterStatus: filterStatus));
            },
            child: Text('确认撤单',
                style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }

  void _showOrderDetail(
      BuildContext context, WidgetRef ref, Order order) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _OrderDetailSheet(order: order, colors: colors),
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({required this.order, required this.colors});

  final Order order;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '订单详情',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _row('订单号', order.orderId),
          _row('股票代码', order.symbol),
          _row('方向', order.side == OrderSide.buy ? '买入' : '卖出'),
          _row('订单类型',
              order.orderType == OrderType.market ? '市价单' : '限价单'),
          if (order.limitPrice != null)
            _row('委托价格', '\$${order.limitPrice!.toStringAsFixed(4)}'),
          _row('委托数量', '${order.qty} 股'),
          _row('已成交', '${order.filledQty} 股'),
          if (order.avgFillPrice != null)
            _row('成交均价', '\$${order.avgFillPrice!.toStringAsFixed(4)}'),
          _row('有效期',
              order.validity == OrderValidity.day ? 'DAY' : 'GTC'),
          _row('委托时间', _formatDt(order.createdAt)),
          _row('更新时间', _formatDt(order.updatedAt)),
          Divider(color: colors.divider, height: 24),
          _row('佣金', '\$${order.fees.commission.toStringAsFixed(2)}'),
          _row('交易所费用', '\$${order.fees.exchangeFee.toStringAsFixed(2)}'),
          _row('SEC 费用', '\$${order.fees.secFee.toStringAsFixed(2)}'),
          _row('FINRA 费用', '\$${order.fees.finraFee.toStringAsFixed(2)}'),
          _row('费用合计', '\$${order.fees.total.toStringAsFixed(2)}',
              bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                    color: colors.onSurfaceVariant, fontSize: 14)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  String _formatDt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Recent Order Banner ─────────────────────────────────────────────────────

class _RecentOrderBanner extends StatelessWidget {
  const _RecentOrderBanner({
    required this.info,
    required this.colors,
    required this.onDismiss,
  });

  final RecentOrderInfo info;
  final ColorTokens colors;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isBuy = info.side == OrderSide.buy;
    final accent =
        isBuy ? const Color(0xFF0DC582) : const Color(0xFFFF4747);
    final typeLabel =
        info.orderType == OrderType.market ? '市价' : '限价';
    final sideLabel = isBuy ? '买入' : '卖出';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '委托已提交',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$typeLabel $sideLabel ${info.symbol} × ${info.qty}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '订单号：${info.orderId}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close,
                color: colors.onSurfaceVariant, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            visualDensity: VisualDensity.compact,
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }
}
