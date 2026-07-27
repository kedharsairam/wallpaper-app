# Changelog

## [1.1.5] — 2026-07-27

### Fixed
- **Wallpaper tap not opening**: `flutter_staggered_grid_view` has a known hit-testing issue where `GestureDetector` inside its items doesn't always register taps. Replaced with `InkWell` which integrates correctly with the Material widget hierarchy and works reliably within staggered grid layout.

## [1.1.4] — 2026-07-27

### Fixed
- **Crash-level: `flutter:` section deleted from `pubspec.yaml`**: `uses-material-design: true` was accidentally removed when adding `dependency_overrides`, causing ALL Material icons (search, filter, heart, share, etc.) to be excluded from the APK. All icons now render properly.
- **Android `versionName` hardcoded to `1.0.0`**: `android/app/build.gradle.kts` used `versionName = "1.0.0"` instead of `flutter.versionName`. This caused `PackageInfo.fromPlatform()` to always return `1.0.0`, making:
  - **Update checker** always detect a "newer" version and show false notifications
  - **About section** display the wrong version
  Fixed by using `flutter.versionCode` / `flutter.versionName` (matching the stock Flutter template).

## [1.1.3] — 2026-07-27

### Changed
- **Upgraded `package_info_plus`** from 9.0.1 to 10.2.1 (uses Built-in Kotlin — no KGP warning).
- **Upgraded `share_plus`** from 10.1.4 to 13.3.0 (uses Built-in Kotlin — no KGP warning).
- **Share API**: `Share.shareXFiles()` → `SharePlus.instance.share(ShareParams(...))`.

## [1.1.2] — 2026-07-27

### Fixed
- **Update checker still showing false positive**: Cached result was returned without re-comparing against current app version. Now cache is invalidated when app version changes, and re-validated on every read.
- **About section version**: Was hardcoded to `1.0.0` in settings sheet. Now reads dynamically from `package_info_plus`.
- **Tap not opening images**: `GestureDetector` had `HitTestBehavior.deferToChild` (default) causing taps to slip through to the scroll view. Added `behavior: HitTestBehavior.opaque` and `transformHitTests: false` on the scale animation so the hit area doesn't shrink during press feedback.
- **Vector illustrations invisible**: Default color `Color(0x4DEBEBF5)` was near-invisible on light backgrounds. Now uses `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25)` for proper adaptation.
- **App icon**: Redesigned from jagged mountain triangles to a clean "W" monogram on dark navy background, generated via `tools/generate_icon.dart`.

### Changed
- **Filter sheet dropdowns**: Unified into reusable `_buildDropdown<T>()` with cleaner borders, rounded corners, and consistent styling.

## [1.1.1] — 2026-07-27

### Fixed
- **Update checker false positive**: Version was hardcoded to `1.0.0` in `main.dart` — the checker always saw a "newer" release. Now reads dynamically from `PackageInfo.fromPlatform()` so it always matches the installed APK version.

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
