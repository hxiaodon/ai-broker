import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_auth_service.g.dart';

/// Thin injectable wrapper around [LocalAuthentication].
///
/// Extracting this into a provider allows tests to override biometric behaviour
/// without touching platform channels.
class LocalAuthService {
  LocalAuthService({LocalAuthentication? localAuth})
      : _auth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> authenticate({required String localizedReason}) =>
      _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
      );

  Future<bool> isAvailable() => _auth.canCheckBiometrics;

  Future<List<BiometricType>> getAvailableBiometrics() =>
      _auth.getAvailableBiometrics();
}

@Riverpod(keepAlive: true)
LocalAuthService localAuthService(Ref ref) => LocalAuthService();
