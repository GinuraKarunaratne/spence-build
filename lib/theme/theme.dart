import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static final Map<ThemeMode, Color> primaryBackground = {
    ThemeMode.light: const Color(0xFFF2F2F2),
    ThemeMode.dark: const Color.fromARGB(255, 21, 21, 21),
  };

  static final Map<ThemeMode, Color> secondaryBackground = {
    ThemeMode.light: const Color(0xFFEBEBEB),
    ThemeMode.dark: const Color.fromARGB(255, 35, 35, 35),
  };

  static final Map<ThemeMode, Color> lightGrayBackground = {
    ThemeMode.light: const Color(0xFFE3E3E3),
    ThemeMode.dark: Colors.grey[700]!,
  };

  static final Map<ThemeMode, Color> accentColor = {
    ThemeMode.light: const Color(0xFFCCF20D),
    ThemeMode.dark: const Color(0xFF2B2B2B),
  };

  static final Map<ThemeMode, Color> customLightGray = {
    ThemeMode.light: const Color(0xFFE1E1E1),
    ThemeMode.dark: Colors.grey[600]!,
  };

  static final Map<ThemeMode, Color> textColor = {
    ThemeMode.light: Colors.black,
    ThemeMode.dark: const Color.fromARGB(255, 255, 255, 255),
  };

  static final Map<ThemeMode, Color> alttextColor = {
    ThemeMode.light: Colors.black,
    ThemeMode.dark: const Color(0xFF1C1B1F),
  };

    static final Map<ThemeMode, Color> budgettextColor = {
    ThemeMode.light: Colors.black,
    ThemeMode.dark: const Color.fromARGB(255, 255, 255, 255),
  };

  static final Map<ThemeMode, Color> transparentColor = {
    ThemeMode.light: Colors.transparent,
    ThemeMode.dark: Colors.transparent,
  };

  static final Map<ThemeMode, Color> iconColor = {
    ThemeMode.light: const Color(0xFF1C1B1F),
    ThemeMode.dark: Colors.white70,
  };

  static final Map<ThemeMode, Color> spinnerColor = {
    ThemeMode.light: Colors.white,
    ThemeMode.dark: Colors.grey[800]!,
  };

  static final Map<ThemeMode, Color> disabledIconColor = {
    ThemeMode.light: const Color.fromARGB(80, 149, 149, 149),
    ThemeMode.dark: Colors.grey[500]!.withOpacity(0.5),
  };

  static final Map<ThemeMode, Color> secondaryTextColor = {
    ThemeMode.light: const Color(0xFF272727),
    ThemeMode.dark: Colors.grey[300]!,
  };

  static final Map<ThemeMode, Color> disabledTextColor = {
    ThemeMode.light: const Color.fromARGB(80, 0, 0, 0),
    ThemeMode.dark: Colors.grey[500]!.withOpacity(0.5),
  };

  static final Map<ThemeMode, Color> whiteColor = {
    ThemeMode.light: Colors.white,
    ThemeMode.dark: Colors.grey[800]!,
  };

  static final Map<ThemeMode, Color> overlayColor = {
    ThemeMode.light: Colors.black.withOpacity(0.5),
    ThemeMode.dark: Colors.black.withOpacity(0.3),
  };

  static final Map<ThemeMode, Color> lightBackground = {
    ThemeMode.light: const Color(0xFFF5F5F5),
    ThemeMode.dark: Colors.grey[700]!,
  };

  static final Map<ThemeMode, Color> notificationTextColor = {
    ThemeMode.light: const Color(0xFF7F7F7F),
    ThemeMode.dark: Colors.grey[400]!,
  };

  static final Map<ThemeMode, Color> budgetShadowColor = {
    ThemeMode.light: const Color.fromARGB(255, 209, 209, 209),
    ThemeMode.dark: Colors.black54,
  };

  static final Map<ThemeMode, Color> budgetLabelBackground = {
    ThemeMode.light: const Color(0xFFCCF20D).withOpacity(0.15),
    ThemeMode.dark: const Color(0xFFCCF402),
  };

  static final Map<ThemeMode, Color> barColor = {
    ThemeMode.light: const Color(0xFFCCF20D),
    ThemeMode.dark: const Color(0xFFCCF402),
  };

  static final Map<ThemeMode, Color> budgetNoteColor = {
    ThemeMode.light: Colors.black38,
    ThemeMode.dark: const Color.fromARGB(168, 255, 255, 255),
  };

  static final Map<ThemeMode, Color> errorColor = {
    ThemeMode.light: Colors.red,
    ThemeMode.dark: Colors.redAccent,
  };

  static final Map<ThemeMode, Color> categoryButtonBackground = {
    ThemeMode.light: const Color(0xFFE6E6E6),
    ThemeMode.dark: Colors.grey[600]!,
  };

  static final Map<ThemeMode, Color> logoutButtonBackground = {
    ThemeMode.light: const Color(0xFFEC0004),
    ThemeMode.dark: const Color(0xFFA10000),
  };

  static final Map<ThemeMode, Color> logoutButtonTextColor = {
    ThemeMode.light: const Color(0xFFF9F9F9),
    ThemeMode.dark: Colors.white,
  };

  static final Map<ThemeMode, Color> logoutIcon = {
    ThemeMode.light: const Color(0xFFF9F9F9),
    ThemeMode.dark: Colors.white,
  };

  static final Map<ThemeMode, Color> logoutDialogContentColor = {
    ThemeMode.light: Colors.black87,
    ThemeMode.dark: const Color(0xFF979797),
  };

  static final Map<ThemeMode, Color> logoutDialogCancelColor = {
    ThemeMode.light: Colors.grey[600]!,
    ThemeMode.dark: Colors.grey[400]!,
  };

  static final Map<ThemeMode, Color> navBarShadowColor = {
    ThemeMode.light: const Color.fromARGB(255, 255, 255, 255),
    ThemeMode.dark: Colors.black54,
  };

  static final Map<ThemeMode, Color> navBarUnselectedColor = {
    ThemeMode.light: Colors.grey,
    ThemeMode.dark: Colors.grey[400]!,
  };

  static final Map<String, Color> categoryPieColors = {
    'Food & Grocery': const Color(0xFF2AE123),
    'Transportation': const Color(0xFF2A00FF),
    'Entertainment': const Color(0xFFFFD400),
    'Recurring Payments': const Color(0xFF9747FF),
    'Shopping': const Color(0xFFFF5900),
    'Other Expenses': const Color(0xFFFF00AA),
  };

  static final Map<ThemeMode, Color> barGradientEnd = {
    ThemeMode.light: const Color(0xFFBBE000),
    ThemeMode.dark: const Color(0xFFB6DA00  ),
  };

  // New color for non-current month bars
  static final Map<ThemeMode, Color> monthlyBarColor = {
    ThemeMode.light: const Color(0xFFF5FCCF),
    ThemeMode.dark: const Color(0xFF4B4B4B), // Placeholder for dark mode
  };

  static final Map<ThemeMode, Color> navtextColor = {
    ThemeMode.light: Colors.black,
    ThemeMode.dark: const Color.fromARGB(255, 255, 255, 255), // Placeholder for dark mode
  };

  static final Map<ThemeMode, Color> navBg = {
    ThemeMode.light: Colors.transparent,
    ThemeMode.dark: const Color.fromARGB(255, 0, 0, 0), // Placeholder for dark mode
  };
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.lightGrayBackground[ThemeMode.light],
      scaffoldBackgroundColor: AppColors.primaryBackground[ThemeMode.light],
      textTheme: GoogleFonts.poppinsTextTheme(),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.lightGrayBackground[ThemeMode.dark],
      scaffoldBackgroundColor: AppColors.primaryBackground[ThemeMode.dark],
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AppColors.textColor[ThemeMode.dark],
        displayColor: AppColors.textColor[ThemeMode.dark],
      ),
    );
  }
}