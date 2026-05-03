// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages user notification preferences (remote read/write).

@ProviderFor(NotificationPreferencesNotifier)
final notificationPreferencesProvider =
    NotificationPreferencesNotifierProvider._();

/// Manages user notification preferences (remote read/write).
final class NotificationPreferencesNotifierProvider
    extends
        $AsyncNotifierProvider<
          NotificationPreferencesNotifier,
          NotificationPreferences
        > {
  /// Manages user notification preferences (remote read/write).
  NotificationPreferencesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPreferencesNotifierHash();

  @$internal
  @override
  NotificationPreferencesNotifier create() => NotificationPreferencesNotifier();
}

String _$notificationPreferencesNotifierHash() =>
    r'98b3b4f83c1fb1017e59e6335d4b369f2a7f5111';

/// Manages user notification preferences (remote read/write).

abstract class _$NotificationPreferencesNotifier
    extends $AsyncNotifier<NotificationPreferences> {
  FutureOr<NotificationPreferences> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<NotificationPreferences>,
              NotificationPreferences
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<NotificationPreferences>,
                NotificationPreferences
              >,
              AsyncValue<NotificationPreferences>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
