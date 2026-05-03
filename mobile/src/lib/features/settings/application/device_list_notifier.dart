import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../data/settings_repository_impl.dart';
import '../domain/entities/device_info.dart';

part 'device_list_notifier.g.dart';

/// Manages the list of bound devices and supports remote device revocation.
@riverpod
class DeviceListNotifier extends _$DeviceListNotifier {
  /// Persisted idempotency key for the in-flight revoke request.
  /// Cleared after success; retained across retries so the server
  /// deduplicates network-retry re-submissions (Rule 8).
  String? _pendingRevokeKey;

  @override
  Future<List<DeviceInfo>> build() =>
      ref.watch(settingsRepositoryProvider).getDevices();

  Future<void> revokeDevice({
    required String deviceId,
    required String bioToken,
    required String bioChallenge,
    required String bioTimestamp,
  }) async {
    _pendingRevokeKey ??= const Uuid().v4();
    final prev = state;
    // Optimistic remove
    state = AsyncData(
      prev.value?.where((d) => d.deviceId != deviceId).toList() ?? [],
    );
    try {
      await ref.read(settingsRepositoryProvider).revokeDevice(
            deviceId: deviceId,
            bioToken: bioToken,
            bioChallenge: bioChallenge,
            bioTimestamp: bioTimestamp,
            idempotencyKey: _pendingRevokeKey!,
          );
      _pendingRevokeKey = null; // clear after confirmed success
      AppLogger.info('revokeDevice success: $deviceId');
    } on Object catch (e) {
      AppLogger.warning('revokeDevice failed: $e');
      state = prev;
      rethrow;
    }
  }
}
