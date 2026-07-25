# WallKraft — Production Specification

## 1. Overview

WallKraft is a wallpaper discovery and management app for Android (primary) and Windows (desktop companion). It sources wallpapers from the Wallhaven API.

### Core User Stories

- As a user, I can browse an infinite feed of wallpapers
- As a user, I can search for wallpapers by keyword
- As a user, I can filter by category, sorting, and time range
- As a user, I can view a wallpaper in full detail with zoom
- As a user, I can set a wallpaper on my home/lock screen
- As a user, I can download wallpapers to my device
- As a user, I can favorite wallpapers and view them later
- As a user, I can see my downloaded wallpapers in one place
- As a user, I know my rate limit status and get clear feedback when I hit it

---

## 2. Information Architecture

### 2.1 Tab Structure (Android Bottom Tab Bar)

The app has three top-level tabs:

```
[ Browse ]  [ Favorites ]  [ Downloads ]
```

- **Browse** — default tab. Wallhaven feed with search and filter.
- **Favorites** — wallpapers the user has liked. Synced to local storage.
- **Downloads** — wallpapers saved to device. Local gallery.

### 2.2 Navigation Flow

```
Tab Bar Root
├── Browse
│   └── Detail (push)
├── Favorites
│   ├── (empty state → "Browse Wallpapers" switches to Browse tab)
│   └── Detail (push)
└── Downloads
    ├── (empty state → "Browse Wallpapers" switches to Browse tab)
    └── Detail (push)

Detail (shared across all tabs)
├── Set Wallpaper (action sheet: Home / Lock / Both)
├── Download
├── Favorite (heart toggle with bounce animation)
└── Share

Modals:
├── Filter Sheet (from Browse nav bar gear icon)
└── Settings / About (from gear icon in nav)
```

---

## 3. Screen-by-Screen Specification

### 3.1 Browse Screen

#### Navigation Bar

| Property | Value |
|----------|-------|
| Title | "WallKraft" — inline (17pt, Bold), centered |
| Trailing icons | Search (magnifying glass), Filters (tune), Settings (gear) |
| Leading icon | None (root view, no back button) |
| Search | Tapping search icon enters inline search mode. Cancel button to dismiss. |

#### Search Bar (inline mode)

| Property | Value |
|----------|-------|
| Style | Inline in nav bar. `secondarySystemBackground` (`#2C2C2E`) rounded container. |
| Placeholder | "Search wallpapers" |
| Corner radius | 10pt |
| Height | 36pt |
| Prefix icon | Magnifying glass (`Icons.search`) |
| Cancel button | Replaces trailing icons. "Cancel" in `systemBlue`. Dismisses search, clears query, returns to default feed. |
| Behavior | **Search-as-you-type.** Debounced at 300ms. Each keystroke updates results. |
| Empty/focused state | When search is open but empty, show **recent searches** as suggestion chips below. |

#### Search Suggestions

When search field is focused and empty, show a "Recent Searches" section:

```
Recent Searches       [Clear All]
[mountains]  [sunset]  [minimal]  [dark]
```

- Stored locally (max 10, oldest replaced) via `SharedPreferences`.
- Each chip is tappable (executes that search).
- Close (X) button on each chip to delete individual entry.
- "Clear All" button in header.
- If no recent searches, show nothing.

#### Grid

| Property | Value |
|----------|-------|
| Layout | Masonry (waterfall). `maxCrossAxisExtent: 170` |
| Spacing | 8pt between tiles, 16pt horizontal padding |
| Aspect ratio | Native (`dimensionX / dimensionY`). No crop. |
| Source | `thumbnailOriginal` when available, else `thumbnail` |
| Cache | `cached_network_image` with disk cache, 80MB global memory cap |
| Scroll | Infinite scroll. Loads more when 400px from bottom. |
| Tile tap animation | 100ms scale 1.0→0.95→1.0 |

#### Grid Tile Overlay

Gradient at bottom of each tile: `Colors.black.withValues(alpha: 0)` → `Colors.black.withValues(alpha: 0.6)`, height 28pt.

| Element | Position | Style |
|---------|----------|-------|
| Favorites count | Leading | `♡ 1.2k` — Footnote (13pt), white at 85% |
| Resolution | Trailing | `1920×1080` — Footnote (13pt), white at 70% |

#### Pull-to-Refresh

Standard pattern. Spinner in `label` color. Refreshes the current query (or default feed).

#### Loading State

| Element | Detail |
|---------|--------|
| First load | Centered `CircularProgressIndicator` (24px), `secondaryLabel` color |
| Load more | Bottom linear indicator in grid footer |

#### Empty State (no results)

```
[photo_library_outlined icon — 48pt, tertiaryLabel]
No wallpapers found for "query"
Try adjusting your search or filters
```

- Title in Callout (16pt), `secondaryLabel`
- Subtitle in Footnote (13pt), `tertiaryLabel`

#### Error State

```
[cloud_off icon — 48pt, tertiaryLabel]
[error message]
[Retry] — systemBlue text button
```

- Retry button is plain text, `systemBlue`

#### Offline Fallback

When network fails, the app attempts to load cached results from a local JSON file (`wallkraft_cache.json`). Cached results are shown without error if available; the error state only appears if no cache exists.

#### Rate Limit Banner

A blue banner appears when remaining API calls ≤ 10:

```
API calls: 8 remaining
```

When rate limited:

```
Rate limit reached. Resets in 45 minutes.
```

#### Keyboard Shortcuts (Desktop)

| Key | Action |
|-----|--------|
| `R` / `Ctrl+R` | Refresh |
| `Ctrl+F` | Open search |
| `Escape` | Close search |
| `Home` / `Ctrl+Up` | Scroll to top |
| `Ctrl+Down` | Scroll to bottom |

### 3.2 Details Screen (shared across tabs)

#### Navigation

| Property | Value |
|----------|-------|
| Back button | Standard chevron. |
| Title | Empty. The wallpaper is the title. |
| Trailing | Heart (favorite) icon. Filled when favorited, outline when not. Bounce animation on toggle. |
| Chrome visibility | Tap image → nav bar + metadata hide. Tap again → show. |

#### Image Viewer

| Property | Value |
|----------|-------|
| Initial scale | Fit within screen bounds. Aspect ratio preserved. |
| Max zoom | 5x |
| Double-tap | Zoom to 2x centered on tap point. If already zoomed, return to 1x. |
| Pinch | Open → zoom in. Close → zoom out. |
| Pan | One-finger drag when zoomed in. |
| Desktop zoom | Trackpad pinch. `Ctrl+=` / `Ctrl+-` to zoom in/out. `Ctrl+0` to reset. |

#### Metadata Panel

Shown below the image.

```
Resolution         1920 × 1080
File Size          2.4 MB
Favorites          ♡ 1,234
Category           anime
```

#### Action Buttons

Placed below metadata in a vertical stack. Each is a plain text button, 44pt tall.

```
Download Wallpaper ────────── systemBlue, Body (17pt)
Set Wallpaper ─────────────── systemBlue, Body (17pt)
Share ─────────────────────── systemBlue, Body (17pt)
```

- **Download:** Streams to disk via `DownloadManager` singleton (deduplicated — tapping again while in-flight reuses the same future). On success: brief toast "Saved", auto-dismiss 2s. On failure: toast with error message. Shows `LinearProgressIndicator` during download.
- **Set Wallpaper:** On tap, show an action sheet: Home Screen / Lock Screen / Both. Uses platform channel (`WallpaperManager` in Kotlin). Downloads the image first if not already saved. On Windows, this button is hidden.
- **Share:** Standard platform share sheet via `share_plus`. Includes image file.

#### Hero Animation

- Grid tile image → Detail image uses `Hero` widget with tag `wallpaper-${id}`.

### 3.3 Favorites Screen

#### Tab Bar Item
- Icon: `Icons.favorite_outline` (unselected), `Icons.favorite` (selected)
- Label: "Favorites"

#### Content

Same masonry grid as Browse. Data source: SQLite via `WallKraftDatabase`.

- Grid tiles are identical to Browse.
- Tapping heart in Detail toggles favorite. Removed from favorites list automatically.
- Refreshes when tab is switched to.

#### Empty State

```
[favorite_border icon — 48pt, tertiaryLabel]
No favorites
Favorite wallpapers to see them here
[Browse Wallpapers] — text button, switches to Browse tab
```

### 3.4 Downloads Screen

#### Tab Bar Item
- Icon: `Icons.download_outline` (unselected), `Icons.download` (selected)
- Label: "Downloads"

#### Content

List of locally downloaded wallpapers. Data source: reads from `getApplicationDocumentsDirectory()`, filtered to `wallkraft-*.jpg`.

- Each item shows: thumbnail (`Image.file`), filename, file size.
- Trash icon to delete individual files.
- Refreshes when tab is switched to.

#### Empty State

```
[cloud_off icon — 48pt, tertiaryLabel]
No downloads
Download wallpapers to see them here
[Browse Wallpapers] — text button, switches to Browse tab
```

### 3.5 Filter Sheet

#### Trigger

- Filter icon (tune) in Browse nav bar.

#### Sheet Presentation

| Property | Value |
|----------|-------|
| Style | Modal bottom sheet |
| Grabber | Visible (small pill at top) |
| Corner radius | 16pt top |
| Background | `systemBackground` (`#1C1C1E`) |
| Dismiss | Swipe down or tap backdrop. |
| Apply | **Changes apply immediately** on selection (no Apply button). |

#### Categories Section

```
Categories
[General] [Anime] [People]
```

- Chip-style toggle. Tapping selects/deselects.
- At least one must be active. If user deselects the last one, it auto-re-selects.
- `AnimatedContainer` with 200ms transition.

#### Sort Section

```
Sort by
[Dropdown: Date Added ▼]
```

- `DropdownButtonFormField` for sort selection.
- Six options: Date Added, Relevance, Random, Most Viewed, Most Favorited, Top List.

#### Top Range Section

Only visible when Sort is "Top List":

```
Top Range
[Dropdown: Past month ▼]
```

- Seven options: Past 24h, Past 3 days, Past week, Past month, Past 3 months, Past 6 months, Past year.

### 3.6 Settings / About Sheet

#### Trigger

Gear icon in Browse nav bar.

#### Presentation

Standard bottom sheet with grabber.

#### Content

```
About
  Version         1.0.0
  Build           1
  ───────────
  Privacy Policy
  Open Source Licenses
```

- Version info is auto-populated from build config.
- Privacy Policy removed for v1 (displays empty view).

---

## 4. Components (Reusable Widgets)

### 4.1 WallpaperGrid

Shared across Browse, Favorites.

| Parameter | Type | Description |
|-----------|------|-------------|
| `wallpapers` | `List<Wallpaper>` | Data source |
| `isLoadingMore` | `bool` | Show bottom loader |
| `hasMore` | `bool` | Hide bottom loader if false |
| `scrollController` | `ScrollController?` | For infinite scroll |
| `onTap` | `void Function(Wallpaper)` | Navigate to detail |

### 4.2 FilterSheet

Standalone widget file (`widgets/filter_sheet.dart`) with static `show()` method.

| Parameter | Type | Description |
|-----------|------|-------------|
| `categories` | `String` | 3-char code (e.g. "111") |
| `sorting` | `String` | API sort value |
| `topRange` | `String?` | API top range value |
| `onApply` | `void Function(String, String, String?)` | Called on every change |

### 4.3 EmptyState

Reusable empty state.

| Parameter | Type |
|-----------|------|
| `icon` | `IconData` |
| `title` | `String` |
| `subtitle` | `String?` |
| `action` | `Widget?` (typically a text button) |

### 4.4 ErrorState

Reusable error state.

| Parameter | Type |
|-----------|------|
| `icon` | `IconData` |
| `message` | `String` |
| `onRetry` | `VoidCallback` |

---

## 5. Data Layer

### 5.1 API — WallpaperApi

```
lib/
  api/
    cancel_token.dart       # CancelToken + extension for request cancellation
    client.dart             # WallpaperApi: HTTP client, search() + wallpaper() methods
    exception.dart          # WallpaperApiException, CancelledException, RateLimitExceededException
```

#### Endpoints

| Endpoint | Method | Params | Returns |
|----------|--------|--------|---------|
| `/search` | GET | `q`, `categories`, `purity`, `sorting`, `topRange`, `page` | `WallpaperResponse` |
| `/w/{id}` | GET | — | Single `Wallpaper` |

#### Purity

Always `'100'` (SFW only) when no API key.

#### Rate Limit Headers

Every response includes:
- `X-RateLimit-Remaining` — remaining requests in current window
- `X-RateLimit-Reset` — epoch time when limit resets

The client:
1. Parses these headers from every response.
2. Stores in a singleton `RateLimitState`.
3. Before making a request, checks if `remaining == 0`. If so, throws `RateLimitExceededException`.
4. Exposes remaining count to the UI.

#### Request Cancellation

The `search()` method accepts an optional `CancelToken`. When cancelled, the underlying `http.Client` is closed, aborting the request mid-flight. In-flight requests are cancelled on:
- New search query (debounce fires)
- Filter change
- Widget disposal

#### Error Handling

| HTTP Status | Error | User Message |
|-------------|-------|-------------|
| 200 | — | Success |
| 429 | Rate limit | "Rate limit reached. Resets in 45 minutes." |
| 5xx | Server error | "API error: [status]" |
| Timeout | No response | "Request timed out. Check your connection." |

### 5.2 Local Storage

| Data | Storage | Key/Table |
|------|---------|-----------|
| Favorites | `sqflite` | `favorites` table. Columns: `id TEXT PK`, `data TEXT` (JSON blob of Wallpaper), `saved_at INTEGER` |
| Recent searches | `SharedPreferences` | `recent_searches` — JSON array of strings, max 10 |
| Downloads metadata | `sqflite` | `downloads` table. Columns: `id TEXT PK`, `path TEXT`, `saved_at INTEGER` |
| Response cache | File (temp directory) | `wallkraft_cache.json` — raw JSON of last search response |

#### Database Schema

```sql
CREATE TABLE favorites (
  id TEXT PRIMARY KEY,
  data TEXT NOT NULL,       -- JSON serialized Wallpaper
  saved_at INTEGER NOT NULL
);

CREATE TABLE downloads (
  id TEXT PRIMARY KEY,
  path TEXT NOT NULL,
  saved_at INTEGER NOT NULL
);
```

### 5.3 Models

```
lib/
  models/
    category.dart         # Category, SortOption, TopRange enums
    wallpaper.dart        # Wallpaper, Tag, WallpaperResponse, WallpaperMeta
    rate_limit.dart       # RateLimitState
```

#### Wallpaper Model

```dart
class Wallpaper {
  final String id;
  final String url;
  final String path;          // Full-res image URL
  final String thumbnail;     // Small thumb
  final String? thumbnailLarge;
  final String? thumbnailOriginal;
  final int dimensionX;
  final int dimensionY;
  final String ratio;
  final int fileSize;
  final int favorites;
  final String category;      // 'general', 'anime', 'people'
  final List<Tag> tags;

  String get resolution;         // "1920x1080"
  String get fileSizeFormatted;  // "2.4 MB"
}
```

#### Enums

```dart
enum Category { general, anime, people }
enum SortOption { dateAdded, relevance, random, mostViewed, mostFavorited, topList }
enum TopRange { past24h, past3Days, pastWeek, pastMonth, past3Months, past6Months, pastYear }
```

### 5.4 Services

```
lib/
  services/
    cache_service.dart        # CacheService — file-based JSON cache for offline fallback
    database.dart             # WallKraftDatabase — SQLite with favorites + downloads tables
    download_manager.dart     # DownloadManager — singleton, deduplicates in-flight downloads
    recent_searches.dart      # RecentSearchesService — SharedPreferences-backed search history
    update_checker.dart       # UpdateChecker — fetches latest GitHub release tag
    wallpaper_setter.dart     # WallpaperSetter — platform channel for Android WallpaperManager
```

#### DownloadManager

Singleton (`DownloadManager.instance`). Deduplicates in-flight requests:
- `download(wallpaper, onProgress?)` — returns file path. If already downloading, returns existing future.
- `isDownloading(id)` — check if in progress.
- `getExistingPath(id)` — check if already on disk.

---

## 6. Platform Considerations

### 6.1 Android

| Concern | Implementation |
|---------|---------------|
| Set wallpaper | Platform channel to `WallpaperManager` in Kotlin `MainActivity.kt` |
| Save to gallery | Downloads to `getApplicationDocumentsDirectory()` (app-private) |
| Share sheet | `share_plus` with `Share.shareXFiles()` |
| App icon | Adaptive icon |
| Permissions | `INTERNET`, `SET_WALLPAPER` in manifest. No storage permissions (scoped storage). |

### 6.2 Windows (Desktop)

| Concern | Implementation |
|---------|---------------|
| Window min size | 400×600 |
| Keyboard shortcuts | `CallbackShortcuts` wrapping the app |
| Download location | `getApplicationDocumentsDirectory()` |
| Set wallpaper | Not supported. Button not shown. |
| SQLite | Uses `sqflite_common_ffi` via `databaseFactoryFfi` in `main.dart` |

### 6.3 Cross-Platform

| Concern | Implementation |
|---------|---------------|
| Image cache | `cached_network_image` with 80MB global memory cap |
| File paths | `path_provider` `getApplicationDocumentsDirectory()` for downloads |
| Share | `share_plus` pinned at `^10.1.4` (upstream issue fluttercommunity#3831) |
| Haptics | `HapticFeedback.lightImpact()` on favorite toggle, download complete |

---

## 7. All States — Every Screen

### Browse Screen

| State | Condition | UI |
|-------|-----------|-----|
| Loading (first) | App just launched | Centered spinner |
| Loaded | Data returned | Masonry grid |
| Empty | No results for query | EmptyState icon + text |
| Error (with cache) | Network/API failure + cache available | Grid shows cached data (no error) |
| Error (no cache) | Network/API failure, no cache | ErrorState icon + text + Retry |
| Loading more | Scrolled near bottom | Bottom indicator |
| Error loading more | - | Snackbar "Failed to load more: ..." |
| Search focused, no text | User tapped search | Recent searches chips |
| Search typing | User is typing | Debounced grid update, previous request cancelled |
| Search empty results | No matches | EmptyState "No wallpapers found for 'query'" |
| Rate limited | 429 response | Blue banner |

### Detail Screen

| State | Condition | UI |
|-------|-----------|-----|
| Loading | Full image loading | Centered spinner |
| Loaded | Image ready | Image + metadata + actions |
| Downloading | In progress | Button shows "Downloading X%" + progress bar |
| Download success | - | Toast "Saved" (2s, auto-dismiss) |
| Download error | - | Toast "Download failed: [reason]" |
| Already saved | File exists | Toast "Already saved" |
| Wallpaper set | - | Toast "Wallpaper set" / "Failed to set wallpaper" |
| Chrome hidden | User tapped image | Nav bar + metadata hidden |

### Favorites Screen

| State | Condition | UI |
|-------|-----------|-----|
| Loading | DB reading | Centered spinner |
| Loaded | Has favorites | Masonry grid |
| Empty | No favorites | EmptyState + "Browse Wallpapers" button |

### Downloads Screen

| State | Condition | UI |
|-------|-----------|-----|
| Loading | Scanning directory | Centered spinner |
| Loaded | Has downloads | List with thumbnails + file info |
| Empty | No downloads | EmptyState + "Browse Wallpapers" button |
| Delete | User taps trash | File deleted, list refreshed |

---

## 8. Animations & Micro-Interactions

| Interaction | Animation | Duration | Curve |
|-------------|-----------|----------|-------|
| Grid → Detail | Hero zoom + fade | 300ms | easeOut |
| Detail chrome hide | Crossfade | 200ms | easeInOut |
| Favorite toggle | Heart scale bounce (1→1.3→1) | 200ms | easeOut |
| Download complete | Toast slides up | 300ms | easeOut |
| Filter sheet | Slides up from bottom | 300ms | easeOut |
| Category chip | AnimatedContainer color transition | 200ms | easeInOut |
| Tile tap (grid) | Scale 1→0.95→1 | 100ms | easeInOut |

---

## 9. Typography & Colors

### Typography Scale

| Token | Size | Weight |
|-------|------|--------|
| Large Title | 34pt | Regular |
| Title 3 | 20pt | Regular |
| Headline | 17pt | Semibold |
| Body | 17pt | Regular |
| Callout | 16pt | Regular |
| Footnote | 13pt | Regular |
| Caption 1 | 12pt | Regular |

### Color Palette (Dark Mode)

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#0F0F0F` | Scaffold background |
| `systemBackground` | `#1C1C1E` | Cards, sheets |
| `secondarySystemBackground` | `#2C2C2E` | Search field, inactive chips |
| `tertiarySystemBackground` | `#3A3A3C` | Image error placeholder |
| `label` | `#FFFFFF` | Primary text |
| `secondaryLabel` | `#EBEBF5` at 60% | Secondary text |
| `tertiaryLabel` | `#EBEBF5` at 30% | Placeholder, disabled |
| `systemBlue` | `#007AFF` | Interactive elements |
| `favoriteRed` | `#FF3B30` | Favorite heart |

---

## 10. Permissions & Privacy

### Android Permissions

| Permission | Required for |
|------------|-------------|
| `INTERNET` | API calls |
| `SET_WALLPAPER` | Set wallpaper feature |

No storage permissions needed (app-private directory with scoped storage).

### Privacy

- **No analytics.** No Firebase, no telemetry.
- **No crash reporting.**
- **No personal data collection.**
- **Network requests:** Only to `wallhaven.cc` for API calls and image downloads.

---

## 11. Directory Structure (current)

```
wallkraft/
  lib/
    main.dart                        # Entry point. Error boundary, 80MB cache cap,
                                     # databaseFactoryFfi init, creates WallpaperApi.
    app.dart                         # MaterialApp, _MainScaffold with 3 tabs.
    theme.dart                       # AppTheme: colors, typography, spacing.

    api/
      cancel_token.dart              # CancelToken — wraps http.Client for abort
      client.dart                    # WallpaperApi — HTTP client with rate limits + cancellation
      exception.dart                 # WallpaperApiException, CancelledException, RateLimitExceededException

    models/
      category.dart                  # Category, SortOption, TopRange enums
      wallpaper.dart                 # Wallpaper, Tag, WallpaperResponse, WallpaperMeta
      rate_limit.dart                # RateLimitState

    services/
      cache_service.dart             # CacheService — file-based JSON cache for offline
      database.dart                  # WallKraftDatabase — SQLite favorites + downloads
      download_manager.dart          # DownloadManager — singleton, deduplication
      recent_searches.dart           # RecentSearchesService — max 10 via SharedPreferences
      update_checker.dart            # UpdateChecker — GitHub API latest release
      wallpaper_setter.dart          # Platform channel for wallpaper (Android)

    screens/
      browse.dart                    # Browse tab — search, filters, masonry grid
      favorites.dart                 # Favorites tab — local SQLite, onBrowseTap callback
      downloads.dart                 # Downloads tab — local files, onBrowseTap callback
      detail.dart                    # Detail — InteractiveViewer, metadata, actions

    widgets/
      filter_sheet.dart              # FilterSheet — categories, sort, top range
      grid.dart                      # WallpaperGrid — masonry layout
      settings_sheet.dart            # Settings/About sheet
      empty_state.dart               # Apple-style empty state
      error_state.dart               # Muted error state with retry

  test/
    widget_test.dart                 # Model tests, CancelToken test, JSON round-trip

  android/
    app/src/main/kotlin/com/wallkraft/app/MainActivity.kt
                                     # Platform channel: setWallpaper via WallpaperManager
    app/proguard-rules.pro           # Keep model classes for JSON deserialization
```

---

## 12. Edge Cases & Gotchas

| Scenario | Handling |
|----------|----------|
| No internet on launch | Error state with fallback to cached results if available |
| Multiple rapid searches | Previous request cancelled via CancelToken before new search |
| Double-tap download | DownloadManager deduplicates — returns existing future |
| Set wallpaper without downloading | DownloadManager auto-downloads first, returns path |
| Concurrent downloads | DownloadManager maps by wallpaper ID, one future per ID |
| Share without downloading | Same auto-download pattern |
| share_plus compile failure | Pinned at `^10.1.4` — upstream issue fluttercommunity#3831 |
| 0x0 wallpaper dimensions | Fallback to 16:9 aspect ratio |
| Database migration | Version check in `WallKraftDatabase._initDatabase()` |
