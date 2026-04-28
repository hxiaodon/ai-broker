// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_accounts_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the list of the user's linked bank accounts.
///
/// Supports:
/// - build(): fetch list from server on init
/// - addBankAccount(): optimistic local insert after server confirms
/// - removeBankAccount(): optimistic local remove, rollback on error
/// - verifyMicroDeposit(): update matching account with server-returned state

@ProviderFor(BankAccountsNotifier)
final bankAccountsProvider = BankAccountsNotifierProvider._();

/// Manages the list of the user's linked bank accounts.
///
/// Supports:
/// - build(): fetch list from server on init
/// - addBankAccount(): optimistic local insert after server confirms
/// - removeBankAccount(): optimistic local remove, rollback on error
/// - verifyMicroDeposit(): update matching account with server-returned state
final class BankAccountsNotifierProvider
    extends $AsyncNotifierProvider<BankAccountsNotifier, List<BankAccount>> {
  /// Manages the list of the user's linked bank accounts.
  ///
  /// Supports:
  /// - build(): fetch list from server on init
  /// - addBankAccount(): optimistic local insert after server confirms
  /// - removeBankAccount(): optimistic local remove, rollback on error
  /// - verifyMicroDeposit(): update matching account with server-returned state
  BankAccountsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bankAccountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bankAccountsNotifierHash();

  @$internal
  @override
  BankAccountsNotifier create() => BankAccountsNotifier();
}

String _$bankAccountsNotifierHash() =>
    r'591cff084ce63e02f1c17fa7d66ecd38bfb748ea';

/// Manages the list of the user's linked bank accounts.
///
/// Supports:
/// - build(): fetch list from server on init
/// - addBankAccount(): optimistic local insert after server confirms
/// - removeBankAccount(): optimistic local remove, rollback on error
/// - verifyMicroDeposit(): update matching account with server-returned state

abstract class _$BankAccountsNotifier
    extends $AsyncNotifier<List<BankAccount>> {
  FutureOr<List<BankAccount>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<BankAccount>>, List<BankAccount>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BankAccount>>, List<BankAccount>>,
              AsyncValue<List<BankAccount>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
