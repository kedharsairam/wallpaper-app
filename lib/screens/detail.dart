import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/wallpaper.dart';
import '../services/database.dart';
import '../services/wallpaper_setter.dart';
import '../theme.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Wallpaper? _wallpaper;
  var _isLoading = true;
  String? _error;
  var _chromeVisible = true;
  var _isFavorite = false;
  var _heartScale = 1.0;
  var _isDownloading = false;
  var _downloadProgress = 0.0;
  final TransformationController _transformController =
      TransformationController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wallpaper == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _wallpaper = args['wallpaper'] as Wallpaper?;
        if (_wallpaper != null) {
          _isLoading = false;
          _checkFavorite();
        } else {
          _error = 'Wallpaper not found';
          _isLoading = false;
        }
      }
    }
  }

  Future<void> _checkFavorite() async {
    if (_wallpaper == null) return;
    final fav = await WallKraftDatabase.isFavorite(_wallpaper!.id);
    if (mounted) setState(() => _isFavorite = fav);
  }

  void _toggleFavorite() async {
    if (_wallpaper == null) return;
    HapticFeedback.lightImpact();

    // Optimistic UI update + bounce
    setState(() {
      _isFavorite = !_isFavorite;
      _heartScale = 1.3;
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _heartScale = 1.0);
    });

    // Persist
    if (_isFavorite) {
      await WallKraftDatabase.addFavorite(_wallpaper!);
    } else {
      await WallKraftDatabase.removeFavorite(_wallpaper!.id);
    }
  }

  Future<void> _download() async {
    if (_wallpaper == null || _isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'wallkraft-${_wallpaper!.id}.jpg';
      final file = File('${dir.path}/$fileName');

      final request = await HttpClient().getUrl(Uri.parse(_wallpaper!.path));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      var receivedBytes = 0;
      final sink = file.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && mounted) {
          setState(() => _downloadProgress = receivedBytes / totalBytes);
        }
      }

      await sink.close();

      await WallKraftDatabase.recordDownload(_wallpaper!.id, file.path);

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 1.0;
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _setWallpaper() async {
    if (_wallpaper == null) return;

    final which = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spacing16, AppTheme.spacing20, AppTheme.spacing16, 32),
        decoration: const BoxDecoration(
          color: AppTheme.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryLabel,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
            const Text('Set Wallpaper', style: AppTheme.title3),
            const SizedBox(height: AppTheme.spacing16),
            ListTile(
              leading: const Icon(Icons.home_outlined, color: AppTheme.systemBlue),
              title: const Text('Home Screen'),
              onTap: () => Navigator.pop(ctx, 'home'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: AppTheme.systemBlue),
              title: const Text('Lock Screen'),
              onTap: () => Navigator.pop(ctx, 'lock'),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android, color: AppTheme.systemBlue),
              title: const Text('Both'),
              onTap: () => Navigator.pop(ctx, 'both'),
            ),
          ],
        ),
      ),
    );

    if (which == null || !mounted) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/wallkraft-${_wallpaper!.id}.jpg');
      if (!await file.exists()) {
        await _download();
      }
      if (await file.exists()) {
        HapticFeedback.mediumImpact();
        final success =
            await WallpaperSetter.setWallpaper(file.path, which: which);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Wallpaper set' : 'Failed to set wallpaper'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Set wallpaper failed: $e')),
        );
      }
    }
  }

  Future<void> _share() async {
    if (_wallpaper == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/wallkraft-${_wallpaper!.id}.jpg');
      if (!await file.exists()) {
        await _download();
      }
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Wallpaper via WallKraft',
        );
      }
    } catch (_) {}
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
  }

  void _handleDoubleTapDown(Offset localPosition) {
    final currentScale = _transformController.value.getMaxScaleOnAxis();

    if (currentScale < 1.5) {
      // Zoom to 2x centered on the double-tap point
      final tapX = localPosition.dx;
      final tapY = localPosition.dy;
      _transformController.value = Matrix4(
        2.0, 0.0, 0.0, 0.0,
        0.0, 2.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        -tapX, -tapY, 0.0, 1.0,
      );
    } else {
      // Zoom out to 1x
      _transformController.value = Matrix4.identity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.equal, control: true): () =>
            _transformController.value = Matrix4.diagonal3Values(3.0, 3.0, 1.0),
        SingleActivator(LogicalKeyboardKey.minus, control: true): () =>
            _transformController.value = Matrix4.identity(),
        SingleActivator(LogicalKeyboardKey.digit0, control: true): () =>
            _transformController.value = Matrix4.identity(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      backgroundColor: Colors.black,
      appBar: _chromeVisible
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.7),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.label),
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: AnimatedScale(
                    scale: _heartScale,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_outline,
                    color: _isFavorite
                        ? AppTheme.favoriteRed
                        : AppTheme.secondaryLabel,
                  ),
                  ),
                  tooltip: _isFavorite ? 'Unfavorite' : 'Favorite',
                  onPressed: _toggleFavorite,
                ),
              ],
            )
          : null,
      body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppTheme.secondaryLabel,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_error != null || _wallpaper == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                size: 48, color: AppTheme.tertiaryLabel),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Wallpaper not found',
              style: const TextStyle(color: AppTheme.secondaryLabel),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleChrome,
      child: Column(
        children: [
          // Image area
          Expanded(
            child: Hero(
              tag: 'wallpaper-${_wallpaper!.id}',
              child: GestureDetector(
                onDoubleTapDown: (details) =>
                    _handleDoubleTapDown(details.localPosition),
                child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 1.0,
              maxScale: 5.0,
              child: CachedNetworkImage(
                imageUrl: _wallpaper!.path,
                fit: BoxFit.contain,
                // No memCacheWidth — user came here to see full quality.
                // 80MB global cache cap prevents runaway memory.
                placeholder: (_, _) => const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppTheme.secondaryLabel,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image,
                      size: 48, color: AppTheme.tertiaryLabel),
                ),
              ),
            ),
          ),
        ),
        ),

          // Metadata panel (hidden with chrome)
          if (_chromeVisible) _buildMetadata(),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    final w = _wallpaper!;
    return Container(
      color: AppTheme.systemBackground,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow('Resolution', w.resolution),
            const Divider(),
            _infoRow('File Size', w.fileSizeFormatted),
            const Divider(),
            _infoRow('Favorites', '♡ ${_formatCount(w.favorites)}'),
            const Divider(),
            _infoRow('Category', w.category),
            const SizedBox(height: AppTheme.spacing12),
            if (_isDownloading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
                child: LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: AppTheme.secondarySystemBackground,
                  color: AppTheme.systemBlue,
                  minHeight: 3,
                ),
              ),
            _actionButton(
              _isDownloading
                  ? 'Downloading ${(_downloadProgress * 100).round()}%'
                  : 'Download Wallpaper',
              onTap: _isDownloading ? null : _download,
            ),
            _actionButton('Set Wallpaper', onTap: _setWallpaper),
            _actionButton('Share', onTap: _share),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                  color: AppTheme.secondaryLabel,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                )),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: AppTheme.label, fontSize: 15),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String title, {VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: AppTheme.spacing44,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor:
              onTap != null ? AppTheme.systemBlue : AppTheme.tertiaryLabel,
          padding: EdgeInsets.zero,
        ),
        child: Text(title),
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
