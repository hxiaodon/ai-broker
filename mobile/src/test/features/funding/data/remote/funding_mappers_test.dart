import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/funding/data/remote/funding_mappers.dart';
import 'package:trading_app/features/funding/data/remote/models/account_balance_model.dart';
import 'package:trading_app/features/funding/data/remote/models/bank_account_model.dart';
import 'package:trading_app/features/funding/data/remote/models/fund_transfer_model.dart';
import 'package:trading_app/features/funding/domain/entities/bank_account.dart';
import 'package:trading_app/features/funding/domain/entities/fund_transfer.dart';

// ─── AccountBalanceModel helpers ─────────────────────────────────────────────

const AccountBalanceModel _balanceModel = AccountBalanceModel(
  accountId: 'acc-001',
  currency: 'USD',
  totalBalance: '12450.00',
  availableBalance: '12450.00',
  unsettledAmount: '0.00',
  withdrawableBalance: '11450.00',
  updatedAt: '2026-04-27T10:00:00.000Z',
);

// ─── BankAccountModel helpers ─────────────────────────────────────────────────

BankAccountModel _bankModel({
  bool isVerified = true,
  String? cooldownEndsAt,
  String microDepositStatus = 'verified',
  int remainingVerifyAttempts = 5,
}) =>
    BankAccountModel(
      id: 'ba-001',
      accountName: 'John Smith',
      accountNumberMasked: '****1234',
      routingNumber: '021000021',
      bankName: 'Chase Bank',
      currency: 'USD',
      isVerified: isVerified,
      cooldownEndsAt: cooldownEndsAt,
      microDepositStatus: microDepositStatus,
      remainingVerifyAttempts: remainingVerifyAttempts,
      createdAt: '2026-04-01T00:00:00.000Z',
    );

// ─── FundTransferModel helpers ────────────────────────────────────────────────

FundTransferModel _transferModel({
  String type = 'DEPOSIT',
  String status = 'PENDING',
  String channel = 'ACH',
  String? completedAt,
}) =>
    FundTransferModel(
      transferId: 'txn-001',
      accountId: 'acc-001',
      type: type,
      status: status,
      amount: '1000.00',
      currency: 'USD',
      channel: channel,
      bankAccountId: 'ba-001',
      requestId: 'idem-001',
      failureReason: '',
      createdAt: '2026-04-27T09:00:00.000Z',
      updatedAt: '2026-04-27T09:01:00.000Z',
      completedAt: completedAt,
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── AccountBalanceModel → AccountBalance ─────────────────────────────────

  group('AccountBalanceModelMapper.toDomain', () {
    test('maps all scalar fields', () {
      final balance = _balanceModel.toDomain();
      expect(balance.accountId, 'acc-001');
      expect(balance.currency, 'USD');
    });

    test('parses all amount strings to Decimal', () {
      final balance = _balanceModel.toDomain();
      expect(balance.totalBalance, Decimal.parse('12450.00'));
      expect(balance.availableBalance, Decimal.parse('12450.00'));
      expect(balance.unsettledAmount, Decimal.zero);
      expect(balance.withdrawableBalance, Decimal.parse('11450.00'));
    });

    test('updatedAt is UTC', () {
      final balance = _balanceModel.toDomain();
      expect(balance.updatedAt.isUtc, isTrue);
      expect(balance.updatedAt, DateTime.utc(2026, 4, 27, 10));
    });

    test('throws on invalid decimal', () {
      const bad = AccountBalanceModel(
        accountId: 'acc-001',
        totalBalance: 'not-a-number',
        availableBalance: '0',
        withdrawableBalance: '0',
        updatedAt: '2026-04-27T10:00:00.000Z',
      );
      expect(() => bad.toDomain(), throwsA(isA<FormatException>()));
    });
  });

  // ── BankAccountModel → BankAccount ────────────────────────────────────────

  group('BankAccountModelMapper.toDomain', () {
    test('maps all scalar fields', () {
      final account = _bankModel().toDomain();
      expect(account.id, 'ba-001');
      expect(account.accountName, 'John Smith');
      expect(account.accountNumberMasked, '****1234');
      expect(account.routingNumber, '021000021');
      expect(account.bankName, 'Chase Bank');
    });

    test('createdAt is UTC', () {
      final account = _bankModel().toDomain();
      expect(account.createdAt.isUtc, isTrue);
      expect(account.createdAt, DateTime.utc(2026, 4, 1));
    });

    test('cooldownEndsAt is null when server returns null', () {
      expect(_bankModel(cooldownEndsAt: null).toDomain().cooldownEndsAt, isNull);
    });

    test('cooldownEndsAt is UTC when present', () {
      final account = _bankModel(
        cooldownEndsAt: '2026-04-30T10:00:00.000Z',
      ).toDomain();
      expect(account.cooldownEndsAt, isNotNull);
      expect(account.cooldownEndsAt!.isUtc, isTrue);
    });

    // MicroDepositStatus mapping
    final microDepositCases = {
      'verified': MicroDepositStatus.verified,
      'verifying': MicroDepositStatus.verifying,
      'failed': MicroDepositStatus.failed,
      'pending': MicroDepositStatus.pending,
      'UNKNOWN': MicroDepositStatus.pending, // unknown → pending
    };
    for (final entry in microDepositCases.entries) {
      test('micro_deposit_status "${entry.key}" → ${entry.value}', () {
        expect(
          _bankModel(microDepositStatus: entry.key).toDomain().microDepositStatus,
          entry.value,
        );
      });
    }
  });

  // ── FundTransferModel → FundTransfer ─────────────────────────────────────

  group('FundTransferModelMapper.toDomain - TransferType', () {
    test('DEPOSIT → TransferType.deposit', () {
      expect(_transferModel(type: 'DEPOSIT').toDomain().type, TransferType.deposit);
    });

    test('WITHDRAWAL → TransferType.withdrawal', () {
      expect(
        _transferModel(type: 'WITHDRAWAL').toDomain().type,
        TransferType.withdrawal,
      );
    });
  });

  group('FundTransferModelMapper.toDomain - BankChannel', () {
    test('ACH → BankChannel.ach', () {
      expect(_transferModel(channel: 'ACH').toDomain().channel, BankChannel.ach);
    });

    test('WIRE → BankChannel.wire', () {
      expect(_transferModel(channel: 'WIRE').toDomain().channel, BankChannel.wire);
    });

    test('unknown channel defaults to ach', () {
      expect(
        _transferModel(channel: 'UNKNOWN').toDomain().channel,
        BankChannel.ach,
      );
    });
  });

  group('FundTransferModelMapper.toDomain - TransferStatus (all 11)', () {
    // Both prefixed and short forms should map
    final statusCases = {
      'PENDING': TransferStatus.pending,
      'TRANSFER_STATUS_PENDING': TransferStatus.pending,
      'COMPLIANCE_CHECK': TransferStatus.complianceCheck,
      'TRANSFER_STATUS_COMPLIANCE_CHECK': TransferStatus.complianceCheck,
      'BALANCE_CHECK': TransferStatus.balanceCheck,
      'TRANSFER_STATUS_BALANCE_CHECK': TransferStatus.balanceCheck,
      'SETTLEMENT_CHECK': TransferStatus.settlementCheck,
      'TRANSFER_STATUS_SETTLEMENT_CHECK': TransferStatus.settlementCheck,
      'APPROVAL': TransferStatus.approval,
      'TRANSFER_STATUS_APPROVAL': TransferStatus.approval,
      'BANK_PROCESSING': TransferStatus.bankProcessing,
      'TRANSFER_STATUS_BANK_PROCESSING': TransferStatus.bankProcessing,
      'CONFIRMED': TransferStatus.confirmed,
      'TRANSFER_STATUS_CONFIRMED': TransferStatus.confirmed,
      'LEDGER_UPDATED': TransferStatus.ledgerUpdated,
      'TRANSFER_STATUS_LEDGER_UPDATED': TransferStatus.ledgerUpdated,
      'COMPLETED': TransferStatus.completed,
      'TRANSFER_STATUS_COMPLETED': TransferStatus.completed,
      'FAILED': TransferStatus.failed,
      'TRANSFER_STATUS_FAILED': TransferStatus.failed,
      'REJECTED': TransferStatus.rejected,
      'TRANSFER_STATUS_REJECTED': TransferStatus.rejected,
    };

    for (final entry in statusCases.entries) {
      test('"${entry.key}" → ${entry.value}', () {
        expect(
          _transferModel(status: entry.key).toDomain().status,
          entry.value,
        );
      });
    }

    test('unknown status defaults to pending', () {
      expect(
        _transferModel(status: 'BOGUS_STATUS').toDomain().status,
        TransferStatus.pending,
      );
    });
  });

  group('FundTransferModelMapper.toDomain - amounts and timestamps', () {
    test('amount is Decimal', () {
      expect(
        _transferModel().toDomain().amount,
        Decimal.parse('1000.00'),
      );
    });

    test('createdAt and updatedAt are UTC', () {
      final transfer = _transferModel().toDomain();
      expect(transfer.createdAt.isUtc, isTrue);
      expect(transfer.updatedAt.isUtc, isTrue);
      expect(transfer.createdAt, DateTime.utc(2026, 4, 27, 9, 0));
    });

    test('completedAt is null when server returns null', () {
      expect(_transferModel(completedAt: null).toDomain().completedAt, isNull);
    });

    test('completedAt is UTC when present', () {
      final transfer = _transferModel(
        completedAt: '2026-04-27T10:00:00.000Z',
      ).toDomain();
      expect(transfer.completedAt, isNotNull);
      expect(transfer.completedAt!.isUtc, isTrue);
    });

    test('throws on invalid amount string', () {
      final bad = FundTransferModel(
        transferId: 'txn-bad',
        accountId: 'acc-001',
        type: 'DEPOSIT',
        status: 'PENDING',
        amount: 'not-decimal',
        channel: 'ACH',
        bankAccountId: 'ba-001',
        requestId: 'req-001',
        createdAt: '2026-04-27T09:00:00.000Z',
        updatedAt: '2026-04-27T09:00:00.000Z',
      );
      expect(() => bad.toDomain(), throwsA(isA<FormatException>()));
    });
  });
}
