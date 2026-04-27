import 'package:flutter/material.dart';

import '../../../../shared/extensions/decimal_extensions.dart';
import '../../domain/entities/fund_transfer.dart';

/// Single row in the transfer history list.
class TransferHistoryTile extends StatelessWidget {
  const TransferHistoryTile({super.key, required this.transfer});

  final FundTransfer transfer;

  @override
  Widget build(BuildContext context) {
    final isDeposit = transfer.type == TransferType.deposit;
    final amountColor =
        isDeposit ? const Color(0xFF0DC582) : const Color(0xFFFF4747);
    final amountPrefix = isDeposit ? '+' : '-';
    final icon = isDeposit ? Icons.arrow_downward : Icons.arrow_upward;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: amountColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: amountColor, size: 18),
      ),
      title: Row(
        children: [
          Text(
            isDeposit ? '入金' : '出金',
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          _StatusChip(status: transfer.status),
        ],
      ),
      subtitle: Text(
        _formatDateTime(transfer.createdAt),
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      ),
      trailing: Text(
        '$amountPrefix${transfer.amount.toAmount()}',
        style: TextStyle(
          color: amountColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_pad(local.month)}-${_pad(local.day)} '
        '${_pad(local.hour)}:${_pad(local.minute)}';
  }

  String _pad(int v) => v.toString().padLeft(2, '0');
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final TransferStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  (String, Color) _resolve(TransferStatus s) => switch (s) {
        TransferStatus.completed => ('已到账', const Color(0xFF0DC582)),
        TransferStatus.failed || TransferStatus.rejected => ('已拒绝', const Color(0xFFFF4747)),
        TransferStatus.approval => ('审核中', const Color(0xFFFFA940)),
        TransferStatus.bankProcessing ||
        TransferStatus.confirmed ||
        TransferStatus.ledgerUpdated =>
          ('处理中', const Color(0xFF1A73E8)),
        _ => ('提交中', Colors.white38),
      };
}
