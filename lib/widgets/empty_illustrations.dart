import 'package:flutter/material.dart';
import '../theme.dart';

/// Which empty-state illustration to show.
enum Illustration {
  favorites,
  downloads,
  search,
  browse,
}

/// Custom vector illustration widget for empty states.
///
/// Each [Illustration] type draws a unique, minimal vector graphic
/// using [CustomPainter]. The illustrations adapt to the current
/// theme brightness via [color].
class EmptyIllustration extends StatelessWidget {
  final Illustration type;
  final double size;
  final Color color;

  const EmptyIllustration({
    super.key,
    required this.type,
    this.size = 120,
    this.color = const Color(0x4DEBEBF5),
  });

  @override
  Widget build(BuildContext context) {
    final paintColor = AppTheme.of(context, color, const Color(0x4D3C3C43));
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IllustrationPainter(type, color: paintColor),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final Illustration type;
  final Color color;

  _IllustrationPainter(this.type, {required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case Illustration.favorites:
        _drawHeart(canvas, size);
      case Illustration.downloads:
        _drawDownload(canvas, size);
      case Illustration.search:
        _drawSearch(canvas, size);
      case Illustration.browse:
        _drawBrowse(canvas, size);
    }
  }

  void _drawHeart(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width / 2;

    // Heart curve using cubic beziers
    final path = Path();
    path.moveTo(cx, cy + s * 0.35);
    path.cubicTo(
      cx - s * 0.15, cy - s * 0.15, // control 1
      cx - s * 0.8, cy - s * 0.05, // control 2
      cx, cy - s * 0.4, // end (top center)
    );
    path.cubicTo(
      cx + s * 0.8, cy - s * 0.05, // control 1
      cx + s * 0.15, cy - s * 0.15, // control 2
      cx, cy + s * 0.35, // end (bottom)
    );
    canvas.drawPath(path, paint);

    // Small "x" or dash to indicate empty
    final xPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - s * 0.15, cy - s * 0.05),
      Offset(cx + s * 0.15, cy + s * 0.15),
      xPaint,
    );
    canvas.drawLine(
      Offset(cx + s * 0.15, cy - s * 0.05),
      Offset(cx - s * 0.15, cy + s * 0.15),
      xPaint,
    );
  }

  void _drawDownload(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width / 2;

    // Cloud shape at top
    final cloudPath = Path();
    cloudPath.moveTo(cx - s * 0.5, cy - s * 0.15);
    cloudPath.quadraticBezierTo(
      cx - s * 0.7, cy - s * 0.3,
      cx - s * 0.3, cy - s * 0.4,
    );
    cloudPath.quadraticBezierTo(
      cx - s * 0.3, cy - s * 0.6,
      cx, cy - s * 0.5,
    );
    cloudPath.quadraticBezierTo(
      cx + s * 0.3, cy - s * 0.6,
      cx + s * 0.3, cy - s * 0.4,
    );
    cloudPath.quadraticBezierTo(
      cx + s * 0.7, cy - s * 0.3,
      cx + s * 0.5, cy - s * 0.15,
    );
    cloudPath.close();
    canvas.drawPath(cloudPath, paint);

    // Arrow pointing down
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy + s * 0.1),
      Offset(cx, cy + s * 0.45),
      arrowPaint,
    );
    // Arrowhead
    canvas.drawLine(
      Offset(cx - s * 0.15, cy + s * 0.3),
      Offset(cx, cy + s * 0.45),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(cx + s * 0.15, cy + s * 0.3),
      Offset(cx, cy + s * 0.45),
      arrowPaint,
    );

    // Ground line
    final groundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - s * 0.5, cy + s * 0.55),
      Offset(cx + s * 0.5, cy + s * 0.55),
      groundPaint,
    );
  }

  void _drawSearch(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width / 2;

    // Magnifying glass circle
    canvas.drawCircle(
      Offset(cx - s * 0.08, cy - s * 0.12),
      s * 0.3,
      paint,
    );

    // Handle
    canvas.drawLine(
      Offset(cx + s * 0.15, cy + s * 0.1),
      Offset(cx + s * 0.42, cy + s * 0.38),
      paint,
    );

    // "No results" underscore with zigzag
    final noPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - s * 0.3, cy + s * 0.5),
      Offset(cx + s * 0.3, cy + s * 0.5),
      noPaint,
    );
    // Small zigzag line through the glass to indicate "nothing"
    canvas.drawLine(
      Offset(cx - s * 0.25, cy - s * 0.12),
      Offset(cx + s * 0.08, cy + s * 0.08),
      noPaint,
    );
  }

  void _drawBrowse(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width / 2;

    // Landscape / gallery frame
    final framePath = Path();
    framePath.moveTo(cx - s * 0.5, cy - s * 0.45);
    framePath.lineTo(cx + s * 0.5, cy - s * 0.45);
    framePath.lineTo(cx + s * 0.5, cy + s * 0.45);
    framePath.lineTo(cx - s * 0.5, cy + s * 0.45);
    framePath.close();
    canvas.drawPath(framePath, paint);

    // Mountain shape inside
    final mountainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final mountainPath = Path();
    mountainPath.moveTo(cx - s * 0.35, cy + s * 0.3);
    mountainPath.lineTo(cx - s * 0.1, cy - s * 0.1);
    mountainPath.lineTo(cx + s * 0.15, cy + s * 0.05);
    mountainPath.lineTo(cx + s * 0.3, cy - s * 0.2);
    mountainPath.lineTo(cx + s * 0.42, cy + s * 0.3);
    mountainPath.close();
    canvas.drawPath(mountainPath, mountainPaint);

    // Small circle (sun)
    canvas.drawCircle(
      Offset(cx + s * 0.3, cy - s * 0.3),
      s * 0.08,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}
