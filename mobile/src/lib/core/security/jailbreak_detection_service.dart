import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../logging/app_logger.dart';
import '../errors/app_exception.dart';

part 'jailbreak_detection_service.g.dart';

/// Detects jailbroken (iOS) or rooted (Android) devices.
///
/// ## Phase 1 (Current)
/// File-path heuristic checks — a basic deterrent that is easily bypassed
/// on advanced jailbreaks. Sufficient for Phase 1 launch gating.
///
/// ## Phase 2 Roadmap
/// - Android: Play Integrity API — server-side verdict signed by Google,
///   eliminating client-side bypass risk.
/// - iOS: App Attest — cryptographic attestation from Apple's servers
///   verifying the app is genuine and the device is not compromised.
///
/// Per security policy: warn user and restrict trading functionality
/// when compromise is detected. Does NOT block non-trading features.
class JailbreakDetectionService {
  JailbreakDetectionService();

  bool? _cachedResult;

  /// Returns true if the device appears to be jailbroken or rooted.
  Future<bool> isDeviceCompromised() async {
    _cachedResult ??= await _checkCompromise();
    return _cachedResult!;
  }

  /// Throws [SecurityException] if device is compromised.
  Future<void> enforceDeviceSecurity() async {
    if (await isDeviceCompromised()) {
      AppLogger.warning('Device security compromise detected');
      throw const SecurityException(
        message: 'Device security requirements not met. Trading is disabled.',
      );
    }
  }

  Future<bool> _checkCompromise() async {
    if (Platform.isIOS) {
      return _checkIosJailbreak();
    } else if (Platform.isAndroid) {
      return _checkAndroidRoot();
    }
    return false;
  }

  bool _checkIosJailbreak() {
    // Heuristic: check for common jailbreak file paths
    const jailbreakPaths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt',
    ];
    for (final path in jailbreakPaths) {
      if (File(path).existsSync()) {
        AppLogger.warning('Jailbreak indicator found: $path');
        return true;
      }
    }
    return false;
  }

  bool _checkAndroidRoot() {
    // Heuristic: check for common root file paths
    const rootPaths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
    ];
    for (final path in rootPaths) {
      if (File(path).existsSync()) {
        AppLogger.warning('Root indicator found: $path');
        return true;
      }
    }
    return false;
  }
}

@Riverpod(keepAlive: true)
JailbreakDetectionService jailbreakDetectionService(
  Ref ref,
) {
  return JailbreakDetectionService();
}
