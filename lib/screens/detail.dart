import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/wallpaper.dart';
import '../api/client.dart';
import '../services/download.dart';

class DetailScreen extends StatefulWidget {
  final WallhavenApi api;
  final Wallpaper wallpaper;

  const DetailScreen({
    super.key,
    required this.api,
    required this.wallpaper,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  var _downloading = false;

  String get _filename {
    final uri = Uri.parse(widget.wallpaper.path);
    final basename = uri.pathSegments.last;
    return basename.isNotEmpty ? basename : 'wallkraft-${widget.wallpaper.id}.jpg';
  }

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);

    try {
      final path = await DownloadService.download(
        widget.wallpaper.path,
        _filename,
      );

      if (!mounted) return;
      setState(() => _downloading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null ? 'Saved: $_filename' : 'Download failed'),
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
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed'),
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
          text: 'WallKraft wallpaper: ${widget.wallpaper.url}',
        );
      } else {
        await Share.share('WallKraft wallpaper: ${widget.wallpaper.url}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share failed'),
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
            fontWeight: FontWeight.w500,
          ),
        ),
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
          _infoPanel(),
        ],
      ),
    );
  }

  Widget _infoPanel() {
    final wp = widget.wallpaper;
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
              _infoChip(Icons.aspect_ratio, wp.ratio),
              _infoChip(Icons.photo_size_select_large, wp.resolution),
              _infoChip(Icons.favorite, '${wp.favorites}'),
              _infoChip(Icons.storage, wp.fileSizeFormatted),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _badge(wp.category, _categoryColor(wp.category)),
              const Spacer(),
              _downloadButton(),
            ],
          ),
          if (wp.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: wp.tags.length > 10 ? 10 : wp.tags.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final tag = wp.tags[index];
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

  Widget _downloadButton() {
    if (_downloading) {
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
}
