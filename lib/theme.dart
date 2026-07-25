import 'package:flutter/material.dart';

/// Apple HIG-aligned design tokens for WallKraft.
///
/// All colors, typography, and spacing values are sourced from
/// Apple's Human Interface Guidelines (Dark Mode defaults).
class AppTheme {
  AppTheme._();

  // ── Colors ────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0F0F0F);
  static const Color systemBackground = Color(0xFF1C1C1E);
  static const Color secondarySystemBackground = Color(0xFF2C2C2E);
  static const Color tertiarySystemBackground = Color(0xFF3A3A3C);
  static const Color label = Color(0xFFFFFFFF);
  static const Color secondaryLabel = Color(0x99EBEBF5); // 60%
  static const Color tertiaryLabel = Color(0x4DEBEBF5); // 30%
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color separator = Color(0xFF38383A);
  static const Color tilePlaceholder = Color(0xFF2C2C2E);
  static const Color favoriteRed = Color(0xFFFF3B30);

  // ── Spacing (8pt grid) ────────────────────────────────────────────
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing44 = 44; // Minimum touch target

  // ── Typography ────────────────────────────────────────────────────
  static const String _fontFamily = '.SF Pro Display';

  static const TextStyle largeTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w400,
    color: label,
    letterSpacing: 0.37,
  );

  static const TextStyle title1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    color: label,
    letterSpacing: 0.36,
  );

  static const TextStyle title2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: label,
    letterSpacing: 0.35,
  );

  static const TextStyle title3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: label,
    letterSpacing: 0.34,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: label,
    letterSpacing: -0.41,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: label,
    letterSpacing: -0.41,
  );

  static const TextStyle callout = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: label,
    letterSpacing: -0.32,
  );

  static const TextStyle subhead = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: secondaryLabel,
    letterSpacing: -0.24,
  );

  static const TextStyle footnote = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: secondaryLabel,
    letterSpacing: -0.08,
  );

  static const TextStyle caption1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: secondaryLabel,
    letterSpacing: 0,
  );

  static const TextStyle caption2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: tertiaryLabel,
    letterSpacing: 0.07,
  );

  // ── App ThemeData ─────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.dark(
          primary: systemBlue,
          surface: systemBackground,
          onSurface: label,
          secondary: secondarySystemBackground,
          outline: separator,
        ),
        useMaterial3: true,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: largeTitle,
          toolbarTextStyle: body,
        ),

        // Tab bar
        tabBarTheme: const TabBarThemeData(
          labelColor: label,
          unselectedLabelColor: secondaryLabel,
          indicatorColor: systemBlue,
        ),

        // Bottom navigation
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: systemBackground,
          selectedItemColor: systemBlue,
          unselectedItemColor: secondaryLabel,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),

        // Text
        textTheme: const TextTheme(
          headlineLarge: largeTitle,
          headlineMedium: title1,
          headlineSmall: title2,
          titleLarge: title3,
          titleMedium: headline,
          bodyLarge: body,
          bodyMedium: callout,
          bodySmall: subhead,
          labelLarge: footnote,
          labelMedium: caption1,
          labelSmall: caption2,
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: systemBackground,
          contentTextStyle: body.copyWith(color: label),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        // Divider
        dividerColor: separator,
        dividerTheme: const DividerThemeData(
          color: separator,
          thickness: 1,
          space: 0,
        ),
      );
}
