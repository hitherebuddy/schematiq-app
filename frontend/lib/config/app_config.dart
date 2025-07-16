import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConfig {
  static const String appName = 'SchematIQ';
  static const String apiBaseUrl = 'https://schematiq-backend.onrender.com/api'; // Use 10.0.2.2 for Android emulator
  // Mock token for development. In a real app, this would be stored securely after login.
  static String? userToken;
}

class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color primary = Color(0xFF64B5F6); // Soft Blue
  static const Color accent = Color(0xFFE53935); // Red for Power Mode
  static const Color text = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFBDBDBD);
  static const Color cardBackground = Color(0xFF1A1A1A);
}

class AppTheme {
  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.primary,
      background: AppColors.background,
      surface: AppColors.cardBackground,
      onPrimary: AppColors.background,
      onSecondary: AppColors.text,
      onBackground: AppColors.text,
      onSurface: AppColors.text,
      error: AppColors.accent,
      onError: AppColors.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5))),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}