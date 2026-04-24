import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../shared/extensions/decimal_extensions.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../domain/entities/sector_allocation.dart';

class SectorAllocationBar extends StatelessWidget {
  const SectorAllocationBar({
    super.key,
    required this.allocation,
    required this.colors,
  });

  final SectorAllocation allocation;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    final pct =
        (allocation.weight * Decimal.fromInt(100)).toFormatted(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  allocation.sector,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                allocation.marketValue.toAmount(),
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: allocation.weight.toDouble(),
              minHeight: 6,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
