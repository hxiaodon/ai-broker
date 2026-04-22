import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/token_service.dart';
import '../config/environment_config.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';
import '../network/authenticated_dio.dart';
import '../storage/secure_storage_service.dart';

part 'session_key_service.g.dart';

class _Keys {
  static const keyId = 'trading.session_key_id';
  static const secret = 'trading.session_key_secret';
  static const expiresAt = 'trading.session_key_expires_at';
}

typedef SessionKey = ({String keyId, String secret});

/// Manages the dynamic HMAC session key lifecycle (S-01).
///
/// Independent 30-min TTL (not tied to access token). Refreshes proactively
/// when within 5 min of expiry. On fetch failure, throws [AuthException] —
/// no fallback to compile-time secret.
class SessionKeyService {
  SessionKeyService({required Dio dio, required SecureStorageService storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final SecureStorageService _storage;

  String? _cachedKeyId;
  String? _cachedSecret;
  DateTime? _cachedExpiresAt;

  /// Returns current session key, refreshing if within 5 min of expiry.
  Future<SessionKey> getSessionKey() async {
    if (_isCacheValid()) return (keyId: _cachedKeyId!, secret: _cachedSecret!);
    await _loadFromStorage();
    if (_isCacheValid()) return (keyId: _cachedKeyId!, secret: _cachedSecret!);
    return _fetchAndStore();
  }

  Future<SessionKey> rotate() => _fetchAndStore();

  Future<void> clear() async {
    _cachedKeyId = null;
    _cachedSecret = null;
    _cachedExpiresAt = null;
    await Future.wait([
      _storage.delete(_Keys.keyId),
      _storage.delete(_Keys.secret),
      _storage.delete(_Keys.expiresAt),
    ]);
  }

  bool _isCacheValid() {
    if (_cachedKeyId == null || _cachedSecret == null || _cachedExpiresAt == null) {
      return false;
    }
    return DateTime.now().toUtc().isBefore(
          _cachedExpiresAt!.subtract(const Duration(minutes: 5)),
        );
  }

  Future<void> _loadFromStorage() async {
    final keyId = await _storage.read(_Keys.keyId);
    final secret = await _storage.read(_Keys.secret);
    final expiresAtRaw = await _storage.read(_Keys.expiresAt);
    if (keyId == null || secret == null || expiresAtRaw == null) return;
    _cachedKeyId = keyId;
    _cachedSecret = secret;
    _cachedExpiresAt = DateTime.tryParse(expiresAtRaw)?.toUtc();
  }

  Future<SessionKey> _fetchAndStore() async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>('/api/v1/auth/session-key');
      final data = resp.data!;
      final keyId = data['key_id'] as String;
      final secret = data['hmac_secret'] as String;
      final expiresAt = DateTime.parse(data['expires_at'] as String).toUtc();

      _cachedKeyId = keyId;
      _cachedSecret = secret;
      _cachedExpiresAt = expiresAt;

      await Future.wait([
        _storage.write(_Keys.keyId, keyId),
        _storage.write(_Keys.secret, secret),
        _storage.write(_Keys.expiresAt, expiresAt.toIso8601String()),
      ]);

      AppLogger.debug('SessionKey rotated: keyId=$keyId expires=$expiresAt');
      return (keyId: keyId, secret: secret);
    } on DioException catch (e) {
      AppLogger.error('Failed to fetch session key', error: e);
      throw AuthException(message: '安全验证失败，请重新登录', cause: e);
    }
  }
}

@Riverpod(keepAlive: true)
SessionKeyService sessionKeyService(Ref ref) {
  final tokenSvc = ref.read(tokenServiceProvider);
  final storage = ref.read(secureStorageServiceProvider);
  final dio = createAuthenticatedDio(
    baseUrl: EnvironmentConfig.instance.tradingBaseUrl,
    tokenService: tokenSvc,
  );
  return SessionKeyService(dio: dio, storage: storage);
}
