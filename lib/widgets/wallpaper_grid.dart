import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import '../models/wallhaven_wallpaper.dart';

class WallpaperGrid extends StatelessWidget {
  final List<WallhavenWallpaper> wallpapers;
  final bool isLoadingMore;
  final bool hasMore;
  final ScrollController scrollController;
  final void Function(WallhavenWallpaper) onTap;

  const WallpaperGrid({
    super.key,
    required this.wallpapers,
    required this.isLoadingMore,
    required this.hasMore,
    required this.scrollController,
    required this.onTap,
  });

  int _columnCount(double width) {
    if (width > 1200) return 5;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery for reliable viewport width.
    final viewWidth = MediaQuery.of(context).size.width;
    final columns = _columnCount(viewWidth);
    // Calculate column width the same way MasonryGridView does internally:
    //   stride = (totalWidth + crossAxisSpacing) / columns
    //   columnWidth = stride - crossAxisSpacing
    const edgePadding = 8.0 * 2;      // left + right padding
    const spacing = 8.0;
    final availableWidth = viewWidth - edgePadding;
    final stride = (availableWidth + spacing) / columns;
    final columnWidth = stride - spacing;

    return MasonryGridView.count(
      controller: scrollController,
      padding: const EdgeInsets.all(8),
      crossAxisCount: columns,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      itemCount: wallpapers.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= wallpapers.length) {
          return _LoadingTile(columnWidth: columnWidth);
        }
        return _WallpaperTile(
          wallpaper: wallpapers[index],
          columnWidth: columnWidth,
          onTap: () => onTap(wallpapers[index]),
        );
      },
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  final WallhavenWallpaper wallpaper;
  final double columnWidth;
  final VoidCallback onTap;

  const _WallpaperTile({
    required this.wallpaper,
    required this.columnWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed 3:2 aspect ratio — matches Wallhaven's small thumbnail format
    // (300×200) and gives a modest 19% height boost over 16:9. The ~16%
    // side crop from BoxFit.cover is mild enough that it only trims edges
    // (safe for centered wallpaper compositions) while making tiles feel
    // more substantial on all devices.
    const tileAspectRatio = 3.0 / 2.0;
    final height = columnWidth / tileAspectRatio;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: columnWidth,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: const Color(0xFF1A1A1A),
            child: Stack(
            children: [
              // Full-size image loaded directly — no scaling surprises.
              CachedNetworkImage(
                imageUrl: wallpaper.thumbnailLarge ?? wallpaper.thumbnail,
                width: columnWidth,
                height: height,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: const Color(0xFF2A2A2A),
                  highlightColor: const Color(0xFF3A3A3A),
                  child: Container(
                    width: columnWidth,
                    height: height,
                    color: const Color(0xFF2A2A2A),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: columnWidth,
                  height: height,
                  color: const Color(0xFF1A1A1A),
                  child: const Icon(Icons.broken_image, color: Colors.white24),
                ),
              ),
              // Gradient overlay for text
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      _iconText(Icons.favorite, '${wallpaper.favorites}'),
                      const Spacer(),
                      _iconText(Icons.aspect_ratio, wallpaper.ratio),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 12),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _LoadingTile extends StatelessWidget {
  final double columnWidth;

  const _LoadingTile({required this.columnWidth});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: Container(
        width: columnWidth,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
