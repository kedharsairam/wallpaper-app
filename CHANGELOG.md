# Changelog

## [1.1.0] — 2026-07-27

### Added
- **App shortcuts**: 3 Android shortcuts (Search, Favorites, Downloads) with `wallkraft://` deep link scheme.
- **Search suggestions**: Wallhaven suggestions API with 200ms debounce, integrated into browse screen.
- **Download notifications**: Progress, completion, and error notifications via `flutter_local_notifications`.
- **Localization**: `flutter_localizations` + `intl` with `app_en.arb` (~70 strings) covering all UI sections.
- **Empty state illustrations**: CustomPaint vector art for no-wallpapers, no-favorites, no-downloads, and error states.
- **API key management**: Paste dialog in settings sheet with link to wallhaven.cc/settings/account.
- **Theme persistence**: Dark/Light/System mode selection saved to SharedPreferences.
- **CI/CD**:
  - PR/main CI checks (analyze + test) via `.github/workflows/ci.yml`.
  - Automated release builds on `v*` tags with APK renaming (`WallKraft-{version}-{abi}.apk`).
- **Widget tests**: 4 tests for browse screen (loading, success, error, search) with `MockWallpaperApi`.
- **Integration tests**: 3 tests (launch, tab navigation, search field).
- **Icon generation**: `tools/generate_icon.dart` script for launcher icon regeneration.
- **ProGuard/R8**: Full mode enabled with `android.enableR8.fullMode=true` and `isShrinkResources = true`.

### Changed
- **Splash screen**: Replaced 17 PNG assets with a single XML color drawable (-147 KB).
- **Theme system**: Full color audit across all screens — all hardcoded dark-mode colors now adapt to light mode.
- **Launcher icons**: Refreshed with new background/foreground layers.
- **Windows desktop**: ATL dependency resolved for local builds.

### Fixed
- **Search suggestion timer**: `_suggestionDebounce` added to cancel stale 200ms timers on rapid input.
- **Update checker cache**: Empty string from "no update" result no longer treated as a valid cached version.
- **Snackbar action button**: `actionTextColor` added to `SnackBarThemeData` — "Update" button was invisible in light mode.
- **"Set Wallpaper" sheet title**: White-on-white in light mode — now uses `Theme.of(ctx).textTheme.titleLarge`.
- **Load-more spinner**: Hardcoded dark color replaced with adaptive `onSurface.withValues(alpha: 0.6)`.
- **Unused import**: Removed from `favorites.dart`.
- **Dead code**: `isLight()` method removed from `settings_sheet.dart`.

## [1.0.0] — 2026-07-26

### Added
- Initial release of WallKraft.
- Browse wallpapers from Wallhaven with category and filter support.
- Favorites (local SQlite storage).
- Downloads with progress tracking.
- Detail view with set-as-wallpaper, share, and resolution info.
- Dark and light theme support.
- Rate limit handling with user-friendly banners.
- Empty state illustrations.
- Shimmer loading grids.
