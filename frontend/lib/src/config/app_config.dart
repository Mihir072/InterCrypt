/// Application configuration constants
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  /// API Configuration
  static const String apiBaseUrl = 'http://172.25.133.205:8443/api';

  /// API Timeout settings (in seconds)
  static const int connectionTimeout = 60;
  static const int receiveTimeout = 60;

  /// Token Configuration
  static const int tokenRefreshThresholdMinutes = 5;

  /// App Information
  static const String appName = 'IntelCrypt';
  static const String appVersion = '1.0.0';

  /// Feature Flags
  static const bool enableMfa = true;
  static const bool enableBiometrics = true;
  static const bool enableSelfDestructMessages = true;
}
