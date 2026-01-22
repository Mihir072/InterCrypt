// ignore_for_file: unused_field

import 'package:flutter/material.dart';

/// IntelCrypt Theme Configuration
class AppTheme {
  // Color palette - Security & Trust focused
  static const Color _primaryColor = Color(
    0xFF1565C0,
  ); // Deep Blue - Trust & Security
  static const Color _secondaryColor = Color(0xFF00BCD4); // Cyan - Innovation
  static const Color _tertiaryColor = Color(0xFF7C4DFF); // Purple - Privacy

  static const Color _errorColor = Color(0xFFE53935); // Red - Critical alerts
  static const Color _warningColor = Color(0xFFFFA726); // Orange - Warnings
  static const Color _successColor = Color(0xFF43A047); // Green - Success
  static const Color _infoColor = Color(0xFF29B6F6); // Light Blue - Information

  // Neutral colors
  static const Color _darkBackground = Color(0xFF0D1117); // Very dark gray
  static const Color _darkSurface = Color(0xFF161B22); // Dark surface
  static const Color _darkOnSurface = Color(0xFFC9D1D9); // Light text on dark

  static const Color _lightBackground = Color(0xFFFFFBFE); // Off-white
  static const Color _lightSurface = Color(0xFFFEF7FF); // Light surface
  static const Color _lightOnSurface = Color(0xFF1F1F1F); // Dark text on light

  // Encryption indicators
  static const Color _encryptedHigh = Color(
    0xFF43A047,
  ); // Green - High encryption
  static const Color _encryptedMedium = Color(
    0xFFFFA726,
  ); // Orange - Medium encryption
  static const Color _encryptedLow = Color(0xFFE53935); // Red - Low encryption
  static const Color _unencrypted = Color(0xFF9E9E9E); // Gray - No encryption

  /// Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      onPrimary: Colors.white,
      secondary: _secondaryColor,
      onSecondary: Colors.white,
      tertiary: _tertiaryColor,
      onTertiary: Colors.white,
      error: _errorColor,
      onError: Colors.white,
      background: _lightBackground,
      onBackground: _lightOnSurface,
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      outline: Color(0xFFCACECF),
      outlineVariant: Color(0xFFFDDC4D),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF313133),
      onInverseSurface: Color(0xFFF4EFF4),
    ),
    scaffoldBackgroundColor: _lightBackground,
    cardTheme: CardThemeData(
      color: _lightSurface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _lightSurface,
      foregroundColor: _lightOnSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: _lightOnSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: Color(0xFF999999)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 0.5,
      space: 0,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: _lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      titleTextStyle: const TextStyle(
        color: _lightOnSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(color: Color(0xFF666666), fontSize: 14),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _lightOnSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _lightOnSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _lightOnSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _lightOnSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _lightOnSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _lightOnSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _lightOnSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF666666),
      ),
      bodyLarge: TextStyle(fontSize: 16, color: _lightOnSurface),
      bodyMedium: TextStyle(fontSize: 14, color: _lightOnSurface),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF666666)),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _lightOnSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF999999),
      ),
    ),
  );

  /// Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      onPrimary: Colors.white,
      secondary: _secondaryColor,
      onSecondary: Color(0xFF000000),
      tertiary: _tertiaryColor,
      onTertiary: Color(0xFF000000),
      error: _errorColor,
      onError: Color(0xFF000000),
      background: _darkBackground,
      onBackground: _darkOnSurface,
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      outline: Color(0xFF444C56),
      outlineVariant: Color(0xFF3F444B),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFC9D1D9),
      onInverseSurface: Color(0xFF0D1117),
    ),
    scaffoldBackgroundColor: _darkBackground,
    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkSurface,
      foregroundColor: _darkOnSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: _darkOnSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF21262D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF30363D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: Color(0xFF6E7681)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF30363D),
      thickness: 0.5,
      space: 0,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: _darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      titleTextStyle: const TextStyle(
        color: _darkOnSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(color: Color(0xFFA0A9B0), fontSize: 14),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _darkOnSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _darkOnSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _darkOnSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _darkOnSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _darkOnSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _darkOnSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _darkOnSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFFA0A9B0),
      ),
      bodyLarge: TextStyle(fontSize: 16, color: _darkOnSurface),
      bodyMedium: TextStyle(fontSize: 14, color: _darkOnSurface),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFFA0A9B0)),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _darkOnSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6E7681),
      ),
    ),
  );

  // Encryption status colors
  static const Map<String, Color> encryptionColors = {
    'HIGH': _encryptedHigh,
    'MEDIUM': _encryptedMedium,
    'LOW': _encryptedLow,
    'NONE': _unencrypted,
  };

  // Get encryption color
  static Color getEncryptionColor(String level) {
    return encryptionColors[level] ?? _unencrypted;
  }

  // Status colors
  static const Color deliveredColor = _successColor;
  static const Color readColor = _primaryColor;
  static const Color sendingColor = _infoColor;
  static const Color failedColor = _errorColor;

  // Get message status color
  static Color getStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return _successColor;
      case MessageStatus.delivered:
        return deliveredColor;
      case MessageStatus.read:
        return readColor;
      case MessageStatus.failed:
        return failedColor;
      case MessageStatus.sending:
        return sendingColor;
      case MessageStatus.archived:
        return Color(0xFF9E9E9E);
    }
  }
}

// Import for type checking
enum MessageStatus { sending, sent, delivered, read, failed, archived }
