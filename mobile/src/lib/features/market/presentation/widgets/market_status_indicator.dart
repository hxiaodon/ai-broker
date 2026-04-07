import 'package:flutter/material.dart';

import '../../domain/entities/market_status.dart';

/// Compact chip showing the current market session state.
///
/// | Status       | Label (ZH) | Colour          |
/// |--------------|------------|-----------------|
/// | regular      | 盘中        | green           |
/// | preMarket    | 盘前        | amber           |
/// | afterHours   | 盘后        | amber           |
/// | closed       | 休市        | grey            |
/// | halted       | 暂停交易     | red             |
///
/// Prototype: prototypes/03-market/hifi/stock-detail.html — market status pill
class MarketStatusIndicator extends StatelessWidget {
  const MarketStatusIndicator({
    super.key,
    required this.status,
  });

  final MarketStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MarketStatus.regular => ('盘中', const Color(0xFF0DC582)),
      MarketStatus.preMarket => ('盘前', const Color(0xFFFFC107)),
      MarketStatus.afterHours => ('盘后', const Color(0xFFFFC107)),
      MarketStatus.closed => ('休市', const Color(0xFF8A8D9F)),
      MarketStatus.halted => ('暂停交易', const Color(0xFFFF4747)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
