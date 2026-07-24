import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: wallpapers.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= wallpapers.length) {
          return const _LoadingTile();
        }
        return _WallpaperTile(
          wallpaper: wallpapers[index],
          onTap: () => onTap(wallpapers[index]),
        );
      },
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  final WallhavenWallpaper wallpaper;
  final VoidCallback onTap;

  const _WallpaperTile({required this.wallpaper, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: wallpaper.thumbnail,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: const Color(0xFF2A2A2A),
                highlightColor: const Color(0xFF3A3A3A),
                child: Container(color: const Color(0xFF2A2A2A)),
              ),
              errorWidget: (context, url, error) => Container(
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
                    _iconText(
                      Icons.favorite,
                      '${wallpaper.favorites}',
                    ),
                    const Spacer(),
                    _iconText(
                      Icons.aspect_ratio,
                      wallpaper.ratio,
                    ),
                  ],
                ),
              ),
            ),

          ],
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
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
