import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/funding/domain/entities/fund_transfer.dart';

FundTransfer _makeTransfer({
  TransferStatus status = TransferStatus.pending,
  TransferType type = TransferType.deposit,
}) =>
    FundTransfer(
      transferId: 'txn-001',
      accountId: 'acc-001',
      type: type,
      status: status,
      amount: Decimal.parse('1000.00'),
      currency: 'USD',
      channel: BankChannel.ach,
      bankAccountId: 'ba-001',
      requestId: 'idem-key-001',
      createdAt: DateTime.utc(2026, 4, 1, 9, 0),
      updatedAt: DateTime.utc(2026, 4, 1, 9, 1),
    );

void main() {
  group('TransferStatus.userFacingLabel', () {
    // "提交中" group
    final submittingStatuses = [
      TransferStatus.pending,
      TransferStatus.complianceCheck,
      TransferStatus.balanceCheck,
      TransferStatus.settlementCheck,
    ];
    for (final status in submittingStatuses) {
      test('$status → 提交中', () {
        expect(status.userFacingLabel, '提交中');
      });
    }

    test('approval → 审核中', () {
      expect(TransferStatus.approval.userFacingLabel, '审核中');
    });

    // "处理中" group
    final processingStatuses = [
      TransferStatus.bankProcessing,
      TransferStatus.confirmed,
      TransferStatus.ledgerUpdated,
    ];
    for (final status in processingStatuses) {
      test('$status → 处理中', () {
        expect(status.userFacingLabel, '处理中');
      });
    }

    test('completed → 已到账', () {
      expect(TransferStatus.completed.userFacingLabel, '已到账');
    });

    // "已拒绝" group
    final rejectedStatuses = [
      TransferStatus.failed,
      TransferStatus.rejected,
    ];
    for (final status in rejectedStatuses) {
      test('$status → 已拒绝', () {
        expect(status.userFacingLabel, '已拒绝');
      });
    }
  });

  group('TransferStatus.isTerminal', () {
    final terminal = [
      TransferStatus.completed,
      TransferStatus.failed,
      TransferStatus.rejected,
    ];
    final nonTerminal = [
      TransferStatus.pending,
      TransferStatus.complianceCheck,
      TransferStatus.balanceCheck,
      TransferStatus.settlementCheck,
      TransferStatus.approval,
      TransferStatus.bankProcessing,
      TransferStatus.confirmed,
      TransferStatus.ledgerUpdated,
    ];

    for (final status in terminal) {
      test('$status is terminal', () {
        expect(status.isTerminal, isTrue);
      });
    }

    for (final status in nonTerminal) {
      test('$status is NOT terminal', () {
        expect(status.isTerminal, isFalse);
      });
    }
  });

  group('TransferStatus enum coverage', () {
    test('has exactly 11 statuses', () {
      expect(TransferStatus.values, hasLength(11));
    });
  });

  group('BankChannel enum', () {
    test('has ach and wire', () {
      expect(BankChannel.values, containsAll([BankChannel.ach, BankChannel.wire]));
    });
  });

  group('TransferType enum', () {
    test('has deposit and withdrawal', () {
      expect(TransferType.values,
          containsAll([TransferType.deposit, TransferType.withdrawal]));
    });
  });

  group('FundTransfer fields', () {
    test('amount is Decimal, not double', () {
      final transfer = _makeTransfer();
      expect(transfer.amount, isA<Decimal>());
      expect(transfer.amount, Decimal.parse('1000.00'));
    });

    test('timestamps are UTC', () {
      final transfer = _makeTransfer();
      expect(transfer.createdAt.isUtc, isTrue);
      expect(transfer.updatedAt.isUtc, isTrue);
    });

    test('failureReason defaults to empty string', () {
      expect(_makeTransfer().failureReason, '');
    });

    test('completedAt is nullable', () {
      final transfer = _makeTransfer();
      expect(transfer.completedAt, isNull);
    });
  });
}
