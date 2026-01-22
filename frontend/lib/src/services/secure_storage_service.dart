import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Storage Service for sensitive data
class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _encryptionKeyPrefix = 'encryption_key_';
  static const _sessionIdKey = 'session_id';
  static const _deviceIdKey = 'device_id';

  late FlutterSecureStorage _storage;

  SecureStorageService() {
    // Configure with high security settings
    const options = AndroidOptions(
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    );
    _storage = FlutterSecureStorage(aOptions: options);
  }

  // ============== Token Management ==============

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
    } catch (e) {
      throw SecureStorageException('Failed to save access token: $e');
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      throw SecureStorageException('Failed to read access token: $e');
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      throw SecureStorageException('Failed to save refresh token: $e');
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      throw SecureStorageException('Failed to read refresh token: $e');
    }
  }

  /// Clear both tokens
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
      ]);
    } catch (e) {
      throw SecureStorageException('Failed to clear tokens: $e');
    }
  }

  // ============== User Management ==============

  /// Save current user ID
  Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
    } catch (e) {
      throw SecureStorageException('Failed to save user ID: $e');
    }
  }

  /// Get current user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      throw SecureStorageException('Failed to read user ID: $e');
    }
  }

  /// Save session ID
  Future<void> saveSessionId(String sessionId) async {
    try {
      await _storage.write(key: _sessionIdKey, value: sessionId);
    } catch (e) {
      throw SecureStorageException('Failed to save session ID: $e');
    }
  }

  /// Get session ID
  Future<String?> getSessionId() async {
    try {
      return await _storage.read(key: _sessionIdKey);
    } catch (e) {
      throw SecureStorageException('Failed to read session ID: $e');
    }
  }

  /// Save device ID
  Future<void> saveDeviceId(String deviceId) async {
    try {
      await _storage.write(key: _deviceIdKey, value: deviceId);
    } catch (e) {
      throw SecureStorageException('Failed to save device ID: $e');
    }
  }

  /// Get device ID
  Future<String?> getDeviceId() async {
    try {
      return await _storage.read(key: _deviceIdKey);
    } catch (e) {
      throw SecureStorageException('Failed to read device ID: $e');
    }
  }

  // ============== Biometric Settings ==============

  /// Save biometric enabled status
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
    } catch (e) {
      throw SecureStorageException('Failed to save biometric status: $e');
    }
  }

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      throw SecureStorageException('Failed to read biometric status: $e');
    }
  }

  // ============== Encryption Key Management ==============

  /// Save encryption key
  Future<void> saveEncryptionKey(String keyId, String key) async {
    try {
      await _storage.write(key: '$_encryptionKeyPrefix$keyId', value: key);
    } catch (e) {
      throw SecureStorageException('Failed to save encryption key: $e');
    }
  }

  /// Get encryption key
  Future<String?> getEncryptionKey(String keyId) async {
    try {
      return await _storage.read(key: '$_encryptionKeyPrefix$keyId');
    } catch (e) {
      throw SecureStorageException('Failed to read encryption key: $e');
    }
  }

  /// Delete encryption key
  Future<void> deleteEncryptionKey(String keyId) async {
    try {
      await _storage.delete(key: '$_encryptionKeyPrefix$keyId');
    } catch (e) {
      throw SecureStorageException('Failed to delete encryption key: $e');
    }
  }

  /// Get all encryption keys
  Future<Map<String, String>> getAllEncryptionKeys() async {
    try {
      final allKeys = await _storage.readAll();
      final encryptionKeys = <String, String>{};

      allKeys.forEach((key, value) {
        if (key.startsWith(_encryptionKeyPrefix)) {
          final keyId = key.replaceFirst(_encryptionKeyPrefix, '');
          encryptionKeys[keyId] = value;
        }
      });

      return encryptionKeys;
    } catch (e) {
      throw SecureStorageException('Failed to read encryption keys: $e');
    }
  }

  /// Clear all encryption keys
  Future<void> clearAllEncryptionKeys() async {
    try {
      final allKeys = await _storage.readAll();

      for (final key in allKeys.keys) {
        if (key.startsWith(_encryptionKeyPrefix)) {
          await _storage.delete(key: key);
        }
      }
    } catch (e) {
      throw SecureStorageException('Failed to clear encryption keys: $e');
    }
  }

  // ============== General Purpose ==============

  /// Save custom value
  Future<void> saveValue(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw SecureStorageException('Failed to save value: $e');
    }
  }

  /// Get custom value
  Future<String?> getValue(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to read value: $e');
    }
  }

  /// Delete custom value
  Future<void> deleteValue(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to delete value: $e');
    }
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException('Failed to clear all data: $e');
    }
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      throw SecureStorageException('Failed to check key existence: $e');
    }
  }
}

/// Exception thrown by SecureStorageService
class SecureStorageException implements Exception {
  final String message;

  SecureStorageException(this.message);

  @override
  String toString() => 'SecureStorageException: $message';
}
