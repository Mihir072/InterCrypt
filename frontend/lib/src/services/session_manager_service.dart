import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'secure_storage_service.dart';

/// Session Manager Service
/// Handles automatic session timeout and app locking for security
class SessionManagerService {
  final SecureStorageService _secureStorage;
  final Logger _logger = Logger();

  // Session timeout duration (default: 5 minutes)
  Duration _sessionTimeout = const Duration(minutes: 5);

  // Timer for session timeout
  Timer? _sessionTimer;

  // Last activity timestamp
  DateTime? _lastActivity;

  // Session lock callback
  VoidCallback? _onSessionExpired;

  // Is session currently locked
  bool _isLocked = false;

  // Session timeout enabled
  bool _isEnabled = true;

  SessionManagerService(this._secureStorage) {
    _loadSettings();
  }

  /// Load session manager settings
  Future<void> _loadSettings() async {
    try {
      // Load timeout duration
      final timeoutMinutes = await _secureStorage.getValue(
        'session_timeout_minutes',
      );
      if (timeoutMinutes != null) {
        _sessionTimeout = Duration(minutes: int.parse(timeoutMinutes));
      }

      // Load enabled status
      final enabled = await _secureStorage.getValue('session_timeout_enabled');
      _isEnabled = enabled != 'false'; // Default to true
    } catch (e) {
      _logger.w('Error loading session settings: $e');
    }
  }

  /// Initialize session manager
  void initialize({required VoidCallback onSessionExpired}) {
    _onSessionExpired = onSessionExpired;
    _lastActivity = DateTime.now();
    _startSessionTimer();
    _logger.i('Session manager initialized');
  }

  /// Record user activity
  void recordActivity() {
    if (!_isEnabled || _isLocked) return;

    _lastActivity = DateTime.now();
    _resetSessionTimer();
  }

  /// Start session timeout timer
  void _startSessionTimer() {
    if (!_isEnabled) return;

    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, _handleSessionTimeout);
    _logger.d('Session timer started: ${_sessionTimeout.inMinutes} minutes');
  }

  /// Reset session timer
  void _resetSessionTimer() {
    if (!_isEnabled) return;

    _sessionTimer?.cancel();
    _startSessionTimer();
  }

  /// Handle session timeout
  void _handleSessionTimeout() {
    _logger.w('Session timeout reached');
    _isLocked = true;
    _onSessionExpired?.call();
  }

  /// Lock session manually
  void lockSession() {
    _logger.i('Session locked manually');
    _isLocked = true;
    _sessionTimer?.cancel();
    _onSessionExpired?.call();
  }

  /// Unlock session
  void unlockSession() {
    _logger.i('Session unlocked');
    _isLocked = false;
    _lastActivity = DateTime.now();
    _startSessionTimer();
  }

  /// Check if session is locked
  bool get isLocked => _isLocked;

  /// Check if session timeout is enabled
  bool get isEnabled => _isEnabled;

  /// Get current timeout duration
  Duration get sessionTimeout => _sessionTimeout;

  /// Get time until session expires
  Duration? getTimeUntilExpiry() {
    if (_lastActivity == null || !_isEnabled || _isLocked) return null;

    final expiryTime = _lastActivity!.add(_sessionTimeout);
    final remaining = expiryTime.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Set session timeout duration
  Future<void> setSessionTimeout(Duration duration) async {
    try {
      _sessionTimeout = duration;
      await _secureStorage.saveValue(
        'session_timeout_minutes',
        duration.inMinutes.toString(),
      );
      _resetSessionTimer();
      _logger.i('Session timeout set to ${duration.inMinutes} minutes');
    } catch (e) {
      _logger.e('Error setting session timeout: $e');
      rethrow;
    }
  }

  /// Enable session timeout
  Future<void> enable() async {
    try {
      _isEnabled = true;
      await _secureStorage.saveValue('session_timeout_enabled', 'true');
      _startSessionTimer();
      _logger.i('Session timeout enabled');
    } catch (e) {
      _logger.e('Error enabling session timeout: $e');
      rethrow;
    }
  }

  /// Disable session timeout
  Future<void> disable() async {
    try {
      _isEnabled = false;
      await _secureStorage.saveValue('session_timeout_enabled', 'false');
      _sessionTimer?.cancel();
      _logger.i('Session timeout disabled');
    } catch (e) {
      _logger.e('Error disabling session timeout: $e');
      rethrow;
    }
  }

  /// Get available timeout durations
  static List<Duration> get availableTimeouts => [
    const Duration(minutes: 1),
    const Duration(minutes: 2),
    const Duration(minutes: 5),
    const Duration(minutes: 10),
    const Duration(minutes: 15),
    const Duration(minutes: 30),
    const Duration(hours: 1),
  ];

  /// Get timeout duration display name
  static String getTimeoutDisplayName(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    } else {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    }
  }

  /// Pause session timer (e.g., when app goes to background)
  void pauseTimer() {
    _sessionTimer?.cancel();
    _logger.d('Session timer paused');
  }

  /// Resume session timer (e.g., when app comes to foreground)
  void resumeTimer() {
    if (!_isEnabled || _isLocked) return;

    // Check if session expired while paused
    if (_lastActivity != null) {
      final timeSinceActivity = DateTime.now().difference(_lastActivity!);
      if (timeSinceActivity >= _sessionTimeout) {
        _handleSessionTimeout();
        return;
      }

      // Resume with remaining time
      final remainingTime = _sessionTimeout - timeSinceActivity;
      _sessionTimer?.cancel();
      _sessionTimer = Timer(remainingTime, _handleSessionTimeout);
      _logger.d(
        'Session timer resumed: ${remainingTime.inMinutes} minutes remaining',
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _sessionTimer?.cancel();
    _logger.i('Session manager disposed');
  }
}

/// Exception thrown by SessionManagerService
class SessionManagerException implements Exception {
  final String message;

  SessionManagerException(this.message);

  @override
  String toString() => 'SessionManagerException: $message';
}
