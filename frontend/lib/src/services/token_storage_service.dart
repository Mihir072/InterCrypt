import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing and retrieving authentication tokens
class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _tokenExpiryKey = 'token_expiry';

  final FlutterSecureStorage _storage;

  TokenStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Save tokens to secure storage
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    DateTime? expiresAt,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
        _storage.write(key: _userIdKey, value: userId),
        if (expiresAt != null)
          _storage.write(
            key: _tokenExpiryKey,
            value: expiresAt.toIso8601String(),
          ),
      ]);
    } catch (e) {
      throw TokenStorageException('Failed to save tokens: $e');
    }
  }

  /// Retrieve access token from secure storage
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      throw TokenStorageException('Failed to retrieve access token: $e');
    }
  }

  /// Retrieve refresh token from secure storage
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      throw TokenStorageException('Failed to retrieve refresh token: $e');
    }
  }

  /// Retrieve user ID from secure storage
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      throw TokenStorageException('Failed to retrieve user ID: $e');
    }
  }

  /// Retrieve token expiry time
  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiry = await _storage.read(key: _tokenExpiryKey);
      if (expiry == null) return null;
      return DateTime.parse(expiry);
    } catch (e) {
      throw TokenStorageException('Failed to retrieve token expiry: $e');
    }
  }

  /// Check if token exists and is still valid
  Future<bool> hasValidToken() async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;

      final expiry = await getTokenExpiry();
      if (expiry == null) return true; // No expiry info, assume valid

      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }

  /// Check if refresh token is available
  Future<bool> hasRefreshToken() async {
    try {
      final token = await getRefreshToken();
      return token != null;
    } catch (e) {
      return false;
    }
  }

  /// Clear all stored tokens
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _tokenExpiryKey),
      ]);
    } catch (e) {
      throw TokenStorageException('Failed to clear tokens: $e');
    }
  }

  /// Clear all data in secure storage
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw TokenStorageException('Failed to clear storage: $e');
    }
  }
}

/// Exception for token storage operations
class TokenStorageException implements Exception {
  final String message;

  TokenStorageException(this.message);

  @override
  String toString() => 'TokenStorageException: $message';
}
