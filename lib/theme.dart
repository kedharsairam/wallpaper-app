import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Apple HIG-aligned design tokens for WallKraft.
///
/// Built on top of the shared Kraft design system with
/// wallpaper-specific overrides.
class AppTheme {
  AppTheme._();

  // ── Core Colors (from shared) ────────────────────────────────────
  // These are references to the universal Kraft palette.
  // New apps should use KraftColors directly; WallKraft keeps these
  // static consts for backward compatibility.
  static const Color background = KraftColors.backgroundDark;
  static const Color systemBackground = KraftColors.surfaceDark;
  static const Color secondarySystemBackground = KraftColors.surfaceSecondaryDark;
  static const Color tertiarySystemBackground = KraftColors.surfaceTertiaryDark;
  static const Color label = KraftColors.textPrimaryDark;
  // Secondary/tertiary use Apple-standard alpha (60%/30%) — referenced
  // heavily (44+ sites) across the codebase. Keep alpha values intact.
  static const Color secondaryLabel = Color(0x99EBEBF5);
  static const Color tertiaryLabel = Color(0x4DEBEBF5);
  static const Color lightSecondaryLabel = Color(0x993C3C43);
  static const Color lightTertiaryLabel = Color(0x4D3C3C43);

  static const Color systemBlue = KraftColors.accentBlue;
  static const Color separator = KraftColors.separatorDark;

  // ── Light Mode Variants (from shared) ─────────────────────────────
  static const Color lightBackground = KraftColors.backgroundLight;
  static const Color lightSystemBackground = KraftColors.surfaceLight;
  static const Color lightSecondaryBackground = KraftColors.surfaceSecondaryLight;
  static const Color lightTertiaryBackground = KraftColors.surfaceTertiaryLight;
  static const Color lightLabel = KraftColors.textPrimaryLight;
  static const Color lightSeparator = KraftColors.separatorLight;

  // ── WallKraft-Specific Colors ─────────────────────────────────────
  // These don't exist in the shared palette — they're unique to WallKraft.
  static const Color tilePlaceholder = Color(0xFF2C2C2E);
  static const Color lightTilePlaceholder = Color(0xFFE5E5EA);
  static const Color favoriteRed = KraftColors.accentRed;

  // ── End WallKraft-Specific Colors ────────────────────────────────

  /// Resolve the correct color for the current [brightness].
  /// Returns [dark] in dark mode, [light] in light mode.
  static Color resolve(Brightness brightness, Color dark, Color light) {
    return brightness == Brightness.dark ? dark : light;
  }

  /// Convenience — resolves from a [BuildContext].
  static Color of(BuildContext context, Color dark, Color light) {
    return resolve(Theme.of(context).brightness, dark, light);
  }

  // ── Spacing (8pt grid, from shared) ───────────────────────────────
  static const double spacing4 = KraftSpacing.spacing4;
  static const double spacing8 = KraftSpacing.spacing8;
  static const double spacing12 = KraftSpacing.spacing12;
  static const double spacing16 = KraftSpacing.spacing16;
  static const double spacing20 = KraftSpacing.spacing20;
  static const double spacing24 = KraftSpacing.spacing24;
  static const double spacing32 = KraftSpacing.spacing32;
  static const double spacing44 = 44; // Bottom nav / min touch target

  // ── Typography (from shared) ──────────────────────────────────────
  static const TextStyle largeTitle = TextStyle(
    fontSize: KraftTypography.largeTitle,
    fontWeight: FontWeight.w400,
    color: KraftColors.textPrimaryDark,
    letterSpacing: 0.37,
  );

  static const TextStyle title1 = TextStyle(
    fontSize: KraftTypography.title1,
    fontWeight: FontWeight.w400,
    color: KraftColors.textPrimaryDark,
    letterSpacing: 0.36,
  );

  static const TextStyle title2 = TextStyle(
    fontSize: KraftTypography.title2,
    fontWeight: FontWeight.w400,
    color: KraftColors.textPrimaryDark,
    letterSpacing: 0.35,
  );

  static const TextStyle title3 = TextStyle(
    fontSize: KraftTypography.title3,
    fontWeight: FontWeight.w400,
    color: KraftColors.textPrimaryDark,
    letterSpacing: 0.34,
  );

  static const TextStyle headline = TextStyle(
    fontSize: KraftTypography.headline,
    fontWeight: FontWeight.w600,
    color: KraftColors.textPrimaryDark,
    letterSpacing: -0.41,
  );

  static const TextStyle body = TextStyle(
    fontSize: KraftTypography.body,
    fontWeight: FontWeight.w400,
    color: KraftColors.textPrimaryDark,
    letterSpacing: -0.41,
  );

  static const TextStyle callout = TextStyle(
    fontSize: KraftTypography.callout,
    fontWeight: FontWeight.w400,
    color: KraftColors.textPrimaryDark,
    letterSpacing: -0.32,
  );

  static const TextStyle subhead = TextStyle(
    fontSize: KraftTypography.subheadline,
    fontWeight: FontWeight.w400,
    color: secondaryLabel,
    letterSpacing: -0.24,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: KraftTypography.footnote,
    fontWeight: FontWeight.w400,
    color: secondaryLabel,
    letterSpacing: -0.08,
  );

  static const TextStyle caption1 = TextStyle(
    fontSize: KraftTypography.caption1,
    fontWeight: FontWeight.w400,
    color: secondaryLabel,
    letterSpacing: 0,
  );

  static const TextStyle caption2 = TextStyle(
    fontSize: KraftTypography.caption2,
    fontWeight: FontWeight.w400,
    color: tertiaryLabel,
    letterSpacing: 0.07,
  );

  /// Builds the full [ThemeData] for a given brightness.
  ///
  /// Starts from [KraftTheme] and overrides wallpaper-specific parts.
  static ThemeData themeFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? KraftTheme.dark : KraftTheme.light;

    return base.copyWith(
      // Override scaffold background to WallKraft's darker dark.
      scaffoldBackgroundColor: isDark ? background : lightBackground,

      // Bottom navigation bar — wallpaper-specific.
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

      // WallKraft uses a slightly different divider thickness.
      dividerTheme: base.dividerTheme.copyWith(
        thickness: 1,
        color: isDark ? separator : lightSeparator,
      ),
    );
  }

  /// Convenience accessors for the two built-in themes.
  static ThemeData get darkTheme => themeFor(Brightness.dark);
  static ThemeData get lightTheme => themeFor(Brightness.light);
}
