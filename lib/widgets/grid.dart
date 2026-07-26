import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:share_plus/share_plus.dart';
import '../models/wallpaper.dart';
import '../services/download_manager.dart';
import '../theme.dart';
import '../helpers/responsive.dart';

/// Masonry wallpaper grid shared across Browse, Favorites, and Downloads.
///
/// Every image is decoded at display size via [memCacheWidth] to prevent
/// OOM crashes on mid-range devices. Each tile is wrapped in
/// [RepaintBoundary] for scroll performance.
class WallpaperGrid extends StatelessWidget {
  final List<Wallpaper> wallpapers;
  final bool isLoadingMore;
  final bool hasMore;
  final ScrollController? scrollController;
  final void Function(Wallpaper) onTap;

  const WallpaperGrid({
    super.key,
    required this.wallpapers,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.scrollController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = wallpapers.length + (isLoadingMore ? 1 : 0);

    return MasonryGridView.extent(
      controller: scrollController,
      padding: const EdgeInsets.all(AppTheme.spacing8),
      maxCrossAxisExtent: 190,
      crossAxisSpacing: AppTheme.spacing8,
      mainAxisSpacing: AppTheme.spacing8,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= wallpapers.length) {
          return const _LoadMoreIndicator();
        }
        return RepaintBoundary(
          child: _MasonryTile(
            wallpaper: wallpapers[index],
            onTap: () => onTap(wallpapers[index]),
          ),
        );
      },
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class _MasonryTile extends StatefulWidget {
  final Wallpaper wallpaper;
  final VoidCallback onTap;

  const _MasonryTile({required this.wallpaper, required this.onTap});

  @override
  State<_MasonryTile> createState() => _MasonryTileState();
}

class _MasonryTileState extends State<_MasonryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _tapAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _tapAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _showContextMenu(BuildContext context) {
    final w = widget.wallpaper;
    final renderBox = context.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + 50,
        offset.dy + 20,
        offset.dx + 200,
        offset.dy + 100,
      ),
      items: [
        const PopupMenuItem(value: 'detail', child: Text('Open Detail')),
        const PopupMenuItem(value: 'download', child: Text('Download')),
        const PopupMenuItem(value: 'share', child: Text('Share')),
        const PopupMenuItem(value: 'copy', child: Text('Copy Link')),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'detail':
          widget.onTap();
        case 'download':
          widget.onTap(); // Navigate to detail for download
        case 'share':
          _onContextShare(w);
        case 'copy':
          _onContextCopyLink(w);
      }
    });
  }

  void _onContextShare(Wallpaper w) async {
    try {
      // Download the file first, then share it.
      final path = await DownloadManager.instance.download(w);
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Wallpaper via WallKraft',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  void _onContextCopyLink(Wallpaper w) async {
    try {
      await Clipboard.setData(ClipboardData(text: w.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copied')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copy failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.wallpaper;
    final aspectRatio =
        (w.dimensionX > 0 && w.dimensionY > 0)
            ? w.dimensionX / w.dimensionY
            : 1.0;

    final tileWidth = Responsive.gridTileWidth(context);

    return GestureDetector(
      onTap: widget.onTap,
      onSecondaryTap: () => _showContextMenu(context),
      onLongPress: () => _showContextMenu(context),
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) => _tapController.reverse(),
      onTapCancel: () => _tapController.reverse(),
      child: AnimatedBuilder(
        animation: _tapAnimation,
        builder: (context, child) => Transform.scale(
          scale: _tapAnimation.value,
          child: child,
        ),
        child: Semantics(
        label: 'Wallpaper ${w.resolution}',
        child: Hero(
          tag: 'wallpaper-${w.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl:
                        w.thumbnailOriginal ?? w.thumbnail,
                    fit: BoxFit.cover,
                    memCacheWidth: tileWidth,
                    placeholder: (_, _) => const _TilePlaceholder(),
                    errorWidget: (_, _, _) => const _TileError(),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing8,
                        vertical: 6,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xCC000000),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite,
                              size: 12, color: Color(0xCCFFFFFF)),
                          const SizedBox(width: 4),
                          Text(
                            _formatCount(w.favorites),
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            w.resolution,
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

class _TilePlaceholder extends StatelessWidget {
  const _TilePlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        color: isDark ? AppTheme.tilePlaceholder : AppTheme.lightTilePlaceholder);
  }
}

class _TileError extends StatelessWidget {
  const _TileError();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppTheme.tilePlaceholder : AppTheme.lightTilePlaceholder,
      child: Center(
        child: Icon(Icons.broken_image,
            size: 20,
            color:
                isDark ? AppTheme.tertiaryLabel : AppTheme.lightTertiaryLabel),
      ),
    );
  }
}
