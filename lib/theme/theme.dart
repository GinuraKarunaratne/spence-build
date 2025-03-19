import 'package:flutter/material.dart';

class AppColors {
  // Light mode colors (your current colors)
  static final Map<ThemeMode, Color> primaryBackground = {
    ThemeMode.light: const Color(0xFFF2F2F2),
    ThemeMode.dark: Colors.grey[900]!, // Placeholder for dark mode
  };

  static final Map<ThemeMode, Color> secondaryBackground = {
    ThemeMode.light: const Color(0xFFEBEBEB),
    ThemeMode.dark: Colors.grey[800]!, // Placeholder
  };

  static final Map<ThemeMode, Color> lightGrayBackground = {
    ThemeMode.light: const Color(0xFFE3E3E3),
    ThemeMode.dark: Colors.grey[700]!, // Placeholder
  };

  static final Map<ThemeMode, Color> accentColor = {
    ThemeMode.light: const Color(0xFFCCF20D),
    ThemeMode.dark: Colors.tealAccent, // Placeholder
  };

  static final Map<ThemeMode, Color> lightAccentColor = {
    ThemeMode.light: const Color(0x26CCF20D),
    ThemeMode.dark: Colors.tealAccent.withOpacity(0.2), // Placeholder
  };

  static final Map<ThemeMode, Color> customLightGray = {
    ThemeMode.light: const Color(0xFFE1E1E1),
    ThemeMode.dark: Colors.grey[600]!, // Placeholder
  };

  static final Map<ThemeMode, Color> textColor = {
    ThemeMode.light: Colors.black,
    ThemeMode.dark: Colors.white, // Adjusted for dark mode visibility
  };
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.lightGrayBackground[ThemeMode.light],
      scaffoldBackgroundColor: AppColors.primaryBackground[ThemeMode.light],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.lightGrayBackground[ThemeMode.dark],
      scaffoldBackgroundColor: AppColors.primaryBackground[ThemeMode.dark],
    );
  }
}