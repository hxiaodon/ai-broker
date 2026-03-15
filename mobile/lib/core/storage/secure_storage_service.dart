import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

part 'secure_storage_service.g.dart';

/// Wraps [FlutterSecureStorage] with typed read/write and error handling.
///
/// iOS: Keychain Services (kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
/// Android: EncryptedSharedPreferences (AES-256)
class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e, st) {
      AppLogger.error('SecureStorage write failed for key=$key', error: e, stackTrace: st);
      throw StorageException(message: 'Failed to write $key', cause: e);
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, st) {
      AppLogger.error('SecureStorage read failed for key=$key', error: e, stackTrace: st);
      throw StorageException(message: 'Failed to read $key', cause: e);
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e, st) {
      AppLogger.error('SecureStorage delete failed for key=$key', error: e, stackTrace: st);
      throw StorageException(message: 'Failed to delete $key', cause: e);
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e, st) {
      AppLogger.error('SecureStorage deleteAll failed', error: e, stackTrace: st);
      throw StorageException(message: 'Failed to clear secure storage', cause: e);
    }
  }

  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key: key);
  }
}

@Riverpod(keepAlive: true)
SecureStorageService secureStorageService(SecureStorageServiceRef ref) {
  const storage = FlutterSecureStorage(
    // unlocked_this_device: only accessible while device is actively unlocked.
    // Stronger than first_unlock_this_device — prevents background reads on
    // jailbroken devices that bypass the lock screen.
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device),
    // migrateOnAlgorithmChange replaces the deprecated encryptedSharedPreferences
    // flag (flutter_secure_storage v10). Automatically migrates existing data when
    // Android changes the underlying encryption algorithm.
    aOptions: AndroidOptions(migrateOnAlgorithmChange: true),
  );
  return SecureStorageService(storage);
}
