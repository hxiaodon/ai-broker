import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/funding_repository_impl.dart';
import '../domain/entities/account_balance.dart';

part 'account_balance_notifier.g.dart';

/// Fetches the user's account balance from the Fund Transfer service.
///
/// autoDispose: re-fetched each time FundingScreen becomes active.
/// Invalidated by DepositFormNotifier and WithdrawFormNotifier on success
/// so the balance card reflects the new state immediately.
@riverpod
Future<AccountBalance> accountBalance(Ref ref) =>
    ref.watch(fundingRepositoryProvider).getBalance();
