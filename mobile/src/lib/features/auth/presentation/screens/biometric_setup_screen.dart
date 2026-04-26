import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../data/auth_repository_impl.dart';

/// BiometricSetupScreen — first-time biometric enrollment guide (T04).
///
/// Prototype: mobile/prototypes/01-auth/hifi/biometric-setup.html
///
/// Rules from PRD §6.2:
///   - Show after first OTP login
///   - Skip counter: max 3 prompts, then never show again
///   - Skip → go to market tab
///   - Enable → trigger local biometric auth → register on server
class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  final _localAuth = LocalAuthentication();
  bool _isLoading = false;

  static const _skipCountKey = 'auth.biometric_skip_count';

  Future<void> _enableBiometric() async {
    setState(() => _isLoading = true);

    try {
      // Check device biometric availability
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        _showNoBiometricDialog();
        return;
      }

      // Trigger local biometric prompt
      final authenticated = await _localAuth.authenticate(
        localizedReason: '开启 Face ID 快捷登录',
      );

      if (!authenticated) return;

      // Get biometric type
      final types = await _localAuth.getAvailableBiometrics();
      final biometricType = _mapBiometricType(types);

      // Register on server
      final repo = ref.read(authRepositoryProvider);
      await repo.registerBiometric(
        biometricType: biometricType,
        deviceFingerprint: _generateDeviceFingerprint(types),
      );

      if (!mounted) return;
      _showSuccessAndNavigate();
    } on Object catch (e, st) {
      AppLogger.warning('Biometric setup failed', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('开启失败，请稍后在设置中手动开启')),
        );
        context.go(RouteNames.market);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Face ID 已开启'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) context.go(RouteNames.market);
    });
  }

  Future<void> _skip() async {
    // Track skip count — max 3 times per PRD §6.2
    final storage = ref.read(secureStorageServiceProvider);
    final raw = await storage.read(_skipCountKey);
    final count = int.tryParse(raw ?? '0') ?? 0;
    await storage.write(_skipCountKey, (count + 1).toString());
    AppLogger.debug('Biometric setup skipped (count: ${count + 1}/3)');

    if (mounted) context.go(RouteNames.market);
  }

  void _showNoBiometricDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设备不支持生物识别'),
        content: const Text('您的设备未设置 Face ID 或指纹，请先在系统设置中完成设置'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(RouteNames.market);
            },
            child: const Text('跳过'),
          ),
        ],
      ),
    );
  }

  String _mapBiometricType(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) return 'FACE_ID';
    if (types.contains(BiometricType.fingerprint)) return 'FINGERPRINT';
    if (types.contains(BiometricType.strong)) return 'FINGERPRINT';
    return 'FINGERPRINT';
  }

  String _generateDeviceFingerprint(List<BiometricType> types) {
    // Fingerprint for change detection — use biometric type list hash
    return types.map((t) => t.name).join('_');
  }

  @override
  Widget build(BuildContext context) {
    const colors = ColorTokens.greenUp;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          '设置 Face ID',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _skip,
            child: Text(
              '跳过',
              style: TextStyle(fontSize: 13, color: colors.primary),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          32,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            // Biometric icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.primary, width: 3),
                color: colors.primary.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.face,
                size: 48,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '开启 Face ID 快捷登录',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '下次打开 App 无需输入验证码，\n一眼即可完成登录',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '关于 Face ID 安全',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '生物识别仅存储于本设备，MetaStock 无法读取您的面容数据',
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
            const Spacer(),
            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _enableBiometric,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : const Text(
                        '开启 Face ID',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isLoading ? null : _skip,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '暂不开启',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '最多提醒 3 次，之后可在「设置 › 安全」中手动开启',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
