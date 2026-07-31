// Apple-style icon: sunset mountain landscape — like the macOS/iOS wallpaper picker.
// Run: dart tools/generate_icon.dart
// Then: dart run flutter_launcher_icons

import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

const _size = 512;

void main() {
  final imgOut = img.Image(width: _size, height: _size, numChannels: 4);

  // ── Sky: warm-to-cool gradient ──
  _drawVerticalGradient(imgOut,
    top: img.ColorRgba8(0xFF, 0x7B, 0x4F, 255),     // warm coral
    mid: img.ColorRgba8(0xE0, 0x4D, 0x5A, 255),     // rose
    bottom: img.ColorRgba8(0x1A, 0x1A, 0x3E, 255),  // deep navy
  );

  // ── Sun glow (large, faint) ──
  _drawFilledCircle(imgOut, _size * 0.70, _size * 0.30, _size * 0.18,
    img.ColorRgba8(255, 220, 150, 25));

  // ── Sun (warm golden) ──
  _drawFilledCircle(imgOut, _size * 0.70, _size * 0.30, _size * 0.09,
    img.ColorRgba8(255, 235, 180, 240));

  // ── Mountain silhouette ──
  // Clean geometric mountain with 3 peaks, spanning the bottom
  final mountainColor = img.ColorRgba8(18, 18, 42, 255);

  // Main peak (centered, tallest)
  // Secondary peak (left, mid-height)
  // Small peak (far right, lowest)
  final mountainPoints = <(double, double)>[
    (0.0, _size * 0.95),              // bottom-left start
    (_size * 0.08, _size * 0.65),    // left base
    (_size * 0.12, _size * 0.60),    // left slope start
    (_size * 0.20, _size * 0.42),    // left peak
    (_size * 0.28, _size * 0.55),    // left valley
    (_size * 0.35, _size * 0.48),    // mid slope
    (_size * 0.50, _size * 0.25),    // main peak (tallest)
    (_size * 0.58, _size * 0.40),    // right slope
    (_size * 0.65, _size * 0.45),    // right valley
    (_size * 0.72, _size * 0.35),    // right peak
    (_size * 0.80, _size * 0.52),    // right slope end
    (_size * 0.88, _size * 0.50),    // small rise
    (_size * 0.95, _size * 0.55),    // right base
    (_size * 1.0, _size * 0.58),     // bottom-right
    (_size * 1.0, _size * 1.0),      // bottom-right corner
    (0.0, _size * 1.0),              // bottom-left corner
  ];

  // Draw mountain as filled polygon
  _drawFilledPolygon(imgOut, mountainPoints, mountainColor);

  // Subtle snow cap on main peak
  final snowColor = img.ColorRgba8(255, 255, 255, 30);
  final snowPoints = <(double, double)>[
    (_size * 0.44, _size * 0.32),
    (_size * 0.50, _size * 0.25),
    (_size * 0.56, _size * 0.35),
    (_size * 0.52, _size * 0.33),
    (_size * 0.50, _size * 0.30),
    (_size * 0.48, _size * 0.33),
  ];
  _drawFilledPolygon(imgOut, snowPoints, snowColor);

  // ── Save combined ──
  File('assets/icon_source.png').writeAsBytesSync(img.encodePng(imgOut));
  print('Generated assets/icon_source.png');

  // ── Background: sky only ──
  final bg = img.Image(width: _size, height: _size, numChannels: 4);
  _drawVerticalGradient(bg,
    top: img.ColorRgba8(0xFF, 0x7B, 0x4F, 255),
    mid: img.ColorRgba8(0xE0, 0x4D, 0x5A, 255),
    bottom: img.ColorRgba8(0x1A, 0x1A, 0x3E, 255),
  );
  File('assets/icon_background.png').writeAsBytesSync(img.encodePng(bg));
  print('Generated assets/icon_background.png');

  // ── Foreground: sun + mountain on transparent ──
  final fg = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(fg, color: img.ColorRgba8(0, 0, 0, 0));

  _drawFilledCircle(fg, _size * 0.70, _size * 0.30, _size * 0.18,
    img.ColorRgba8(255, 220, 150, 25));
  _drawFilledCircle(fg, _size * 0.70, _size * 0.30, _size * 0.09,
    img.ColorRgba8(255, 235, 180, 240));
  _drawFilledPolygon(fg, mountainPoints, mountainColor);
  _drawFilledPolygon(fg, snowPoints, snowColor);

  File('assets/icon_foreground.png').writeAsBytesSync(img.encodePng(fg));
  print('Generated assets/icon_foreground.png');

  print('Done. Run: dart run flutter_launcher_icons');
}

void _drawVerticalGradient(img.Image image,
    {required img.ColorRgba8 top, img.ColorRgba8? mid, required img.ColorRgba8 bottom}) {
  final h = image.height;
  final midY = h ~/ 2;
  for (int y = 0; y < h; y++) {
    double t;
    img.ColorRgba8 cTop, cBottom;
    if (mid != null && y < midY) {
      t = (midY > 0) ? y / midY : 0;
      cTop = top;
      cBottom = mid;
    } else if (mid != null) {
      t = (h > midY) ? (y - midY) / (h - midY) : 0;
      cTop = mid;
      cBottom = bottom;
    } else {
      t = (h > 1) ? y / (h - 1) : 0;
      cTop = top;
      cBottom = bottom;
    }
    final r = (cTop.r + (cBottom.r - cTop.r) * t).round().clamp(0, 255);
    final g = (cTop.g + (cBottom.g - cTop.g) * t).round().clamp(0, 255);
    final b = (cTop.b + (cBottom.b - cTop.b) * t).round().clamp(0, 255);
    for (int x = 0; x < image.width; x++) {
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
}

void _drawFilledCircle(img.Image image, double cx, double cy, double r, img.ColorRgba8 color) {
  for (int y = (cy - r - 1).floor().clamp(0, image.height - 1); y <= (cy + r + 1).ceil().clamp(0, image.height - 1); y++) {
    for (int x = (cx - r - 1).floor().clamp(0, image.width - 1); x <= (cx + r + 1).ceil().clamp(0, image.width - 1); x++) {
      final dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
      final a = (r + 0.5 - dist).clamp(0.0, 1.0) * (color.a / 255.0);
      if (a > 0) {
        final existing = image.getPixel(x, y);
        final dstA = existing.a / 255.0;
        final outA = a + dstA * (1 - a);
        if (outA > 0) {
          image.setPixelRgba(x, y,
            ((color.r * a + existing.r * dstA * (1 - a)) / outA).round().clamp(0, 255),
            ((color.g * a + existing.g * dstA * (1 - a)) / outA).round().clamp(0, 255),
            ((color.b * a + existing.b * dstA * (1 - a)) / outA).round().clamp(0, 255),
            (outA * 255).round().clamp(0, 255),
          );
        }
      }
    }
  }
}

void _drawFilledPolygon(img.Image image, List<(double, double)> points, img.ColorRgba8 color) {
  var minX = double.infinity, maxX = double.negativeInfinity;
  var minY = double.infinity, maxY = double.negativeInfinity;
  for (final p in points) {
    if (p.$1 < minX) minX = p.$1;
    if (p.$1 > maxX) maxX = p.$1;
    if (p.$2 < minY) minY = p.$2;
    if (p.$2 > maxY) maxY = p.$2;
  }

  for (int py = minY.floor().clamp(0, image.height - 1); py <= maxY.ceil().clamp(0, image.height - 1); py++) {
    for (int px = minX.floor().clamp(0, image.width - 1); px <= maxX.ceil().clamp(0, image.width - 1); px++) {
      if (_pointInPolygon(px.toDouble(), py.toDouble(), points)) {
        final existing = image.getPixel(px, py);
        final srcA = color.a / 255.0;
        final dstA = existing.a / 255.0;
        final outA = srcA + dstA * (1 - srcA);
        if (outA > 0) {
          image.setPixelRgba(px, py,
            ((color.r * srcA + existing.r * dstA * (1 - srcA)) / outA).round().clamp(0, 255),
            ((color.g * srcA + existing.g * dstA * (1 - srcA)) / outA).round().clamp(0, 255),
            ((color.b * srcA + existing.b * dstA * (1 - srcA)) / outA).round().clamp(0, 255),
            (outA * 255).round().clamp(0, 255),
          );
        }
      }
    }
  }
}

bool _pointInPolygon(double px, double py, List<(double, double)> poly) {
  var inside = false;
  for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    if (((poly[i].$2 > py) != (poly[j].$2 > py)) &&
        (px < (poly[j].$1 - poly[i].$1) * (py - poly[i].$2) / (poly[j].$2 - poly[i].$2) + poly[i].$1)) {
      inside = !inside;
    }
  }
  return inside;
}
