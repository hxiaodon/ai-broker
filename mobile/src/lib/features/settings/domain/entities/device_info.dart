import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_info.freezed.dart';

enum DeviceStatus { active, locallyLoggedOut, remotelyKicked, sessionExpired }

/// A bound device from GET /v1/auth/devices.
@freezed
abstract class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    required String deviceId,
    required String deviceName,
    required String platform,
    required DeviceStatus status,
    required DateTime lastActiveAt,
    required bool isCurrentDevice,
  }) = _DeviceInfo;
}
