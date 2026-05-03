// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_status_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches account compliance status from GET /v1/profile/account-status.

@ProviderFor(accountStatus)
final accountStatusProvider = AccountStatusProvider._();

/// Fetches account compliance status from GET /v1/profile/account-status.

final class AccountStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<AccountStatus>,
          AccountStatus,
          FutureOr<AccountStatus>
        >
    with $FutureModifier<AccountStatus>, $FutureProvider<AccountStatus> {
  /// Fetches account compliance status from GET /v1/profile/account-status.
  AccountStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountStatusHash();

  @$internal
  @override
  $FutureProviderElement<AccountStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AccountStatus> create(Ref ref) {
    return accountStatus(ref);
  }
}

String _$accountStatusHash() => r'3b87bdbc8dc1a9d1ad8556ed50b614d0f653d8df';
