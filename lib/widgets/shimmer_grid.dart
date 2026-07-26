import 'package:flutter/material.dart';
import '../theme.dart';

/// A shimmer placeholder grid shown while wallpapers are loading.
///
/// Mimics the masonry layout with two columns of animated gradient tiles.
class ShimmerGrid extends StatefulWidget {
  const ShimmerGrid({super.key});

  @override
  State<ShimmerGrid> createState() => _ShimmerGridState();
}

class _ShimmerGridState extends State<ShimmerGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildColumn(0.7, 0.9, 0.5, 0.8)),
                const SizedBox(width: 8),
                Expanded(child: _buildColumn(0.5, 0.7, 0.6, 0.6)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn(double h1, double h2, double h3, double h4) {
    return Column(
      children: [
        _shimmerTile(h1),
        const SizedBox(height: 8),
        _shimmerTile(h2),
        const SizedBox(height: 8),
        _shimmerTile(h3),
        const SizedBox(height: 8),
        _shimmerTile(h4),
      ],
    );
  }

  Widget _shimmerTile(double heightFactor) {
    return AspectRatio(
      aspectRatio: 1.0 / heightFactor,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment(-1.0 + _animation.value, 0),
                end: Alignment(1.0 + _animation.value, 0),
                colors: [
                  AppTheme.secondarySystemBackground,
                  AppTheme.tertiarySystemBackground.withValues(alpha: 0.5),
                  AppTheme.secondarySystemBackground,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
