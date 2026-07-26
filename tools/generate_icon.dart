// Generates the app icon: a mountain range silhouette on a dark background.
// Run: dart tools/generate_icon.dart
// Then: dart run flutter_launcher_icons

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  // ──────────────────────────────────────────────
  // Foreground layer (108x108 — adaptive icon spec)
  // ──────────────────────────────────────────────
  final fg = img.Image(width: 108, height: 108);
  img.fill(fg, color: img.ColorRgba8(0, 0, 0, 0)); // transparent

  // Draw three mountain peaks in white
  final peaks = [
    // (center_x, peak_y, base_y, width_at_base)
    (cx: 54.0, py: 18.0, by: 92.0, hw: 50.0),  // center peak
    (cx: 22.0, py: 38.0, by: 92.0, hw: 30.0),  // left peak
    (cx: 88.0, py: 42.0, by: 92.0, hw: 32.0),  // right peak
  ];

  for (final p in peaks) {
    _fillTriangle(fg, p.cx, p.py, p.hw, p.by, 255, 255, 255);
  }

  // Small sun/moon circle behind the center peak
  _fillCircle(fg, 54, 48, 10, 255, 255, 255);

  // Save foreground
  final fgBytes = img.encodePng(fg);
  File('assets/icon_foreground.png').writeAsBytesSync(fgBytes);
  print('Generated assets/icon_foreground.png');

  // ──────────────────────────────────────────────
  // Background layer (solid color)
  // ──────────────────────────────────────────────
  final bg = img.Image(width: 108, height: 108);
  img.fill(bg, color: img.ColorRgba8(28, 28, 30, 255)); // systemBackground
  final bgBytes = img.encodePng(bg);
  File('assets/icon_background.png').writeAsBytesSync(bgBytes);
  print('Generated assets/icon_background.png');

  // ──────────────────────────────────────────────
  // Combined icon_source (for non-adaptive / splash)
  // ──────────────────────────────────────────────
  final combined = img.Image(width: 108, height: 108);
  img.fill(combined, color: img.ColorRgba8(28, 28, 30, 255));

  // Composite foreground onto background
  for (int y = 0; y < 108; y++) {
    for (int x = 0; x < 108; x++) {
      final fgPixel = fg.getPixel(x, y);
      if (fgPixel.a > 0) {
        combined.setPixelRgba(x, y, fgPixel.r, fgPixel.g, fgPixel.b, fgPixel.a);
      }
    }
  }

  final combinedBytes = img.encodePng(combined);
  File('assets/icon_source.png').writeAsBytesSync(combinedBytes);
  print('Generated assets/icon_source.png');

  print('Done. Run: dart run flutter_launcher_icons');
}

void _fillTriangle(img.Image image, double cx, double py, double hw,
    double by, int r, int g, int b) {
  final baseY = by.toInt();
  for (int y = py.toInt(); y <= baseY; y++) {
    if (y < 0 || y >= image.height) continue;
    final t = (y - py) / (baseY - py);
    final halfWidth = hw * (1 - t);
    final x1 = (cx - halfWidth).round();
    final x2 = (cx + halfWidth).round();
    for (int x = x1; x <= x2; x++) {
      if (x >= 0 && x < image.width) {
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }
}

void _fillCircle(img.Image image, double cx, double cy, double radius,
    int r, int g, int b) {
  for (int y = (cy - radius).round(); y <= (cy + radius).round(); y++) {
    for (int x = (cx - radius).round(); x <= (cx + radius).round(); x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        final dx = x - cx;
        final dy = y - cy;
        if (dx * dx + dy * dy <= radius * radius) {
          image.setPixelRgba(x, y, r, g, b, 200); // slightly transparent
        }
      }
    }
  }
}
