# WallKraft Architecture

## Overview

WallKraft is a Flutter wallpaper browsing client for wallhaven.cc. It displays a masonry grid of wallpapers from the Wallhaven API, lets users search/filter, view details, download, favorite, and set wallpapers.

**Stack**: Flutter 3.44.8 (stable), Dart, SQLite (sqflite), shared_preferences, cached_network_image, flutter_staggered_grid_view, package_info_plus, url_launcher.

---

## Directory Structure

```
lib/
  main.dart                   — Entry point, bootstrap, global error handlers
  app.dart                    — MaterialApp, theme, route config, update checker trigger
  theme.dart                  — Light/dark theme definitions + color constants
  l10n/                       — Localization delegates
  api/
    client.dart               — Wallhaven API client (search, suggestions, etc.)
    cancel_token.dart         — Request cancellation pattern
    exception.dart            — API exception class
  models/
    wallpaper.dart            — Wallpaper data model + JSON parsing
    category.dart             — Category/purity enums
    rate_limit.dart           — API rate limit tracker (singleton)
  screens/
    browse.dart               — Main grid screen with search, filters, grid
    detail.dart               — Full-screen wallpaper detail with zoom, metadata
    favorites.dart            — Favorites list (from local DB)
    downloads.dart            — Downloaded files list (from disk)
    settings_screen.dart      — Full-page settings (theme, API key, about, version)
  services/
    update_checker.dart       — GitHub release version check with 24h cache
    database.dart             — SQLite DB for favorites + download tracking
    download_manager.dart     — File download with progress tracking
    wallpaper_setter.dart     — Android wallpaper setter via platform channel
    notification_service.dart — Download progress notifications
    theme_service.dart        — Persist theme preference
    cache_service.dart        — JSON cache for offline fallback
    recent_searches.dart      — Recent search query persistence
    db_init_io.dart / stub    — Desktop/mobile DB init split
  widgets/
    grid.dart                 — Masonry wallpaper grid (shared across screens)
    shimmer_grid.dart         — Loading shimmer placeholder
    filter_sheet.dart         — Bottom sheet for category/sorting/ratio filters
    empty_state.dart          — Reusable empty state with illustrations
    empty_illustrations.dart  — Custom vector illustrations as widget art
  helpers/
    responsive.dart           — Decode-size helpers for image memory caching
  models/
    wallpaper.dart            — Wallpaper data class
```

---

## Data Flow

```
User action → Screen State → API client → HTTP → Parse models → setState → Rebuild
                                                                    ↓
                                                              CacheService.save()
```

1. **BrowseScreen** calls `api.search()` with query + filters
2. API returns JSON → parsed into `List<Wallpaper>` via `Wallpaper.fromJson()`
3. `setState()` updates `_wallpapers` → `WallpaperGrid` rebuilds
4. Raw JSON is cached to `CacheService` for offline fallback

---

## State Management

No state management library — plain `StatefulWidget` + `setState`. The app is simple enough that this works cleanly:

- **BrowseScreen** — owns API state, search, filters, pagination
- **FavoritesScreen** — loads from DB via `WallKraftDatabase`
- **DownloadsScreen** — scans filesystem for downloaded files
- **DetailScreen** — receives wallpaper via route arguments, manages its own favorite/download/set state

Singletons for cross-cutting concerns:
- `DownloadManager.instance` — download queue
- `NotificationService.instance` — Android notifications
- `RateLimitState.instance` — API rate limit tracking
- `CacheService.instance` — offline JSON cache

---

## Screen Flow

```
App launch
  ↓
MainScaffold (bottom nav: Browse | Favorites | Downloads | Settings)
  ↓ tap grid item
DetailScreen (route: /detail, receives wallpaper via arguments)
  ↓ tap tag
Back to BrowseScreen with tag as search query
```

Routes are defined in `app.dart` via `onGenerateRoute`. Route type must match the generic type used in `pushNamed`:

```dart
// Correct:
return MaterialPageRoute<Map<String, dynamic>>(
  settings: settings,
  builder: (context) => const DetailScreen(),
);
// Navigation call:
Navigator.pushNamed<Map<String, dynamic>>(context, '/detail', arguments: {...});
```

**⚠️ Critical**: The route generic type must match. `MaterialPageRoute<dynamic>` will crash at runtime with a type cast error when used with `pushNamed<Map<String, dynamic>>`.

---

## Key Services

### Update Checker (`update_checker.dart`)
- Checks GitHub releases API for newer versions
- Compares against `PackageInfo.fromPlatform()` version
- Caches result in SharedPreferences for 24 hours
- Stores `update_check_app_version` key to invalidate cache on app update
- If cached version is stale (app was updated), re-checks automatically

### Database (`database.dart`)
- SQLite via sqflite
- Tables: `favorites`, `downloads`
- Favorite wallpaper metadata stored as JSON columns
- Downloads tracked by wallpaper ID + file path

### Download Manager (`download_manager.dart`)
- Downloads wallpaper image file to app documents directory
- Reports progress via callback
- Tracks existing downloads to avoid duplicates
- Filename format: `wallkraft-{wallpaper_id}.jpg`

---

## Platform Notes

### Android
- Full feature set: wallpaper setter, notifications, share, download
- Build: `flutter build apk --release --split-per-abi` (produces arm64-v8a, armeabi-v7a, x86_64)
- Release CI via GitHub Actions (`.github/workflows/`)

### Windows (development testing)
- Most features work: browse, search, filter, favorites, API calls
- NOT available: wallpaper setter, notifications, download progress notifications
- Build + run: `flutter run -d windows --debug`
- Hot reload (`r`) works for rapid iteration

---

## Build & Test Commands

| Task | Command |
|------|---------|
| Quick test | `.\tools\run.ps1` |
| Full pre-commit check | `.\tools\test_all.ps1` |
| Analyze only | `flutter analyze` |
| Unit tests | `flutter test` |
| Android release | `flutter build apk --release --split-per-abi` |
| Windows debug | `flutter build windows --debug` |

---

## Key Decisions & Tradeoffs

### Grid: `GestureDetector` with `HitTestBehavior.translucent`
`flutter_staggered_grid_view` has hit-testing quirks. `GestureDetector` with `behavior: HitTestBehavior.translucent` is the most reliable tap handler inside masonry items. Tiles are plain `StatelessWidget` — no animation, no `InkWell` (which showed no improvement and added complexity).

### Homepage: Stack-based overlay
The homepage is an overlay on top of the grid, not a separate screen. `Stack(fit: StackFit.expand)` keeps the grid alive underneath (Layer 0) while the homepage overlay (Layer 1) covers it. This preserves scroll position and avoids re-fetching data. Tapping Home shows a SnackBar with Undo — Undo just removes the overlay.

### Browse App Bar: Always-visible search bar
The browse app bar has a Home icon on the left and the compact search bar filling the rest. No toggle modes (`_showSearch` was removed). The search bar always shows search + filter buttons in its suffix. App bar is `null` on the homepage (edge-to-edge).

### Route Type Safety
`MaterialPageRoute<Map<String, dynamic>>(settings: settings, builder: ...)` — the generic type must match the `pushNamed<Map<String, dynamic>>` call. A mismatch crashes silently via the platform error handler (user sees "nothing happens" on tap).

### Image Memory Management
`CachedNetworkImage` with `memCacheWidth` using `Responsive.gridTileWidth(context)` ensures 4K wallpapers are decoded at display size (170 logical pixels) instead of full resolution. Prevents OOM on mid-range devices. 80MB image cache ceiling set in `main.dart`.

### No State Management Library
The app has a flat screen hierarchy with localized state. `setState` is sufficient. Adding Riverpod/Bloc would be over-engineering for this scope.

### Version + Build Number
`pubspec.yaml` version `{major}.{minor}.{patch}+{build}`. Version name from `PackageInfo.fromPlatform()` is used by the update checker. Build number auto-increments. The version in pubspec MUST match the git tag (e.g., `1.1.6+1` ↔ tag `v1.1.6`).

---

## Testing Workflow

1. I make code changes
2. Run `flutter analyze` — catches type errors, unused imports, context misuse
3. Run `flutter test` — 13 widget/unit tests
4. Build: `flutter build windows --debug`
5. Launch: `.\tools\run.ps1` — opens native Windows window
6. User visually verifies on desktop
7. On approval: commit + push, CI builds Android release APKs
