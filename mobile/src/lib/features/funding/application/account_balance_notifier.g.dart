// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_balance_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches the user's account balance from the Fund Transfer service.
///
/// autoDispose: re-fetched each time FundingScreen becomes active.
/// Invalidated by DepositFormNotifier and WithdrawFormNotifier on success
/// so the balance card reflects the new state immediately.

@ProviderFor(accountBalance)
final accountBalanceProvider = AccountBalanceProvider._();

/// Fetches the user's account balance from the Fund Transfer service.
///
/// autoDispose: re-fetched each time FundingScreen becomes active.
/// Invalidated by DepositFormNotifier and WithdrawFormNotifier on success
/// so the balance card reflects the new state immediately.

final class AccountBalanceProvider
    extends
        $FunctionalProvider<
          AsyncValue<AccountBalance>,
          AccountBalance,
          FutureOr<AccountBalance>
        >
    with $FutureModifier<AccountBalance>, $FutureProvider<AccountBalance> {
  /// Fetches the user's account balance from the Fund Transfer service.
  ///
  /// autoDispose: re-fetched each time FundingScreen becomes active.
  /// Invalidated by DepositFormNotifier and WithdrawFormNotifier on success
  /// so the balance card reflects the new state immediately.
  AccountBalanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountBalanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountBalanceHash();

  @$internal
  @override
  $FutureProviderElement<AccountBalance> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AccountBalance> create(Ref ref) {
    return accountBalance(ref);
  }
}

String _$accountBalanceHash() => r'950a422e55c112df84ec0beaaba4d27afd411fbc';
