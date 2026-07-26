import 'package:flutter/material.dart';

/// Apple HIG-aligned design tokens for WallKraft.
///
/// All colors are defined as static consts for backward compatibility
/// (existing widgets use `AppTheme.systemBackground` directly).
/// Light-mode variants are prefixed with `light` so files that want
/// to support both modes can call [resolve].
class AppTheme {
  AppTheme._();

  // ── Default (Dark Mode) Colors ───────────────────────────────────
  // These are the original const values — every file in the codebase
  // references them. They match the dark palette.
  static const Color background = Color(0xFF0F0F0F);
  static const Color systemBackground = Color(0xFF1C1C1E);
  static const Color secondarySystemBackground = Color(0xFF2C2C2E);
  static const Color tertiarySystemBackground = Color(0xFF3A3A3C);
  static const Color label = Color(0xFFFFFFFF);
  static const Color secondaryLabel = Color(0x99EBEBF5);
  static const Color tertiaryLabel = Color(0x4DEBEBF5);
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color separator = Color(0xFF38383A);
  static const Color tilePlaceholder = Color(0xFF2C2C2E);
  static const Color favoriteRed = Color(0xFFFF3B30);

  // ── Light Mode Variants ─────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSystemBackground = Color(0xFFFFFFFF);
  static const Color lightSecondaryBackground = Color(0xFFF2F2F7);
  static const Color lightTertiaryBackground = Color(0xFFE5E5EA);
  static const Color lightLabel = Color(0xFF000000);
  static const Color lightSecondaryLabel = Color(0x993C3C43);
  static const Color lightTertiaryLabel = Color(0x4D3C3C43);
  static const Color lightSeparator = Color(0xFFC6C6C8);
  static const Color lightTilePlaceholder = Color(0xFFE5E5EA);

  /// Resolve the correct color for the current [brightness].
  /// Returns [dark] in dark mode, [light] in light mode.
  static Color resolve(Brightness brightness, Color dark, Color light) {
    return brightness == Brightness.dark ? dark : light;
  }

  /// Convenience — resolves from a [BuildContext].
  static Color of(BuildContext context, Color dark, Color light) {
    return resolve(Theme.of(context).brightness, dark, light);
  }

  // ── Spacing (8pt grid) ────────────────────────────────────────────
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing44 = 44;

  // ── Typography ────────────────────────────────────────────────────
  static const String _fontFamily = 'sans-serif';

  static const TextStyle largeTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w400,
    color: Color(0xFFFFFFFF),
    letterSpacing: 0.37,
  );

  static const TextStyle title1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    color: Color(0xFFFFFFFF),
    letterSpacing: 0.36,
  );

  static const TextStyle title2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: Color(0xFFFFFFFF),
    letterSpacing: 0.35,
  );

  static const TextStyle title3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: Color(0xFFFFFFFF),
    letterSpacing: 0.34,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Color(0xFFFFFFFF),
    letterSpacing: -0.41,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: Color(0xFFFFFFFF),
    letterSpacing: -0.41,
  );

  static const TextStyle callout = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xFFFFFFFF),
    letterSpacing: -0.32,
  );

  static const TextStyle subhead = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0x99EBEBF5),
    letterSpacing: -0.24,
  );

  static const TextStyle footnote = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0x99EBEBF5),
    letterSpacing: -0.08,
  );

  static const TextStyle caption1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0x99EBEBF5),
    letterSpacing: 0,
  );

  static const TextStyle caption2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Color(0x4DEBEBF5),
    letterSpacing: 0.07,
  );

  /// Builds the full [ThemeData] for a given brightness.
  static ThemeData themeFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? background : lightBackground,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: systemBlue,
              surface: systemBackground,
              onSurface: label,
              secondary: secondarySystemBackground,
              outline: separator,
            )
          : const ColorScheme.light(
              primary: systemBlue,
              surface: lightSystemBackground,
              onSurface: lightLabel,
              secondary: lightSecondaryBackground,
              outline: lightSeparator,
            ),
      useMaterial3: true,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? systemBackground : lightSystemBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: isDark ? label : lightLabel,
          letterSpacing: -0.41,
        ),
        iconTheme: const IconThemeData(color: systemBlue, size: 22),
        actionsIconTheme: const IconThemeData(color: systemBlue, size: 22),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? systemBackground : lightSystemBackground,
        selectedItemColor: systemBlue,
        unselectedItemColor: isDark ? secondaryLabel : lightSecondaryLabel,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
      ),

      // Text
      textTheme: TextTheme(
        headlineLarge: largeTitle.copyWith(color: isDark ? label : lightLabel),
        headlineMedium: title1.copyWith(color: isDark ? label : lightLabel),
        headlineSmall: title2.copyWith(color: isDark ? label : lightLabel),
        titleLarge: title3.copyWith(color: isDark ? label : lightLabel),
        titleMedium: headline.copyWith(color: isDark ? label : lightLabel),
        bodyLarge: body.copyWith(color: isDark ? label : lightLabel),
        bodyMedium: callout.copyWith(color: isDark ? label : lightLabel),
        bodySmall: subhead.copyWith(
            color: isDark ? secondaryLabel : lightSecondaryLabel),
        labelLarge: footnote.copyWith(
            color: isDark ? secondaryLabel : lightSecondaryLabel),
        labelMedium: caption1.copyWith(
            color: isDark ? secondaryLabel : lightSecondaryLabel),
        labelSmall: caption2.copyWith(
            color: isDark ? tertiaryLabel : lightTertiaryLabel),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? systemBackground : lightSystemBackground,
        contentTextStyle: body.copyWith(
            color: isDark ? label : lightLabel),
        actionTextColor: systemBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // Divider
      dividerColor: isDark ? separator : lightSeparator,
      dividerTheme: DividerThemeData(
        color: isDark ? separator : lightSeparator,
        thickness: 1,
        space: 0,
      ),
    );
  }

  /// Convenience accessors for the two built-in themes.
  static ThemeData get darkTheme => themeFor(Brightness.dark);
  static ThemeData get lightTheme => themeFor(Brightness.light);
}
