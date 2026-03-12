// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/message_model.dart';

/// IntelCrypt Theme Configuration — Stitch-inspired cyberpunk dark design
class AppTheme {
  // ── Core Stitch Palette ──────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1E2A38); // Deep Security Blue
  static const Color electricCyan = Color(0xFF00F2FF); // Electric Cyan accent
  static const Color accentBlue = Color(0xFF3B82F6); // Secondary accent
  static const Color backgroundDark = Color(0xFF16191C); // Main dark bg
  static const Color backgroundDeep = Color(0xFF0A0C10); // Deepest background
  static const Color surfaceDark = Color(0xFF1A1D21); // Card / surface

  // Neutral text palette
  static const Color textPrimary = Color(0xFFF1F5F9); // slate-100
  static const Color textSecondary = Color(0xFF94A3B8); // slate-400
  static const Color textMuted = Color(0xFF64748B); // slate-500

  // Status colors
  static const Color successGreen = Color(0xFF10B981); // emerald-500
  static const Color errorRed = Color(0xFFEF4444); // red-500
  static const Color warningOrange = Color(0xFFF59E0B); // amber-500

  // Encryption indicator colors
  static const Color encryptedHigh = Color(0xFF10B981);
  static const Color encryptedMedium = Color(0xFFF59E0B);
  static const Color encryptedLow = Color(0xFFEF4444);
  static const Color unencrypted = Color(0xFF6B7280);

  // ── Shared Text Theme (Space Grotesk) ────────────────────────────────────
  static TextTheme _buildTextTheme(Color onSurface, Color muted) {
    return GoogleFonts.spaceGroteskTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -0.5),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -0.5),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -0.3),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: onSurface),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: muted),
        bodyLarge: TextStyle(fontSize: 16, color: onSurface),
        bodyMedium: TextStyle(fontSize: 14, color: onSurface),
        bodySmall: TextStyle(fontSize: 12, color: muted),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: 0.5),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: muted, letterSpacing: 1.2),
      ),
    );
  }

  /// Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      onPrimary: Colors.white,
      secondary: electricCyan,
      onSecondary: Color(0xFF0A0C10),
      tertiary: accentBlue,
      onTertiary: Colors.white,
      error: errorRed,
      onError: Colors.white,
      surface: Color(0xFFF6F7F7),
      onSurface: Color(0xFF1F1F1F),
      outline: Color(0xFFCACECF),
    ),
    scaffoldBackgroundColor: const Color(0xFFF6F7F7),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: primaryBlue.withOpacity(0.1)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF6F7F7).withOpacity(0.8),
      foregroundColor: const Color(0xFF1F1F1F),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        color: const Color(0xFF1F1F1F),
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: primaryBlue.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: electricCyan, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: Color(0xFF999999)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: electricCyan,
        textStyle: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: BorderSide(color: primaryBlue.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: primaryBlue.withOpacity(0.1),
      thickness: 0.5,
      space: 0,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
    ),
    textTheme: _buildTextTheme(const Color(0xFF1F1F1F), const Color(0xFF666666)),
  );

  /// Dark Theme — primary Stitch theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      onPrimary: Colors.white,
      secondary: electricCyan,
      onSecondary: Color(0xFF0A0C10),
      tertiary: accentBlue,
      onTertiary: Colors.white,
      error: errorRed,
      onError: Colors.white,
      surface: surfaceDark,
      onSurface: textPrimary,
      outline: Color(0xFF2E3033),
      outlineVariant: Color(0xFF3F444B),
      inverseSurface: Color(0xFFC9D1D9),
      onInverseSurface: Color(0xFF0D1117),
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardTheme: CardThemeData(
      color: primaryBlue.withOpacity(0.2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: primaryBlue.withOpacity(0.3)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundDark.withOpacity(0.8),
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: primaryBlue.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue.withOpacity(0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: electricCyan.withOpacity(0.5), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: electricCyan,
        foregroundColor: backgroundDeep,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: electricCyan,
        textStyle: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: BorderSide(color: primaryBlue.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: primaryBlue.withOpacity(0.3),
      thickness: 0.5,
      space: 0,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: primaryBlue.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
    ),
    textTheme: _buildTextTheme(textPrimary, textSecondary),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: electricCyan,
      foregroundColor: backgroundDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: backgroundDark,
      selectedItemColor: electricCyan,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );

  // Encryption status colors
  static const Map<String, Color> encryptionColors = {
    'HIGH': encryptedHigh,
    'MEDIUM': encryptedMedium,
    'LOW': encryptedLow,
    'NONE': unencrypted,
  };

  static Color getEncryptionColor(String level) {
    return encryptionColors[level] ?? unencrypted;
  }

  // Status colors
  static const Color deliveredColor = successGreen;
  static const Color readColor = accentBlue;
  static const Color sendingColor = electricCyan;
  static const Color failedColor = errorRed;

  static Color getStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return successGreen;
      case MessageStatus.delivered:
        return deliveredColor;
      case MessageStatus.read:
        return readColor;
      case MessageStatus.failed:
        return failedColor;
      case MessageStatus.sending:
        return sendingColor;
      case MessageStatus.archived:
        return const Color(0xFF6B7280);
    }
  }
}

