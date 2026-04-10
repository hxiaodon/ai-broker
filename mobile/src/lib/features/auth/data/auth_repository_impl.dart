import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/device_info_service.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/authenticated_dio.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/entities/auth_token.dart';
import '../domain/entities/device_info_entity.dart';
import '../domain/repositories/auth_repository.dart';
import 'remote/auth_remote_data_source.dart';
import 'remote/auth_request_models.dart';
import 'remote/auth_response_models.dart';

part 'auth_repository_impl.g.dart';

// ---------------------------------------------------------------------------
// Environment base URL — replace with AppConfig in Phase 2
// ---------------------------------------------------------------------------
const _kAmsBaseUrl = String.fromEnvironment(
  'AMS_BASE_URL',
  defaultValue: 'https://api.example.com',
);

/// Production implementation of [AuthRepository].
///
/// Maps data-layer DTOs to domain entities. Delegates network calls to
/// [AuthRemoteDataSource]. Stores tokens via [TokenService].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenService tokenService,
    required DeviceInfoService deviceInfoService,
    required SecureStorageService secureStorage,
  })  : _remote = remoteDataSource,
        _tokenService = tokenService,
        _deviceInfoService = deviceInfoService,
        _secureStorage = secureStorage;

  final AuthRemoteDataSource _remote;
  final TokenService _tokenService;
  final DeviceInfoService _deviceInfoService;
  final SecureStorageService _secureStorage;

  static const _biometricRegisteredKey = 'auth.biometric_registered';

  @override
  Future<OtpSendResult> sendOtp({
    required String phoneNumber,
    required String idempotencyKey,
  }) async {
    final deviceInfo = await _deviceInfoService.getDeviceInfo();
    final response = await _remote.sendOtp(
      request: SendOtpRequest(phoneNumber: phoneNumber),
      idempotencyKey: idempotencyKey,
      deviceId: deviceInfo.deviceId,
    );

    AppLogger.debug('OTP send succeeded — requestId: ${response.requestId}');
    return OtpSendResult(
      requestId: response.requestId,
      maskedPhoneNumber: response.phoneNumber,
      expiresInSeconds: response.expiresInSeconds,
      retryAfterSeconds: response.retryAfterSeconds,
    );
  }

  @override
  Future<OtpVerifyResult> verifyOtp({
    required String requestId,
    required String otpCode,
    required String phoneNumber,
    required String idempotencyKey,
  }) async {
    final deviceInfo = await _deviceInfoService.getDeviceInfo();
    final raw = await _remote.verifyOtp(
      request: VerifyOtpRequest(
        requestId: requestId,
        otpCode: otpCode,
        phoneNumber: phoneNumber,
      ),
      idempotencyKey: idempotencyKey,
      deviceId: deviceInfo.deviceId,
    );

    final status = raw['status'] as String? ?? '';

    if (status == 'OTP_VERIFIED_NEW_USER') {
      return const OtpVerifyResult(status: OtpVerifyStatus.newUser);
    }

    // Existing user: parse tokens
    final dto = VerifyOtpExistingUserResponse.fromJson(raw);
    final expiresAt = DateTime.now()
        .toUtc()
        .add(Duration(seconds: dto.expiresInSeconds));

    final token = AuthToken(
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
      accessTokenExpiresAt: expiresAt,
      accountId: dto.accountId,
      accountStatus: dto.accountStatus,
    );

    await _tokenService.saveTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      accessTokenExpiresAt: token.accessTokenExpiresAt,
    );

    AppLogger.info('OTP verified — account: ${dto.accountId}');
    return OtpVerifyResult(
      status: OtpVerifyStatus.existingUser,
      token: token,
      accountStatus: dto.accountStatus,
    );
  }

  @override
  Future<AuthToken> refreshToken({required String refreshToken}) async {
    final deviceInfo = await _deviceInfoService.getDeviceInfo();
    final response = await _remote.refreshToken(
      request: RefreshTokenRequest(refreshToken: refreshToken),
      deviceId: deviceInfo.deviceId,
    );

    final expiresAt = DateTime.now()
        .toUtc()
        .add(Duration(seconds: response.expiresInSeconds));

    // Re-read accountId from current token (refresh doesn't return it)
    final existingAccess = await _tokenService.getAccessToken();
    final accountId = _extractAccountIdFromJwt(existingAccess) ?? 'unknown';

    final token = AuthToken(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      accessTokenExpiresAt: expiresAt,
      accountId: accountId,
      accountStatus: 'ACTIVE',
    );

    await _tokenService.saveTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      accessTokenExpiresAt: token.accessTokenExpiresAt,
    );

    AppLogger.debug('Token refreshed successfully');
    return token;
  }

  @override
  Future<void> registerBiometric({
    required String biometricType,
    required String deviceFingerprint,
    String? deviceName,
  }) async {
    final deviceInfo = await _deviceInfoService.getDeviceInfo();
    await _remote.registerBiometric(
      request: RegisterBiometricRequest(
        biometricType: biometricType,
        deviceFingerprint: deviceFingerprint,
        deviceName: deviceName,
      ),
      deviceId: deviceInfo.deviceId,
    );

    // Mark biometric registered locally
    await _secureStorage.write(_biometricRegisteredKey, 'true');
    AppLogger.info('Biometric registered: $biometricType');
  }

  @override
  Future<String> verifyBiometric({
    required String operation,
    required String biometricSignature,
    required String deviceFingerprint,
  }) async {
    final deviceInfo = await _deviceInfoService.getDeviceInfo();
    final response = await _remote.verifyBiometric(
      request: VerifyBiometricRequest(
        operation: operation,
        deviceFingerprint: deviceFingerprint,
      ),
      biometricSignature: biometricSignature,
      deviceId: deviceInfo.deviceId,
    );
    return response.verificationToken;
  }

  @override
  Future<void> logout() async {
    final deviceInfo = await _deviceInfoService.getDeviceInfo();
    try {
      await _remote.logout(deviceId: deviceInfo.deviceId);
    } on DioException catch (e) {
      AppLogger.warning('Logout server call failed — clearing local state anyway: $e');
    }
    await _tokenService.clearTokens();
    await _secureStorage.delete(_biometricRegisteredKey);
    AppLogger.info('Logout complete — tokens cleared');
  }

  @override
  Future<List<DeviceInfoEntity>> getDevices() async {
    final deviceInfo = await _deviceInfoService.getDeviceInfo();
    final response = await _remote.getDevices(deviceId: deviceInfo.deviceId);
    return response.devices.map(_mapDeviceDto).toList();
  }

  @override
  Future<void> revokeDevice({
    required String targetDeviceId,
    required String biometricSignature,
  }) async {
    final deviceInfo = await _deviceInfoService.getDeviceInfo();
    await _remote.revokeDevice(
      targetDeviceId: targetDeviceId,
      currentDeviceId: deviceInfo.deviceId,
      biometricSignature: biometricSignature,
    );
    AppLogger.info('Device revoked: $targetDeviceId');
  }

  /// Check whether biometric has been registered on this device.
  Future<bool> isBiometricRegistered() async {
    final val = await _secureStorage.read(_biometricRegisteredKey);
    return val == 'true';
  }

  DeviceInfoEntity _mapDeviceDto(DeviceInfoDto dto) {
    return DeviceInfoEntity(
      deviceId: dto.deviceId,
      deviceName: dto.deviceName,
      osType: dto.osType,
      status: dto.status,
      loginTime: DateTime.parse(dto.loginTime).toUtc(),
      lastActivityTime: dto.lastActivityTime != null
          ? DateTime.parse(dto.lastActivityTime!).toUtc()
          : DateTime.parse(dto.loginTime).toUtc(),
      isCurrentDevice: dto.isCurrentDevice ?? false,
      biometricRegistered: dto.biometricRegistered ?? false,
      locationCountry: dto.locationCountry,
      locationCity: dto.locationCity,
      biometricType: dto.biometricType,
    );
  }

  /// Decode account_id claim from JWT payload without verifying signature.
  /// Used only to maintain accountId after a token refresh (non-security path).
  String? _extractAccountIdFromJwt(String? jwt) {
    if (jwt == null) return null;
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      // Add padding if needed for base64 decode
      final payload = parts[1];
      final padded = payload.padRight((payload.length + 3) & ~3, '=');
      final decoded = String.fromCharCodes(
        _base64UrlDecode(padded),
      );
      final claims = _parseJsonSimple(decoded);
      return claims['account_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  List<int> _base64UrlDecode(String input) {
    final normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    final bytes = <int>[];
    for (var i = 0; i < normalized.length; i += 4) {
      final chunk = normalized.substring(i, i + 4);
      final b0 = _b64Char(chunk[0]);
      final b1 = _b64Char(chunk[1]);
      final b2 = chunk[2] == '=' ? 0 : _b64Char(chunk[2]);
      final b3 = chunk[3] == '=' ? 0 : _b64Char(chunk[3]);
      bytes.add((b0 << 2) | (b1 >> 4));
      if (chunk[2] != '=') bytes.add(((b1 & 0xF) << 4) | (b2 >> 2));
      if (chunk[3] != '=') bytes.add(((b2 & 0x3) << 6) | b3);
    }
    return bytes;
  }

  int _b64Char(String c) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    return chars.indexOf(c);
  }

  Map<String, dynamic> _parseJsonSimple(String json) {
    // Minimal JSON object parser for JWT claims (account_id is a string field)
    final result = <String, dynamic>{};
    final re = RegExp(r'"([^"]+)"\s*:\s*"([^"]*)"');
    for (final match in re.allMatches(json)) {
      result[match.group(1)!] = match.group(2)!;
    }
    return result;
  }
}

/// Wires up [AuthRepositoryImpl] with all required dependencies.
///
/// - Creates a dedicated [Dio] instance for the AMS service (SPKI pinned).
/// - Injects [TokenService], [DeviceInfoService], [SecureStorageService].
@Riverpod(keepAlive: true)
AuthRepositoryImpl authRepository(Ref ref) {
  final tokenSvc = ref.read(tokenServiceProvider);
  final dio = createAuthenticatedDio(
    baseUrl: _kAmsBaseUrl,
    tokenService: tokenSvc,
  );
  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSource(dio),
    tokenService: tokenSvc,
    deviceInfoService: ref.read(deviceInfoServiceProvider),
    secureStorage: ref.read(secureStorageServiceProvider),
  );
}
