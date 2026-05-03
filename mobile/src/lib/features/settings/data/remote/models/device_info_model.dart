import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entities/device_info.dart';

part 'device_info_model.freezed.dart';
part 'device_info_model.g.dart';

@freezed
abstract class DeviceInfoModel with _$DeviceInfoModel {
  const factory DeviceInfoModel({
    @JsonKey(name: 'device_id') required String deviceId,
    @JsonKey(name: 'device_name') required String deviceName,
    required String platform,
    required String status,
    @JsonKey(name: 'last_active_at') required String lastActiveAt,
    @JsonKey(name: 'is_current_device') @Default(false) bool isCurrentDevice,
  }) = _DeviceInfoModel;

  factory DeviceInfoModel.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoModelFromJson(json);

  const DeviceInfoModel._();

  DeviceInfo toDomain() => DeviceInfo(
        deviceId: deviceId,
        deviceName: deviceName,
        platform: platform,
        status: _parseStatus(status),
        lastActiveAt: DateTime.parse(lastActiveAt).toUtc(),
        isCurrentDevice: isCurrentDevice,
      );

  static DeviceStatus _parseStatus(String raw) => switch (raw.toUpperCase()) {
        'LOCALLY_LOGGED_OUT' => DeviceStatus.locallyLoggedOut,
        'REMOTELY_KICKED' => DeviceStatus.remotelyKicked,
        'SESSION_EXPIRED' => DeviceStatus.sessionExpired,
        _ => DeviceStatus.active,
      };
}
