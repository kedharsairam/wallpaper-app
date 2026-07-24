import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/wallhaven_wallpaper.dart';
import '../services/wallhaven_api.dart';
import '../services/download_service.dart';

class DetailScreen extends StatefulWidget {
  final WallhavenApi api;
  final WallhavenWallpaper wallpaper;

  const DetailScreen({
    super.key,
    required this.api,
    required this.wallpaper,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isDownloading = false;

  String get _filename {
    final uri = Uri.parse(widget.wallpaper.path);
    final basename = uri.pathSegments.last;
    return basename.isNotEmpty ? basename : 'wallhaven-${widget.wallpaper.id}.jpg';
  }

  Future<void> _download() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final path = await DownloadService.download(
        widget.wallpaper.path,
        _filename,
      );

      if (!mounted) return;
      setState(() => _isDownloading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null
              ? 'Downloaded: $_filename'
              : 'Download started'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: path != null
              ? SnackBarAction(
                  label: 'Share',
                  onPressed: () => _share(path),
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _share(String? path) async {
    try {
      if (path != null) {
        await Share.shareXFiles(
          [XFile(path)],
          text: 'Wallhaven wallpaper: ${widget.wallpaper.url}',
        );
      } else {
        await Share.share('Wallhaven wallpaper: ${widget.wallpaper.url}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.wallpaper.id,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'GoogleFonts',
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white70),
            tooltip: 'Share',
            onPressed: () => _share(DownloadService.lastDownloadPath),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.white70),
            tooltip: 'Open in browser',
            onPressed: () => _openInBrowser(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.wallpaper.path,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  ),
                  errorWidget: (context, url, error) => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white38, size: 64),
                      SizedBox(height: 8),
                      Text('Failed to load image',
                          style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildInfoPanel(context),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoChip(Icons.aspect_ratio, widget.wallpaper.ratio),
              _infoChip(Icons.photo_size_select_large, widget.wallpaper.resolution),
              _infoChip(Icons.favorite, '${widget.wallpaper.favorites}'),
              _infoChip(Icons.storage, widget.wallpaper.fileSizeFormatted),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _badge(widget.wallpaper.category, _categoryColor(widget.wallpaper.category)),
              const SizedBox(width: 8),
              _badge(widget.wallpaper.purity, _purityColor(widget.wallpaper.purity)),
              const Spacer(),
              _buildDownloadButton(),
            ],
          ),
          if (widget.wallpaper.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.wallpaper.tags.length > 10
                    ? 10
                    : widget.wallpaper.tags.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final tag = widget.wallpaper.tags[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tag.name,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (_isDownloading) {
      return const SizedBox(
        width: 120,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.blueAccent,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _download,
      icon: const Icon(Icons.download, size: 18),
      label: const Text('Download'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'anime':
        return Colors.purpleAccent;
      case 'people':
        return Colors.orangeAccent;
      default:
        return Colors.greenAccent;
    }
  }

  Color _purityColor(String purity) {
    switch (purity) {
      case 'nsfw':
        return Colors.redAccent;
      case 'sketchy':
        return Colors.amberAccent;
      default:
        return Colors.greenAccent;
    }
  }

  void _openInBrowser(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URL: ${widget.wallpaper.url}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
