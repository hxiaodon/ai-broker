import 'package:flutter/material.dart';

/// Yellow warning banner shown when a quote becomes stale.
///
/// Visible when `StockDetail.isStale == true` AND `staleSinceMs >= 5000`.
/// Warns the user that market data may be delayed and they should trade carefully.
///
/// Prototype: prototypes/03-market/hifi/stock-detail.html [STATE: stale]
class StaleQuoteWarningBanner extends StatelessWidget {
  const StaleQuoteWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF332B00),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFFFC107)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '行情数据可能存在延迟，请谨慎交易',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFFFC107),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
