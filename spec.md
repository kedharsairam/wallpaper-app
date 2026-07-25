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

The app has three top-level tabs, standard iOS/Android pattern:

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
│   ├── (empty state → "Browse" link)
│   └── Detail (push)
└── Downloads
    ├── (empty state → "Browse" link)
    └── Detail (push)

Detail (shared across all tabs)
├── Set Wallpaper (action sheet: Home / Lock / Both)
├── Download
├── Favorite (heart toggle)
└── Share

Modals:
├── Filter Sheet (from Browse search)
└── About / Settings (from gear icon in nav)
```

---

## 3. Screen-by-Screen Specification

### 3.1 Browse Screen

#### Navigation Bar

| Property | Value |
|----------|-------|
| Title | "WallKraft" — Large Title (34pt, Regular). Collapses to inline (17pt, Bold) on scroll. |
| Trailing icon | Gear icon (settings/about). Only icon in nav bar. |
| Leading icon | None (root view, no back button). |
| Large title collapse | `expandedHeight: 96`, `collapsedHeight: 56`. Spring animation. |

#### Search Bar

| Property | Value |
|----------|-------|
| Style | Prominent (tinted background). Fixed below nav bar, does NOT scroll with content. |
| Background | `secondarySystemBackground` (`#2C2C2E`) |
| Placeholder | "Search wallpapers" |
| Corner radius | 12pt |
| Height | 40pt |
| Icons | Leading: magnifying glass (`Icons.search`). Trailing: Clear button (appears after text entered). |
| Cancel button | Appears when search field is focused. Text "Cancel" in `systemBlue`. Tapping it: clears text, dismisses keyboard, resets to default feed. |
| Behavior | **Search-as-you-type.** Debounced at 300ms. Each keystroke updates results. |
| Scope bar | None. HIG: "Favor improving search results over including a scope bar." Filter is in the sheet. |
| Empty/focused state | When search field is tapped but empty, show **recent searches** as suggestion chips below. |

#### Search Suggestions

When search field is focused and empty, show a "Recent Searches" section:

```
Recent Searches
[mountains]  [sunset]  [minimal]  [dark]
```

- Stored locally (max 10, oldest replaced).
- Each chip is tappable (executes that search).
- Swipe left to delete individual entries.
- "Clear All" button at the end.
- If no recent searches, show nothing.

#### Grid

| Property | Value |
|----------|-------|
| Layout | Masonry (waterfall). `maxCrossAxisExtent: 170` |
| Spacing | 8pt between tiles, 16pt horizontal padding |
| Aspect ratio | Native (`dimensionX / dimensionY`). No crop. |
| Source | `thumbnail_original` (preserves ratio) |
| Cache | `cached_network_image` with disk cache |
| Scroll | Infinite scroll. Loads more when 400px from bottom. |

#### Grid Tile Overlay

Gradient at bottom of each tile: `Colors.black.withValues(alpha: 0)` → `Colors.black.withValues(alpha: 0.6)`, height 28pt.

| Element | Position | Style |
|---------|----------|-------|
| Favorites count | Leading | `♡ 1.2k` — Footnote (13pt), white at 85% |
| Resolution | Trailing | `1920×1080` — Footnote (13pt), white at 70% |

#### Pull-to-Refresh

Standard SwiftUI-style. Spinner in `label` color. Refreshes the current query (or default feed).

#### Loading State

| Element | Detail |
|---------|--------|
| First load | Centered `CircularProgressIndicator` (24px), `secondaryLabel` color |
| Load more | Bottom indicator: centered spinner + "Loading more..." in Footnote below |

#### Empty State (no results)

```
[photo.on.rectangle.angled icon — 48pt, tertiaryLabel]
No wallpapers found
Try adjusting your search or filters
```

- Icon in `tertiaryLabel` at 48pt
- Title in Callout (16pt), `secondaryLabel`
- Subtitle in Footnote (13pt), `tertiaryLabel`
- No retry button — pull-to-refresh or change search/filters

#### Error State

```
[exclamationmark.icloud icon — 48pt, tertiaryLabel]
Couldn't load wallpapers
[Retry] — systemBlue text button, Body (17pt)
```

- Same icon style as empty state
- No red icons or text. Apple uses muted colors for content errors.
- Retry button is plain text, `systemBlue`, 44pt tall tap target.

#### Scroll-to-Top

- **Mobile:** Tap status bar (not available in Flutter — accepted limitation).
- **Desktop:** `Home` key or `Ctrl+Up`. **No FAB.**

### 3.2 Details Screen (shared across tabs)

#### Navigation

| Property | Value |
|----------|-------|
| Back button | Standard chevron. Label: previous screen title. |
| Title | Empty. The wallpaper is the title. |
| Trailing | Heart (favorite) icon. Filled when favorited, outline when not. |
| Chrome visibility | Tap image → nav bar + metadata hide. Tap again → show. |

#### Image Viewer

| Property | Value |
|----------|-------|
| Initial scale | Fit within screen bounds. Aspect ratio preserved. |
| Max zoom | 5x |
| Double-tap | Zoom to 2x centered on tap point. If already zoomed, return to 1x. |
| Pinch | Open → zoom in. Close → zoom out. |
| Pan | One-finger drag when zoomed in. Rubber-bands at edges. |
| Desktop zoom | Trackpad pinch. Ctrl+Scroll. Space+click+drag to pan. |
| Desktop keyboard | `Ctrl+=` / `Ctrl+-` to zoom in/out. `Ctrl+0` to reset. |

#### Metadata Panel

Shown below the image. Each row is 44pt tall.

```
Resolution         1920 × 1080
File Size          2.4 MB
Favorites          ♡ 1,234
Category           General
```

| Element | Style |
|---------|-------|
| Label | Headline (17pt, Semibold), `secondaryLabel` |
| Value | Body (17pt, Regular), `label` |
| Separator | Inset 16pt from leading. 1pt, `separator` color. |
| Last row | No separator. |

#### Action Buttons

Placed below metadata in a vertical stack. Each is a plain text button, 44pt tall.

```
Set Wallpaper ─────────────── systemBlue, Body (17pt)
Download Wallpaper ────────── systemBlue, Body (17pt)
Share ─────────────────────── systemBlue, Body (17pt)
```

- **Set Wallpaper:** On tap, show an action sheet:
  - Home Screen
  - Lock Screen
  - Both
  - Cancel
  Uses `android_intent_plus` or platform channel to invoke system wallpaper setter. On Windows, this button is hidden.

- **Download:** Streams to disk (as current). On success: brief toast "Saved" with checkmark, auto-dismiss 2s. On failure: toast with error message.

- **Share:** Standard platform share sheet via `share_plus`. Includes image file and attribution text.

#### Loading State (Detail)

- Full-screen centered spinner while the full-resolution image loads.
- Metadata shows immediately if cached from the list.
- Error: icon + "Couldn't load wallpaper" + Retry.

#### Hero Animation

- Grid tile image → Detail image uses `Hero` widget with tag `wallpaper-${id}`.
- Shared zoom + fade transition.

### 3.3 Favorites Screen

#### Tab Bar Item
- Icon: `Icons.favorite_outline` (unselected), `Icons.favorite` (selected)
- Label: "Favorites"

#### Content

Same masonry grid as Browse. Data source: local storage (SQLite or SharedPreferences).

- Grid tiles are identical to Browse (same overlay, same tap → Detail).
- Tapping heart in Detail toggles favorite. Removed from favorites list automatically.

#### Empty State

```
[heart icon — 48pt, tertiaryLabel]
No favorites yet
Start by tapping the heart icon on a wallpaper you love
[Browse Wallpapers] — text button, systemBlue
```

- "Browse Wallpapers" button switches to Browse tab.

#### Pull-to-Refresh
- Refreshes the list (re-checks local storage — instant, but provides visual consistency).

### 3.4 Downloads Screen

#### Tab Bar Item
- Icon: `Icons.download_outline` (unselected), `Icons.download` (selected)
- Label: "Downloads"

#### Content

Grid of locally downloaded wallpapers. Data source: reads from app document directory.

- Same masonry grid as Browse.
- Each tile is the actual downloaded image (not a thumbnail).
- Overlay: resolution (matching Browse style).
- Long-press on tile: context menu with Delete option.

#### Empty State

```
[arrow.down.circle icon — 48pt, tertiaryLabel]
No downloads yet
Download a wallpaper from the detail view
[Browse Wallpapers] — text button, systemBlue
```

#### Image Source
- Use `Image.file()` from the download directory.
- If the file has been deleted externally, show a placeholder and remove from the list on next refresh.

#### Swipe Actions
- Swipe left on a download in list view (if we switch to list): "Delete" in red.

**Note:** For v1, use grid view only. List view is a future enhancement.

### 3.5 Filter Sheet

#### Trigger

- Filter icon in the search field's trailing area (appears when search field is focused).
- Also triggered from a "Filter" text button below the search bar (alternative entry).

#### Sheet Presentation

| Property | Value |
|----------|-------|
| Style | Modal bottom sheet |
| Grabber | Visible (`prefersGrabberVisible: true`) |
| Corner radius | 16pt top |
| Background | `systemBackground` (`#1C1C1E`) |
| Dismiss | Swipe down or tap backdrop. No explicit dismiss button. |
| Apply | **Changes apply immediately** on selection (no Apply button). |

#### Categories Section

Standard iOS list with checkmarks:

```
Categories
  ☑ General
  ☐ Anime
  ☐ People
```

- Each row 44pt, Body (17pt), label color.
- Tapping toggles checkmark. `systemBlue` checkmark on right.
- At least one must be active. If user deselects the last one, it automatically re-selects (silently maintains minimum).

#### Sort Section

Same list-with-checkmark pattern:

```
Sort by
  ☑ Date Added
  ☐ Relevance
  ☐ Random
  ☐ Most Viewed
  ☐ Most Favorited
  ☐ Top List
```

- Single select. Tapping one moves the checkmark.
- Selection applies immediately (sheet stays open).

#### Top Range Section

Only visible when Sort is "Top List":

```
Top Range
  ☑ Past 24h
  ☐ Past 3 days
  ☐ Past week
  ☐ Past month
  ☐ Past 3 months
  ☐ Past 6 months
  ☐ Past year
```

- Same pattern. Single select.
- Animate section appearance/disappearance when Top List is selected/deselected.

#### Sections Layout

Each section has a header in Title 2 (22pt, Regular, `label`), 16pt padding top, 8pt bottom.

### 3.6 Settings / About Sheet

#### Trigger

Gear icon in Browse nav bar trailing position.

#### Presentation

Standard bottom sheet with grabber.

#### Content

```
About
  Version         1.0.0
  Build           1
  ───────────
  Powered by Wallhaven
  ───────────
  Privacy Policy
  Open Source Licenses
```

- "Powered by Wallhaven" links to wallhaven.cc (opens in browser).
- "Privacy Policy" — opens `PRIVACY.md` or a web URL.
- Version info is auto-populated from build config.

#### No traditional settings needed
- No theme toggle (dark mode only).
- No account management (no auth in v1).
- No cache clearing (system manages this).

---

## 4. Components (Reusable Widgets)

### 4.1 WallpaperGrid

Shared across Browse, Favorites, Downloads.

| Parameter | Type | Description |
|-----------|------|-------------|
| `wallpapers` | `List<Wallpaper>` | Data source |
| `isLoadingMore` | `bool` | Show bottom loader |
| `hasMore` | `bool` | Hide bottom loader if false |
| `scrollController` | `ScrollController?` | For infinite scroll |
| `onTap` | `void Function(Wallpaper)` | Navigate to detail |
| `heroPrefix` | `String` | Unique prefix for Hero tags per tab |

### 4.2 GridTile

Individual tile in the masonry grid.

| Element | Detail |
|---------|--------|
| Image | `CachedNetworkImage` with `thumbnailOriginal`. Placeholder: dark `#2C2C2E` rectangle. Error: same dark rectangle. |
| Hero tag | `heroPrefix + wallpaper.id` |
| Aspect ratio | Intrinsic from `dimensionX/dimensionY` |
| Overlay | Gradient bottom-to-top, 28pt. Favorites left, resolution right. |

### 4.3 LoadingTile

Shimmer placeholder for pre-load grid skeletons (optional — can be simple dark rectangles).

### 4.4 InfoRow

Reusable labeled row for detail metadata.

| Parameter | Type |
|-----------|------|
| `label` | `String` |
| `value` | `String` |

### 4.5 ActionButton

Plain text action button for detail screen.

| Parameter | Type |
|-----------|------|
| `title` | `String` |
| `color` | `Color` (default systemBlue) |
| `onTap` | `VoidCallback` |

### 4.6 EmptyState

Reusable empty state for all screens.

| Parameter | Type |
|-----------|------|
| `icon` | `IconData` |
| `title` | `String` |
| `subtitle` | `String?` |
| `action` | `Widget?` (typically a text button) |

### 4.7 ErrorState

Reusable error state.

| Parameter | Type |
|-----------|------|
| `icon` | `IconData` |
| `message` | `String` |
| `onRetry` | `VoidCallback` |

---

## 5. Data Layer

### 5.1 API — WallhavenClient

```
lib/
  api/
    client.dart          # HTTP client, search() + wallpaper() methods
    exception.dart       # WallhavenException with rate limit info
    models.dart          # Wallpaper, Tag, WallhavenResponse, WallhavenMeta
```

#### Endpoints

| Endpoint | Method | Params | Returns |
|----------|--------|--------|---------|
| `/search` | GET | `q`, `categories`, `purity`, `sorting`, `topRange`, `page` | `WallhavenResponse` |
| `/wallpaper/{id}` | GET | — | Single `Wallpaper` |

#### Purity

Always `'100'` (SFW only) when no API key. HIG doesn't apply but App Store requires filtering explicit content for unauthenticated users.

#### Rate Limit Headers

Every response includes:
- `X-RateLimit-Remaining` — remaining requests in current window
- `X-RateLimit-Reset` — epoch time when limit resets

The client MUST:
1. Parse these headers from every response.
2. Store in a singleton `RateLimitState`.
3. Before making a request, check if `remaining == 0`. If so, throw a specific `RateLimitExceededException` with the reset time.
4. Expose remaining count to the UI.

#### Error Handling

| HTTP Status | Error | User Message |
|-------------|-------|-------------|
| 200 | — | Success |
| 429 | Rate limit | "Rate limit reached. Resets in 45 minutes." |
| 5xx | Server error | "Wallhaven is temporarily unavailable." |
| Timeout | No response | "Request timed out. Check your connection." |

### 5.2 Local Storage

| Data | Storage | Key/Table |
|------|---------|-----------|
| Favorites | `sqflite` | `favorites` table. Columns: `id TEXT PK`, `data TEXT` (JSON blob of Wallpaper), `saved_at INTEGER` |
| Recent searches | `SharedPreferences` | `recent_searches` — JSON array of strings, max 10 |
| Rate limit state | `SharedPreferences` | `rate_limit_remaining`, `rate_limit_reset` |
| Downloads metadata | `sqflite` | `downloads` table. Columns: `id TEXT PK`, `path TEXT`, `saved_at INTEGER` |

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
    wallpaper.dart       # Wallpaper, Tag, WallhavenResponse, WallhavenMeta, Category enum
    rate_limit.dart      # RateLimitState
```

#### Wallpaper Model

```dart
class Wallpaper {
  final String id;
  final String url;
  final String thumbnail;
  final String? thumbnailOriginal;
  final String imageOriginal; // Full-res image URL
  final int dimensionX;
  final int dimensionY;
  final int fileSize;
  final String category; // 'general', 'anime', 'people'
  final int favorites;
  final String resolution; // "1920x1080"
  final List<Tag> tags;
  final DateTime createdAt;

  // Computed
  String get fileSizeFormatted; // "2.4 MB"
}
```

#### Enums

```dart
enum Category { general, anime, people }
enum Sorting { dateAdded, relevance, random, views, favorites, toplist }
enum TopRange { pastDay, past3Days, pastWeek, pastMonth, past3Months, past6Months, pastYear }
```

---

## 6. Platform Considerations

### 6.1 Android

| Concern | Implementation |
|---------|---------------|
| Set wallpaper | Platform channel to `WallpaperManager`. Intent with `WallpaperManager.FLAG_SET_SYSTEM`, `FLAG_SET_LOCK`, or both. |
| Save to gallery | Android 10+ use `MediaStore` (no permission needed). Below 10 use `WRITE_EXTERNAL_STORAGE`. Offer both "App folder" and "Gallery" save locations. |
| Back gesture | Standard Android back gesture. Works with Flutter's `PopScope`. |
| Share sheet | `share_plus` with `Share.shareXFiles()`. |
| App icon | Adaptive icon: geometric "W" on dark navy gradient. Already generated. |
| Splash screen | `flutter_native_splash` already configured. `#0F0F0F` background. |

### 6.2 Windows (Desktop)

| Concern | Implementation |
|---------|---------------|
| Window min size | 400×600. Set in `win32_window.cpp`. |
| Keyboard shortcuts | `CallbackShortcuts` wrapping the app. `R`/`Ctrl+R` refresh, `Ctrl+F` search, `Escape` dismiss, `Home`/`Ctrl+Up` scroll to top, `Ctrl+=`/`Ctrl+-` zoom, `Ctrl+0` zoom reset. |
| Tab bar | Replace bottom tab bar with top tab bar (TabBar at top). Or use a sidebar. Flutter's `TabBar` adapts well. |
| Menu bar | Optional. Not critical for v1. |
| Download location | `getApplicationDocumentsDirectory()` or user's Pictures folder. |
| Set wallpaper | Not supported on Windows. Hide the button. |
| Context menu | Right-click on grid tile: "Open", "Download", "Copy link". |
| Mouse wheel | Standard vertical scroll. Ctrl+wheel for zoom in detail view. |

### 6.3 Cross-Platform (both)

| Concern | Implementation |
|---------|---------------|
| Image cache | `cached_network_image` with `CachedNetworkImageProvider`. Default cache: 1GB disk limit, 30 days. |
| File paths | `path_provider` `getApplicationDocumentsDirectory()` for downloads. |
| Share | `share_plus`. |
| Haptics | `HapticFeedback.lightImpact()` on: favorite toggle, download complete, filter applied. |

---

## 7. All States — Every Screen

### Browse Screen

| State | Condition | UI |
|-------|-----------|-----|
| Loading (first) | App just launched | Centered spinner |
| Loaded | Data returned | Masonry grid |
| Empty | No results for query | EmptyState icon + text |
| Error | Network/API failure | ErrorState icon + text + Retry |
| Loading more | Scrolled near bottom | Bottom spinner |
| Error loading more | - | Snackbar "Couldn't load more" |
| Search focused, no text | User tapped search | Recent searches chips |
| Search typing | User is typing | Debounced grid update |
| Search empty results | No matches | EmptyState "No results for X" |
| Rate limited | 429 response | Banner: "Rate limit reached. Resets at 3:45 PM." |

### Detail Screen

| State | Condition | UI |
|-------|-----------|-----|
| Loading | Full image loading | Centered spinner |
| Loaded | Image ready | Image + metadata + actions |
| Error | Image failed to load | ErrorState + Retry |
| Downloading | In progress | Button shows "Downloading..." + progress |
| Download success | - | Toast "Saved" (2s, auto-dismiss) |
| Download error | - | Toast "Download failed: [reason]" |
| Setting wallpaper | - | Activity indicator overlay |
| Wallpaper set | - | Toast "Wallpaper set" |
| Chrome hidden | User tapped image | Nav bar + metadata hidden |

### Favorites Screen

| State | Condition | UI |
|-------|-----------|-----|
| Loading | DB reading | Centered spinner |
| Loaded | Has favorites | Masonry grid |
| Empty | No favorites | EmptyState + Browse button |
| Error | DB error | ErrorState + Retry (re-read) |
| Pull-to-refresh | User pulled | Standard spinner |

### Downloads Screen

| State | Condition | UI |
|-------|-----------|-----|
| Loading | Scanning directory | Centered spinner |
| Loaded | Has downloads | Masonry grid |
| Empty | No downloads | EmptyState + Browse button |
| Error | Permission/storage issue | ErrorState + Retry |
| File missing | Deleted externally | Placeholder tile with "File not found" |

### Filter Sheet

| State | Condition | UI |
|-------|-----------|-----|
| Open | User tapped filter | Sheet with 3 sections |
| Category — none selected | Impossible state | Auto-reselect General |
| Category — selection changed | User tapped | Checkmark moves instantly |
| Sort — Top List | User selected | Top Range section appears with animation |
| Sort — other | User selected | Top Range section disappears with animation |

---

## 8. Animations & Micro-Interactions

| Interaction | Animation | Duration | Curve |
|-------------|-----------|----------|-------|
| Nav bar title collapse | Scale down + fade | 300ms | iOS spring |
| Search bar focus | Cancel button slides in | 200ms | easeInOut |
| Grid → Detail | Hero zoom + fade | 300ms | easeOut |
| Detail chrome hide | Crossfade | 200ms | easeInOut |
| Favorite toggle | Heart icon scale bounce (1→1.3→1) | 300ms | spring |
| Download complete | Toast slides up from bottom | 300ms, stays 2s | easeOut |
| Filter sheet | Slides up from bottom | 300ms | easeOut |
| Category checkmark | Checkmark fade in/out | 150ms | easeInOut |
| Sort selection | Checkmark moves | 150ms | easeInOut |
| Pull-to-refresh | Standard spinner | - | - |
| Error state → Retry | Button tap feedback | 100ms | - |
| Tile tap (grid) | Scale 1→0.95→1 | 100ms | easeInOut |

---

## 9. Typography & Colors (Recap)

### Typography Scale

See the full table at the top of this doc. Key values:

| Token | Size | Weight |
|-------|------|--------|
| Large Title | 34pt | Regular |
| Title 2 | 22pt | Regular |
| Headline | 17pt | Semibold |
| Body | 17pt | Regular |
| Callout | 16pt | Regular |
| Footnote | 13pt | Regular |
| Caption 1 | 12pt | Regular |

### Color Palette (Dark Mode)

| Token | Hex | Opacity |
|-------|-----|---------|
| `systemBackground` | `#1C1C1E` | 100% |
| `secondarySystemBackground` | `#2C2C2E` | 100% |
| `tertiarySystemBackground` | `#3A3A3C` | 100% |
| `label` | `#FFFFFF` | 100% |
| `secondaryLabel` | `#EBEBF5` | 60% |
| `tertiaryLabel` | `#EBEBF5` | 30% |
| `systemBlue` | `#007AFF` | 100% |
| `separator` | `#38383A` | 100% |
| Scaffold background | `#0F0F0F` | 100% (app-wide dark base — matches splash) |
| Tile placeholder | `#2C2C2E` | 100% |

---

## 10. Permissions & Privacy

### Android Permissions

| Permission | Required for | When requested |
|------------|-------------|---------------|
| `INTERNET` | API calls | Install time (auto) |
| `SET_WALLPAPER` | Set wallpaper feature | On "Set Wallpaper" tap |
| `WRITE_EXTERNAL_STORAGE` | Save to gallery (Android <10) | On "Download" if path is public |
| `READ_EXTERNAL_STORAGE` | View downloads (Android <10) | On Downloads tab if path is public |

For Android 10+, use `MediaStore` API — no storage permissions needed.

### Privacy

- **No analytics.** No Firebase, no Mixpanel, no telemetry.
- **No crash reporting.** Optionally add Sentry or Crashlytics with user consent in a future version. v1 ships without.
- **No personal data collection.** The app only stores:
  - Favorites (local only)
  - Recent searches (local only)
  - Downloaded files (local only)
- **Network requests:** Only to `wallhaven.cc` for API calls and image downloads.
- **Privacy policy:** Already written (`PRIVACY.md`). Link in Settings sheet.

---

## 11. Directory Structure

```
lib/
  main.dart                     # Entry point. Creates WallhavenApi, runs WallKraftApp.
  app.dart                      # MaterialApp with dark theme, tabs.
  theme.dart                    # AppTheme: colors, typography, spacing constants.
  
  api/
    client.dart                 # WallhavenApi: HTTP client with rate limit tracking
    exception.dart              # WallhavenException, RateLimitExceededException
  
  models/
    wallpaper.dart              # Wallpaper, Tag, WallhavenResponse, WallhavenMeta, enums
    rate_limit.dart             # RateLimitState
  
  services/
    database.dart               # SQLite database init, FavoritesDao, DownloadsDao
    download.dart               # DownloadService: streaming file download
    wallpaper_setter.dart       # Platform channel for setting wallpaper (Android)
  
  screens/
    browse.dart                 # Browse tab — grid, search, filter
    favorites.dart              # Favorites tab — local favorites grid
    downloads.dart              # Downloads tab — local files grid
    detail.dart                 # Detail — image viewer, metadata, actions
  
  widgets/
    grid.dart                   # WallpaperGrid — masonry grid
    grid_tile.dart              # GridTile — individual tile with overlay
    search_bar.dart             # SearchBar — prominent style with suggestions
    filter_sheet.dart           # FilterSheet — categories, sort, top range
    info_row.dart               # InfoRow — labeled metadata row
    action_button.dart          # ActionButton — text action button
    empty_state.dart            # EmptyState — icon + title + optional action
    error_state.dart            # ErrorState — icon + message + retry
    settings_sheet.dart         # SettingsSheet — about, attribution, links

assets/
  icon_source.png               # App icon source
  feature_graphic.png           # Play Store feature graphic

tools/
  generate_icon.js              # Icon generation script
  generate_feature_graphic.js   # Feature graphic generation script
```

---

## 12. Implementation Order

### Phase 1 — Foundation (Day 1)

1. Create `app.dart` with TabBar (3 tabs) and dark theme.
2. Create `theme.dart` with all system colors, typography styles, spacing constants.
3. Create all model files (`wallpaper.dart`, `rate_limit.dart`).
4. Create API client with rate limit tracking.

### Phase 2 — Core Browsing (Day 2-3)

5. Build `WallpaperGrid` + `GridTile` with masonry layout.
6. Build Browse screen — nav bar, grid, infinite scroll, pull-to-refresh.
7. Build loading/empty/error states.
8. Integrate `cached_network_image`.

### Phase 3 — Search & Filter (Day 3-4)

9. Build `SearchBar` with prominent style, Cancel button, debounced input.
10. Build search suggestions (recent searches).
11. Build `FilterSheet` with checkmarks, immediate apply.
12. Wire search + filter to API with URL params.

### Phase 4 — Detail Screen (Day 4-5)

13. Build image viewer with double-tap zoom, pinch zoom, pan.
14. Build metadata panel (InfoRow widgets).
15. Build action buttons (Set Wallpaper, Download, Share, Favorite).
16. Add Hero animation from grid to detail.
17. Chrome hide/show on tap.

### Phase 5 — Favorites (Day 5-6)

18. Set up SQLite database with favorites table.
19. Build Favorites screen with same grid + empty state.
20. Wire favorite toggle in Detail screen.

### Phase 6 — Downloads (Day 6-7)

21. Build `DownloadService` with streaming, progress, filename sanitization.
22. Build Downloads screen with grid + empty state.
23. Wire download button in Detail screen.
24. Add Set Wallpaper platform channel.

### Phase 7 — Polish (Day 7-8)

25. Add haptics to all interactions.
26. Add keyboard shortcuts for desktop.
27. Build Settings/About sheet.
28. Add rate limit banner/indicator.
29. Test all states (loading, empty, error, rate limited).
30. Full `flutter analyze` pass. Fix all warnings.
31. `flutter build apk --release` — verify 50MB or less.

---

## 13. Edge Cases & Gotchas

| Scenario | Handling |
|----------|----------|
| No internet on launch | Error state with Retry. No crash. |
| Rotate device | Grid reflows. Detail re-scales image. Sheet dismisses. |
| Back button during search | Dismiss keyboard first, then search. |
| Rapid filter taps | Debounce API calls. Guard with `_hasPendingSearch`. |
| Multiple tabs downloading | Queue downloads. Max 2 concurrent. |
| Storage full during download | Catch exception, show "Storage full" toast, delete partial file. |
| Very long wallpaper titles | Not applicable (no titles). But very long tags in filter? Not in v1. |
| 0x0 wallpaper dimensions | Use 16:9 fallback aspect ratio. |
| Wallhaven API down | Error state with clear message. |
| App in background during download | Download continues (Flutter isolates). Show notification? Not in v1. |
| First launch vs returning user | Check `SharedPreferences` `hasLaunched` flag. Show subtle tip on first launch. |
