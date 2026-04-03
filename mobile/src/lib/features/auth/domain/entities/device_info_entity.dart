import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_info_entity.freezed.dart';

/// Domain entity representing a device registered to the user's account.
///
/// Maps from AMS GET /v1/auth/devices response.
@freezed
abstract class DeviceInfoEntity with _$DeviceInfoEntity {
  const factory DeviceInfoEntity({
    required String deviceId,
    required String deviceName,
    required String osType,
    required String status,
    required DateTime loginTime,
    required DateTime lastActivityTime,
    required bool isCurrentDevice,
    required bool biometricRegistered,
    String? locationCountry,
    String? locationCity,
    String? biometricType,
  }) = _DeviceInfoEntity;
}

/// Device status values per AMS contract.
class DeviceStatus {
  static const active = 'ACTIVE';
  static const locallyLoggedOut = 'LOCALLY_LOGGED_OUT';
  static const remotelyKicked = 'REMOTELY_KICKED';
  static const sessionExpired = 'SESSION_EXPIRED';
}
