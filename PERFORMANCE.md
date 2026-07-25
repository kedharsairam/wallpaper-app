# WallKraft — Performance Architecture

## Golden Rule

The app will be 60fps smooth on a 2020 Moto G (3GB RAM) and a Samsung Galaxy S25 Ultra. No dropped frames, no OOM crashes, no loading jank.

## 1. Image Memory (The Only Real Danger)

### Problem

A single 4K wallpaper (3840×2160) decoded at full resolution = **32MB of memory** in RGBA. If the grid decodes 20 of these simultaneously, that's **640MB**. Most mid-range Android devices kill the process at 256MB heap.

### Solution — Every image, every time, enforce this

```dart
// Grid thumbnail — decode at display size
CachedNetworkImage(
  imageUrl: wallpaper.thumbnailOriginal ?? wallpaper.thumbnail,
  memCacheWidth: _tileDisplayWidth(context), // 170 * dpr ≈ ~400px
  memCacheHeight: _tileDisplayHeight(context),
  placeholder: (_, __) => const _TilePlaceholder(),
  errorWidget: (_, __, ___) => const _TilePlaceholder(),
)

// Detail full-res — decode at screen size, not native
Image(
  image: ResizeImage(
    NetworkImage(wallpaper.imageOriginal),
    width: _screenDisplayWidth(context), // screenWidth * dpr
  ),
  // OR use `CachedNetworkImage` with memCacheWidth
)
```

### Global limit

```dart
// In main.dart, BEFORE any image loads
void main() {
  PaintingBinding.instance.imageCache.maximumSizeBytes = 80 * 1024 * 1024; // 80MB
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WallKraftApp());
}
```

### Image dimensions helper

```dart
// lib/helpers/responsive.dart
class Responsive {
  static int displayPixels(BuildContext context, double logicalPixels) {
    return (logicalPixels * MediaQuery.of(context).devicePixelRatio).round();
  }
}
```

## 2. Dependency Weight Budget

| Dependency | Size | Verdict | Why |
|-----------|------|---------|-----|
| `flutter_staggered_grid_view` | ~200KB compiled | ✅ Keep | Masonry layout. No viable alternative. |
| `cached_network_image` | ~800KB compiled | ✅ Keep | Disk cache is essential. `memCacheWidth` prevents OOM. |
| `sqflite` | ~600KB compiled | ✅ Keep | Favorites need structured storage. SharedPrefs JSON is fragile for write-heavy favorites. |
| `path_provider` | ~100KB compiled | ✅ Keep | Essential for downloads. |
| `share_plus` | ~400KB compiled | ✅ Keep | Share feature. One-time cost. |
| `flutter_native_splash` | ~200KB compiled | ✅ Keep | Already configured. One-time startup cost. |

**Total dependency overhead: ~2.3MB.** Release APK target: **53MB** (up from 49MB). App Bundle delivers ~18MB to user.

## 3. Build & Rendering Rules

### Do this

| Rule | Why |
|------|-----|
| `const` constructors on all widgets | Prevents unnecessary rebuilds. Compiler can cache the widget instance. |
| `RepaintBoundary` around each grid tile | Each tile paints independently. Scrolling doesn't repaint off-screen tiles. |
| `.builder()` constructors everywhere (`ListView.builder`, `GridView.builder`) | Lazy loading. Only visible items are built. |
| `FadeTransition` for animations | `Opacity` widget forces repaint on every frame. `FadeTransition` is GPU-optimized. |
| `AnimatedContainer` over `setState` + manual animation | Handled by the framework with compositing layers. |
| `ValueNotifier` + `ValueListenableBuilder` for local state | Only rebuilds the part of the tree that depends on that value. |

### Don't do this

| Anti-pattern | Why |
|-------------|-----|
| `setState(() {})` in `_onScroll` without diffing | Rebuilds the entire screen on every scroll frame. Use a `ValueNotifier<bool>` for FAB visibility. |
| `Opacity` on animated images | Forces CPU-side repaint on every frame. Use `FadeTransition`. |
| Recreating lists every build | Pass a stable list reference. `_wallpapers` is only mutated on data change, not on every setState. |
| Loading full-res images in grid | Already prevented by `memCacheWidth`. Enforce via code review. |
| Nested `ScrollView` inside `SingleChildScrollView` | Flutter creates an infinite viewport. One scrollable per screen. |

### Scroll performance

```dart
// Grid — use the masonry grid's built-in lazy builder
MasonryGridView.extent(
  maxCrossAxisExtent: 170,
  crossAxisSpacing: 8,
  mainAxisSpacing: 8,
  // DO NOT pre-compute all item heights. Let masonry compute them lazily.
  itemBuilder: (context, index) => RepaintBoundary(
    child: GridTile(wallpaper: wallpapers[index]),
  ),
)
```

## 4. Startup Performance

| Concern | Solution |
|---------|----------|
| SQLite initialization | Open database lazily, not in `main()`. First DB query may be 50ms slower — acceptable. |
| First image load | Placeholder shows instantly (`_TilePlaceholder` is a `Container` with dark bg, 0 allocation cost). Image loads async. |
| Tab bar | All 3 tabs exist but only visible tab is built. `TabBarView.children` with `AutomaticKeepAliveClientMixin` only for Browse tab. Favorites and Downloads rebuild each time they're visited. |

## 5. APK Size Budget

| Component | Size |
|-----------|------|
| Flutter engine | 24.5MB |
| Dart runtime + core libs | 2.1MB |
| Material + Cupertino | 7.8MB |
| App code | 4.2MB |
| Assets (icons, splash) | 1.8MB |
| Native libs (arm64, x86_64) | 8.0MB |
| Package dependencies | 4.6MB |
| **Release APK** | **~53MB** |
| **App Bundle (Play Store)** | **~18MB** delivered |

## 6. Runtime Performance Targets

| Operation | Target | How |
|-----------|--------|-----|
| App cold start to visible grid | < 2s | Lazy DB init, placeholder immediately, images load async |
| Grid scroll (60fps) | No dropped frames | RepaintBoundary, lazy builder, const widgets |
| Search debounce → results | < 300ms API + 100ms render | Keyed list items prevent rebuild of unchanged tiles |
| Detail image load | < 1.5s on 4G | ResizeImage decodes to screen size, not native 4K |
| Download 10MB file | < 10s on WiFi | Streaming to disk, no memory buffer |
| Favorite toggle → UI update | < 16ms (60fps) | `ValueNotifier<bool>` on heart icon, no full-screen rebuild |

## 7. Monitoring (Development)

During development, always build and test with:

```bash
flutter run --profile  # Shows frame timing in DevTools
flutter run --release  # Tests actual release performance
flutter build apk --release --target-platform android-arm64
```

Watch for:
- **Frame rendering budget** > 16ms in DevTools → investigate
- **Image cache bytes** growing unbounded → check `memCacheWidth` enforcement
- **Widget rebuild count** spiking per frame → check for anti-patterns

## Summary

The app will not lag because:

1. **Images are always decoded at display size.** The only real performance killer is handled with a single `memCacheWidth` parameter on every image load. This is enforced at the widget level, not left to developer discipline.

2. **Lazy builders everywhere.** Nothing is built before it's visible. No pre-computation, no eager loading.

3. **Minimal dependencies.** Each dependency chosen for performance, not convenience. No Bloc, no Provider, no Riverpod.

4. **Const + RepaintBoundary as standard practice.** Not "add if we have time."

5. **Image cache capped at 80MB.** The OS never kills the app for memory pressure.
