import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/funding_repository_impl.dart';
import '../domain/entities/fund_transfer.dart';

part 'fund_transfer_history_notifier.g.dart';

/// Recent 10 transfers — shown on the FundingScreen main page.
@riverpod
Future<List<FundTransfer>> fundTransferHistory(Ref ref) =>
    ref.watch(fundingRepositoryProvider).getTransferHistory(pageSize: 10);

/// Paginated transfers — used in the full history page.
@riverpod
Future<List<FundTransfer>> fundTransferHistoryPage(Ref ref, int page) =>
    ref.watch(fundingRepositoryProvider).getTransferHistory(page: page);
