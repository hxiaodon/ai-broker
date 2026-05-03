import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/auth/device_info_service.dart' as svc;
import '../../../../core/logging/app_logger.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/security/screen_protection_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../../shared/widgets/error/error_view.dart';
import '../../application/device_list_notifier.dart';
import '../../application/trade_settings_notifier.dart';
import '../../data/settings_repository_impl.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/trade_settings.dart';

const _kBiometricLoginEnabledKey = 'settings.security.biometricLogin';

/// Security settings screen — PRD §6.
///
/// Sections: biometric management, device management, change phone,
///           account lock, account deactivation.
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen>
    with ScreenProtectionMixin {
  final _localAuth = LocalAuthentication();
  bool _biometricLoginEnabled = true;
  bool _biometricStateLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricLoginState();
  }

  Future<void> _loadBiometricLoginState() async {
    final value = await ref
        .read(secureStorageServiceProvider)
        .read(_kBiometricLoginEnabledKey);
    if (mounted) setState(() => _biometricLoginEnabled = value != 'false');
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(deviceListProvider);
    final tradeAsync = ref.watch(tradeSettingsProvider);
    final orderBiometricEnabled =
        tradeAsync.value?.confirmationMethod != OrderConfirmationMethod.slideOnly;

    return Scaffold(
      backgroundColor: ColorTokens.greenUp.background,
      appBar: AppBar(
        title: const Text('安全设置'),
        backgroundColor: ColorTokens.greenUp.surface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // ── Biometric Settings ──────────────────────────────────────────
          _SectionHeader('生物识别'),
          _SettingsToggleItem(
            title: '生物识别登录',
            subtitle: 'Face ID / 指纹，下次打开可免 OTP',
            value: _biometricLoginEnabled,
            onChanged: _biometricStateLoading
                ? null
                : (v) => _toggleBiometricLogin(context, v),
          ),
          _SettingsToggleItem(
            title: '下单生物识别确认',
            subtitle: '每次委托下单需要生物识别',
            value: orderBiometricEnabled,
            onChanged: (v) => _toggleOrderBiometric(context, v),
          ),
          _SettingsToggleItem(
            title: '出金生物识别确认',
            subtitle: '必需，不可关闭',
            value: true,
            enabled: false, // always required (PRD §6.1)
            onChanged: null,
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorTokens.greenUp.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '下单和出金需通过生物识别验证，保护账户资金安全',
              style: TextStyle(
                color: ColorTokens.greenUp.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),

          // ── Device Management ───────────────────────────────────────────
          _SectionHeader('已登录设备'),
          devicesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => ErrorView(
              message: '加载设备列表失败',
              onRetry: () => ref.invalidate(deviceListProvider),
            ),
            data: (List<DeviceInfo> devices) => _DeviceList(
              devices: devices,
              onRevoke: (d) => _confirmRevokeDevice(context, d),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorTokens.greenUp.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: ColorTokens.greenUp.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '新设备登录时将收到通知，如发现异常登录请立即移除设备',
                    style: TextStyle(
                      color: ColorTokens.greenUp.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Account Actions ─────────────────────────────────────────────
          _SectionHeader('账户操作'),
          _NavItem(
            icon: Icons.phone_android_outlined,
            title: '更换手机号',
            subtitle: '双重 OTP 验证，更换后所有设备重新登录',
            onTap: () => context.push(RouteNames.changePhone),
          ),
          _NavItem(
            icon: Icons.lock_outline,
            title: '紧急锁定账户',
            subtitle: '锁定后需联系客服解锁（1-3 个工作日）',
            onTap: () => _confirmLockAccount(context),
          ),

          // ── Danger Zone ─────────────────────────────────────────────────
          _SectionHeader('危险操作'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorTokens.greenUp.error,
                side: BorderSide(color: ColorTokens.greenUp.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => context.push(RouteNames.accountDeactivation),
              child: const Text('注销账户'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Action handlers ────────────────────────────────────────────────────────

  Future<void> _toggleBiometricLogin(BuildContext ctx, bool enable) async {
    if (enable) {
      final ss = ref.read(secureStorageServiceProvider);
      await ss.write(_kBiometricLoginEnabledKey, 'true');
      if (mounted) setState(() => _biometricLoginEnabled = true);
    } else {
      await _disableBiometricLoginWithOtp();
    }
  }

  Future<void> _disableBiometricLoginWithOtp() async {
    if (!mounted) return;
    setState(() => _biometricStateLoading = true);

    // Step 1: Send OTP to current phone
    try {
      await ref.read(settingsRepositoryProvider).sendOtpForBiometricDisable();
    } on Object catch (e) {
      AppLogger.warning('sendOtpForBiometricDisable failed: ${e.runtimeType}');
      if (mounted) {
        setState(() => _biometricStateLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发送验证码失败，请稍后重试')),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _biometricStateLoading = false);

    // Step 2: OTP input dialog — use widget's own context (guarded by mounted above)
    final otpController = TextEditingController();
    final otpCode = await showDialog<String?>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('关闭生物识别登录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入发送至您手机的 6 位验证码以确认关闭生物识别登录'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '6 位验证码',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(null),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx).pop(otpController.text.trim()),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    otpController.dispose();

    if (otpCode == null || otpCode.length != 6 || !mounted) return;

    // Step 3: Verify OTP + disable on server
    setState(() => _biometricStateLoading = true);
    try {
      await ref
          .read(settingsRepositoryProvider)
          .disableBiometricLogin(otpCode: otpCode);
      await ref
          .read(secureStorageServiceProvider)
          .write(_kBiometricLoginEnabledKey, 'false');
      if (mounted) {
        setState(() {
          _biometricLoginEnabled = false;
          _biometricStateLoading = false;
        });
      }
    } on Object catch (e) {
      AppLogger.warning('disableBiometricLogin failed: ${e.runtimeType}');
      if (mounted) {
        setState(() => _biometricStateLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证失败，请重试')),
        );
      }
    }
  }

  Future<void> _toggleOrderBiometric(BuildContext ctx, bool enable) async {
    final tradeSettings = ref.read(tradeSettingsProvider).value;
    if (tradeSettings == null) return;
    final method = enable
        ? OrderConfirmationMethod.slideAndBiometric
        : OrderConfirmationMethod.slideOnly;
    await ref
        .read(tradeSettingsProvider.notifier)
        .saveSettings(tradeSettings.copyWith(confirmationMethod: method));
  }

  Future<void> _confirmRevokeDevice(BuildContext ctx, DeviceInfo device) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('注销设备'),
        content: Text('确定要注销 "${device.deviceName}" 吗？该设备将被强制退出登录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text('注销', style: TextStyle(color: ColorTokens.greenUp.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      // C-1 guard: real Secure Enclave / Keystore signing not yet available.
      // In release builds, block the feature and direct users to customer service.
      // TODO(phase2): replace stub with BiometricKeyManager signature.
      if (kReleaseMode) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('远程注销功能正在建设中，如需帮助请联系客服')),
          );
        }
        return;
      }

      // M-1: enforce biometricOnly so the operation cannot be downgraded to PIN/password
      final authenticated = await _localAuth.authenticate(
        localizedReason: '请验证身份以注销远程设备',
        biometricOnly: true,
      );
      if (!authenticated || !mounted) return;

      // Build stub biometric signature (debug-only path, guarded by kReleaseMode above)
      final deviceInfoService = ref.read(svc.deviceInfoServiceProvider);
      final currentDeviceId = await deviceInfoService.getDeviceId();
      final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final bioTimestamp = DateTime.now().toUtc().toIso8601String();
      final bioToken = '$timestamp|$currentDeviceId|revoke|stub_signature';

      await ref.read(deviceListProvider.notifier).revokeDevice(
            deviceId: device.deviceId,
            bioToken: bioToken,
            bioChallenge: 'debug-challenge',
            bioTimestamp: bioTimestamp,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${device.deviceName}" 已成功注销')),
        );
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请稍后重试')),
        );
      }
    }
  }

  Future<void> _confirmLockAccount(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('锁定账户'),
        content: const Text(
          '锁定后，所有交易、出入金功能将被冻结。\n解锁需联系客服，可能影响 1-3 个工作日的正常交易。\n\n确定要锁定账户吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text('确定锁定', style: TextStyle(color: ColorTokens.greenUp.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Require biometric before locking — high-risk irreversible operation (PRD §6.1)
    final authenticated = await _localAuth.authenticate(
      localizedReason: '请验证身份以锁定账户',
      biometricOnly: true,
    );
    if (!authenticated || !mounted) return;

    try {
      await ref.read(settingsRepositoryProvider).lockAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('账户已锁定，请联系客服解锁')),
        );
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请稍后重试')),
        );
      }
    }
  }
}

// ─── Device List ──────────────────────────────────────────────────────────────

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.devices, required this.onRevoke});
  final List<DeviceInfo> devices;
  final void Function(DeviceInfo) onRevoke;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '暂无已登录设备',
          style: TextStyle(color: ColorTokens.greenUp.onSurfaceVariant),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: devices.map((d) => _DeviceItem(device: d, onRevoke: onRevoke)).toList(),
      ),
    );
  }
}

class _DeviceItem extends StatelessWidget {
  const _DeviceItem({required this.device, required this.onRevoke});
  final DeviceInfo device;
  final void Function(DeviceInfo) onRevoke;

  @override
  Widget build(BuildContext context) {
    final isCurrent = device.isCurrentDevice;
    final icon = device.platform.toLowerCase().contains('ios') ||
            device.platform.toLowerCase().contains('android')
        ? Icons.smartphone_outlined
        : Icons.laptop_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorTokens.greenUp.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColorTokens.greenUp.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorTokens.greenUp.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: ColorTokens.greenUp.onSurface),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ColorTokens.greenUp.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '本机',
                          style: TextStyle(
                            color: ColorTokens.greenUp.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${device.platform} · 上次活跃 ${_formatTime(device.lastActiveAt)}',
                  style: TextStyle(
                    color: ColorTokens.greenUp.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            TextButton(
              onPressed: () => onRevoke(device),
              child: Text(
                '移除',
                style: TextStyle(
                  color: ColorTokens.greenUp.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} 天前';
    if (diff.inHours > 0) return '${diff.inHours} 小时前';
    return '刚刚';
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: ColorTokens.greenUp.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsToggleItem extends StatelessWidget {
  const _SettingsToggleItem({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.greenUp.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        color: ColorTokens.greenUp.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: ColorTokens.greenUp.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: ColorTokens.greenUp.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 1),
        child: Row(
          children: [
            Icon(icon, size: 22, color: ColorTokens.greenUp.onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: ColorTokens.greenUp.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: ColorTokens.greenUp.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
