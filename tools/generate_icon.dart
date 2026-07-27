// Generates the app icon: a clean "W" monogram on a dark background.
// Run: dart tools/generate_icon.dart
// Then: dart run flutter_launcher_icons

import 'dart:io';
import 'dart:math' show sqrt;
import 'package:image/image.dart' as img;

/// Standard resolution for Android adaptive icons (108x108).
const _size = 108;

void main() {
  // Background layer: solid deep navy
  final bg = img.Image(width: _size, height: _size);
  img.fill(bg, color: img.ColorRgba8(0x1A, 0x1A, 0x3E, 255));
  final bgBytes = img.encodePng(bg);
  File('assets/icon_background.png').writeAsBytesSync(bgBytes);
  print('Generated assets/icon_background.png');

  // Foreground layer: clean "W" monogram in white
  final fg = img.Image(width: _size, height: _size);
  img.fill(fg, color: img.ColorRgba8(0, 0, 0, 0));
  _drawWMonogram(fg, _size);
  final fgBytes = img.encodePng(fg);
  File('assets/icon_foreground.png').writeAsBytesSync(fgBytes);
  print('Generated assets/icon_foreground.png');

  // Combined icon_source (foreground on background)
  final combined = img.Image(width: _size, height: _size);
  for (int y = 0; y < _size; y++) {
    for (int x = 0; x < _size; x++) {
      final fgp = fg.getPixel(x, y);
      final bgp = bg.getPixel(x, y);
      if (fgp.a > 0) {
        combined.setPixelRgba(x, y, fgp.r, fgp.g, fgp.b, fgp.a);
      } else {
        combined.setPixelRgba(x, y, bgp.r, bgp.g, bgp.b, bgp.a);
      }
    }
  }
  final combinedBytes = img.encodePng(combined);
  File('assets/icon_source.png').writeAsBytesSync(combinedBytes);
  print('Generated assets/icon_source.png');
  print('Done. Run: dart run flutter_launcher_icons');
}

void _drawWMonogram(img.Image image, int size) {
  final cx = size / 2;
  final cy = size / 2;
  final s = size * 0.30;
  final w = s * 0.22;

  _drawThickLine(image, cx - s, cy + s * 0.5, cx - s * 0.35, cy - s * 0.6, w);
  _drawThickLine(image, cx - s * 0.35, cy - s * 0.6, cx, cy - s * 0.15, w);
  _drawThickLine(image, cx, cy - s * 0.15, cx + s * 0.35, cy - s * 0.6, w);
  _drawThickLine(image, cx + s * 0.35, cy - s * 0.6, cx + s, cy + s * 0.5, w);
}

void _drawThickLine(
    img.Image image, double x0, double y0, double x1, double y1, double w) {
  final dx = x1 - x0;
  final dy = y1 - y0;
  final len = dx * dx + dy * dy;
  if (len < 0.01) return;
  final invLen = 1.0 / sqrt(len);
  final px = -dy * invLen;
  final py = dx * invLen;
  final hw = w / 2;

  final corners = <({double x, double y})>[
    (x: x0 + px * hw, y: y0 + py * hw),
    (x: x0 - px * hw, y: y0 - py * hw),
    (x: x1 - px * hw, y: y1 - py * hw),
    (x: x1 + px * hw, y: y1 + py * hw),
  ];

  final minX = corners
      .map((c) => c.x)
      .reduce((a, b) => a < b ? a : b)
      .floor()
      .clamp(0, image.width - 1);
  final maxX = corners
      .map((c) => c.x)
      .reduce((a, b) => a > b ? a : b)
      .ceil()
      .clamp(0, image.width - 1);
  final minY = corners
      .map((c) => c.y)
      .reduce((a, b) => a < b ? a : b)
      .floor()
      .clamp(0, image.height - 1);
  final maxY = corners
      .map((c) => c.y)
      .reduce((a, b) => a > b ? a : b)
      .ceil()
      .clamp(0, image.height - 1);

  for (int y = minY; y <= maxY; y++) {
    for (int x = minX; x <= maxX; x++) {
      if (_pointInConvexPolygon(
          x.toDouble(), y.toDouble(), corners)) {
        image.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
  }
}

bool _pointInConvexPolygon(
    double px, double py, List<({double x, double y})> poly) {
  var pos = false;
  var neg = false;
  for (int i = 0; i < poly.length; i++) {
    final j = (i + 1) % poly.length;
    final cross = (poly[j].x - poly[i].x) * (py - poly[i].y) -
        (poly[j].y - poly[i].y) * (px - poly[i].x);
    if (cross > 0) pos = true;
    if (cross < 0) neg = true;
    if (pos && neg) return false;
  }
  return true;
}
