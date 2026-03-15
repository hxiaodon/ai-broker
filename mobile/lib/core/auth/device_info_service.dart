import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../logging/app_logger.dart';

part 'device_info_service.g.dart';

/// Device information and persistent device ID management.
///
/// Device ID is generated once (UUID v4) and stored in secure storage
/// so it survives app reinstalls on Android but resets on iOS restore-from-backup.
class DeviceInfo {
  const DeviceInfo({
    required this.deviceId,
    required this.platform,
    required this.osVersion,
    required this.model,
    required this.appVersion,
  });

  final String deviceId;
  final String platform;
  final String osVersion;
  final String model;
  final String appVersion;

  Map<String, String> toHeaders() => {
        'X-Device-ID': deviceId,
        'X-Platform': platform,
        'X-OS-Version': osVersion,
        'X-App-Version': appVersion,
      };
}

class DeviceInfoService {
  DeviceInfoService(this._plugin, this._secureStorage);

  static const _deviceIdKey = 'device.persistent_id';

  final DeviceInfoPlugin _plugin;
  final FlutterSecureStorage _secureStorage;

  DeviceInfo? _cached;

  Future<DeviceInfo> getDeviceInfo() async {
    if (_cached != null) return _cached!;
    _cached = await _loadDeviceInfo();
    return _cached!;
  }

  Future<String> getDeviceId() async {
    final info = await getDeviceInfo();
    return info.deviceId;
  }

  Future<DeviceInfo> _loadDeviceInfo() async {
    final deviceId = await _getOrCreateDeviceId();

    if (Platform.isIOS) {
      final iosInfo = await _plugin.iosInfo;
      return DeviceInfo(
        deviceId: deviceId,
        platform: 'ios',
        osVersion: iosInfo.systemVersion,
        model: iosInfo.model,
        appVersion: 'unknown', // Populated by PackageInfoService in Phase 2
      );
    } else if (Platform.isAndroid) {
      final androidInfo = await _plugin.androidInfo;
      return DeviceInfo(
        deviceId: deviceId,
        platform: 'android',
        osVersion: androidInfo.version.release,
        model: '${androidInfo.manufacturer} ${androidInfo.model}',
        appVersion: 'unknown',
      );
    }

    return DeviceInfo(
      deviceId: deviceId,
      platform: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      model: 'unknown',
      appVersion: 'unknown',
    );
  }

  Future<String> _getOrCreateDeviceId() async {
    try {
      final existing = await _secureStorage.read(key: _deviceIdKey);
      if (existing != null && existing.isNotEmpty) return existing;

      final newId = const Uuid().v4();
      await _secureStorage.write(key: _deviceIdKey, value: newId);
      AppLogger.info('Created new device ID: $newId');
      return newId;
    } catch (e, st) {
      AppLogger.error('Failed to get/create device ID', error: e, stackTrace: st);
      // Fall back to an ephemeral ID (not persisted)
      return const Uuid().v4();
    }
  }
}

@Riverpod(keepAlive: true)
DeviceInfoService deviceInfoService(DeviceInfoServiceRef ref) {
  return DeviceInfoService(
    DeviceInfoPlugin(),
    const FlutterSecureStorage(
      iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device),
      aOptions: AndroidOptions(migrateOnAlgorithmChange: true),
    ),
  );
}
