// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches and caches the user's profile from GET /v1/profile.
///
/// autoDispose: profile is refetched when user navigates back to the screen.

@ProviderFor(userProfile)
final userProfileProvider = UserProfileProvider._();

/// Fetches and caches the user's profile from GET /v1/profile.
///
/// autoDispose: profile is refetched when user navigates back to the screen.

final class UserProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile>,
          UserProfile,
          FutureOr<UserProfile>
        >
    with $FutureModifier<UserProfile>, $FutureProvider<UserProfile> {
  /// Fetches and caches the user's profile from GET /v1/profile.
  ///
  /// autoDispose: profile is refetched when user navigates back to the screen.
  UserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @$internal
  @override
  $FutureProviderElement<UserProfile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserProfile> create(Ref ref) {
    return userProfile(ref);
  }
}

String _$userProfileHash() => r'802fe845fc9d261861a516eab60080607acdb630';
