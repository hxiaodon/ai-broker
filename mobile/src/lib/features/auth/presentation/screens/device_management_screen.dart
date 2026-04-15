import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/auth/device_info_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/device_info_entity.dart';

/// DeviceManagementScreen — manage registered devices (T06).
///
/// Prototype: mobile/prototypes/01-auth/hifi/devices.html
///
/// Rules from PRD §6.3:
///   - Max 3 concurrent devices
///   - Remote revoke requires biometric confirmation on current device
///   - Current device labeled "本机"
///   - Device list: name / platform / last active
class DeviceManagementScreen extends ConsumerStatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  ConsumerState<DeviceManagementScreen> createState() =>
      _DeviceManagementScreenState();
}

class _DeviceManagementScreenState
    extends ConsumerState<DeviceManagementScreen> {
  final _localAuth = LocalAuthentication();
  List<DeviceInfoEntity>? _devices;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final devices = await repo.getDevices();
      if (mounted) setState(() => _devices = devices);
    } on Object catch (e, st) {
      AppLogger.error('Load devices failed', error: e, stackTrace: st);
      if (mounted) setState(() => _errorMessage = '加载失败，请重试');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAndRevokeDevice(DeviceInfoEntity device) async {
    final confirmed = await _showRevokeConfirmSheet(device);
    if (!confirmed) return;

    // Biometric confirmation required per PRD §6.3
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要生物识别验证才能注销设备')),
        );
      }
      return;
    }

    final authenticated = await _localAuth.authenticate(
      localizedReason: '验证身份以注销设备 ${device.deviceName}',
    );

    if (!authenticated) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      // Build biometric signature header value
      final deviceInfoService = ref.read(deviceInfoServiceProvider);
      final currentDeviceId = await deviceInfoService.getDeviceId();
      final timestamp =
          DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      // Phase 1 stub: real biometric signing via Secure Enclave / Keystore
      // will be implemented in Phase 2 (see BiometricKeyManager).
      // Phase 1 stub: real biometric signing via Secure Enclave / Keystore
      // will be implemented in Phase 2 (see BiometricKeyManager).
      final biometricSignature =
          '$timestamp|$currentDeviceId|revoke|stub_signature';

      await repo.revokeDevice(
        targetDeviceId: device.deviceId,
        biometricSignature: biometricSignature,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已通过 Face ID 验证，设备已注销')),
        );
        await _loadDevices();
      }
    } on Object catch (e, st) {
      AppLogger.error('Revoke device failed', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注销失败，请重试')),
        );
      }
    }
  }

  Future<bool> _showRevokeConfirmSheet(DeviceInfoEntity device) async {
    const colors = ColorTokens.greenUp;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: colors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '注销设备',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '需在本机通过 Face ID 验证，注销后该设备需重新登录',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.face, size: 18),
                label: const Text('Face ID 确认注销'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.onSurface,
                  side: BorderSide(color: colors.divider),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('取消'),
              ),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    const colors = ColorTokens.greenUp;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        elevation: 0,
        title: Text(
          '登录设备管理',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colors.primary),
            )
          : _errorMessage != null
              ? _buildErrorView(context, colors)
              : _buildDeviceList(context, colors),
    );
  }

  Widget _buildErrorView(BuildContext context, ColorTokens colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, size: 48, color: colors.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDevices,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, ColorTokens colors) {
    final devices = _devices ?? [];
    final currentDevice = devices.where((d) => d.isCurrentDevice).toList();
    final otherDevices = devices.where((d) => !d.isCurrentDevice).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.phone_android, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '设备并发上限',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '同一账户最多 3 台设备同时登录。超出时自动踢出最早登录的设备',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Current device section
        if (currentDevice.isNotEmpty) ...[
          _buildSectionLabel('当前设备', colors),
          _buildDeviceCard(currentDevice, isCurrentSection: true, colors: colors),
        ],

        // Other devices section
        if (otherDevices.isNotEmpty) ...[
          _buildSectionLabel(
            '其他设备（${otherDevices.length}/${devices.length}）',
            colors,
          ),
          _buildDeviceCard(otherDevices, isCurrentSection: false, colors: colors),
        ],

        if (otherDevices.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _confirmRevokeAll(otherDevices, colors),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurface,
                side: BorderSide(color: colors.divider),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('注销所有其他设备'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String label, ColorTokens colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDeviceCard(
    List<DeviceInfoEntity> devices, {
    required bool isCurrentSection,
    required ColorTokens colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < devices.length; i++) ...[
            _buildDeviceRow(devices[i], isCurrentSection, colors),
            if (i < devices.length - 1)
              Divider(height: 1, color: colors.divider),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceRow(
    DeviceInfoEntity device,
    bool isCurrent,
    ColorTokens colors,
  ) {
    final icon = device.osType == 'iOS' ? Icons.phone_iphone : Icons.phone_android;
    final lastActive = timeago.format(
      device.lastActivityTime,
      locale: 'zh',
      allowFromNow: false,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: colors.onSurface),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device.deviceName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    if (device.isCurrentDevice) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0DC582).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '本机',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0DC582),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '最后活跃：$lastActive',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          if (!device.isCurrentDevice)
            GestureDetector(
              onTap: () => _confirmAndRevokeDevice(device),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: colors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '注销',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRevokeAll(
    List<DeviceInfoEntity> devices,
    ColorTokens colors,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: colors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '注销所有其他设备',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '所有其他设备（${devices.length} 台）将被强制退出登录，它们下次打开 App 需重新验证',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(ctx).pop(true),
                icon: const Icon(Icons.face, size: 18),
                label: const Text('Face ID 确认注销全部'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.onSurface,
                  side: BorderSide(color: colors.divider),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('取消'),
              ),
            ),
          ],
        ),
      ),
    );

    if (!(confirmed ?? false)) return;

    for (final device in devices) {
      await _confirmAndRevokeDevice(device);
    }
  }
}
