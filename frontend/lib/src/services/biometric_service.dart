import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';
import 'secure_storage_service.dart';

/// Biometric Authentication Service
/// Handles fingerprint and face ID authentication
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage;
  final Logger _logger = Logger();

  BiometricService(this._secureStorage);

  /// Check if biometric authentication is available on device
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      _logger.w('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      _logger.w('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if biometric authentication is enabled in app settings
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.getValue('biometric_enabled');
      return enabled == 'true';
    } catch (e) {
      _logger.w('Error reading biometric setting: $e');
      return false;
    }
  }

  /// Enable biometric authentication
  Future<void> enableBiometric() async {
    try {
      await _secureStorage.saveValue('biometric_enabled', 'true');
    } catch (e) {
      _logger.e('Error enabling biometric: $e');
      rethrow;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      await _secureStorage.saveValue('biometric_enabled', 'false');
      await _secureStorage.deleteValue('biometric_credentials');
    } catch (e) {
      _logger.e('Error disabling biometric: $e');
      rethrow;
    }
  }

  /// Authenticate using biometrics
  /// Returns true if authentication successful
  Future<bool> authenticate({
    String reason = 'Please authenticate to access your account',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // Check if biometric is available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        _logger.w('Biometric authentication not available');
        return false;
      }

      // Perform authentication
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _logger.i('Biometric authentication successful');
      } else {
        _logger.w('Biometric authentication failed');
      }

      return authenticated;
    } on PlatformException catch (e) {
      _logger.e('Biometric authentication error: ${e.code} - ${e.message}');

      // Handle specific error codes
      switch (e.code) {
        case 'NotAvailable':
          throw BiometricException(
            'Biometric authentication is not available on this device',
          );
        case 'NotEnrolled':
          throw BiometricException(
            'No biometric credentials enrolled. Please set up fingerprint or face ID in device settings',
          );
        case 'LockedOut':
          throw BiometricException(
            'Too many failed attempts. Biometric authentication is temporarily locked',
          );
        case 'PermanentlyLockedOut':
          throw BiometricException(
            'Biometric authentication is permanently disabled. Please use password',
          );
        default:
          throw BiometricException(
            'Biometric authentication failed: ${e.message}',
          );
      }
    } catch (e) {
      _logger.e('Unexpected biometric error: $e');
      throw BiometricException('Unexpected error during authentication');
    }
  }

  /// Store credentials for biometric authentication
  /// This stores encrypted username for quick login
  Future<void> storeCredentialsForBiometric(String username) async {
    try {
      await _secureStorage.saveValue('biometric_username', username);
      _logger.i('Credentials stored for biometric authentication');
    } catch (e) {
      _logger.e('Error storing biometric credentials: $e');
      rethrow;
    }
  }

  /// Get stored credentials for biometric authentication
  Future<String?> getStoredUsername() async {
    try {
      return await _secureStorage.getValue('biometric_username');
    } catch (e) {
      _logger.w('Error reading stored username: $e');
      return null;
    }
  }

  /// Clear stored biometric credentials
  Future<void> clearStoredCredentials() async {
    try {
      await _secureStorage.deleteValue('biometric_username');
      await _secureStorage.deleteValue('biometric_enabled');
      _logger.i('Biometric credentials cleared');
    } catch (e) {
      _logger.e('Error clearing biometric credentials: $e');
      rethrow;
    }
  }

  /// Get biometric type display name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }

  /// Get primary biometric type available
  Future<BiometricType?> getPrimaryBiometricType() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.isEmpty) return null;

    // Priority order: face > fingerprint > iris > strong > weak
    if (biometrics.contains(BiometricType.face)) {
      return BiometricType.face;
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    } else if (biometrics.contains(BiometricType.iris)) {
      return BiometricType.iris;
    } else if (biometrics.contains(BiometricType.strong)) {
      return BiometricType.strong;
    } else if (biometrics.contains(BiometricType.weak)) {
      return BiometricType.weak;
    }

    return biometrics.first;
  }

  /// Get biometric icon based on type
  String getBiometricIcon(BiometricType? type) {
    if (type == null) return '🔐';

    switch (type) {
      case BiometricType.face:
        return '👤';
      case BiometricType.fingerprint:
        return '👆';
      case BiometricType.iris:
        return '👁️';
      default:
        return '🔐';
    }
  }

  /// Stop authentication (cancel ongoing authentication)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      _logger.i('Biometric authentication cancelled');
    } catch (e) {
      _logger.w('Error stopping authentication: $e');
    }
  }
}

/// Exception thrown by BiometricService
class BiometricException implements Exception {
  final String message;

  BiometricException(this.message);

  @override
  String toString() => 'BiometricException: $message';
}
