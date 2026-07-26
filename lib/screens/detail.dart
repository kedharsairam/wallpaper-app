import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/wallpaper.dart';
import '../services/database.dart';
import '../services/download_manager.dart';
import '../services/wallpaper_setter.dart';
import '../theme.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
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
  var _imageError = false;
  var _imageLoadAttempt = 0;
  late AnimationController _chromeAnimController;
  late Animation<double> _chromeOpacity;

  @override
  void initState() {
    super.initState();
    _chromeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..value = 1.0;
    _chromeOpacity = _chromeAnimController;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wallpaper == null) {
      final route = ModalRoute.of(context);
      if (route == null) return; // Not attached yet.
      final args = route.settings.arguments as Map<String, dynamic>?;
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

  @override
  void dispose() {
    _chromeAnimController.dispose();
    _transformController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _checkFavorite() async {
    if (_wallpaper == null) return;
    final fav = await WallKraftDatabase.isFavorite(_wallpaper!.id);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    if (_wallpaper == null) return;
    HapticFeedback.lightImpact();

    final previousState = _isFavorite;
    setState(() {
      _isFavorite = !previousState;
      _heartScale = 1.3;
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _heartScale = 1.0);
    });

    try {
      if (_isFavorite) {
        await WallKraftDatabase.addFavorite(_wallpaper!);
      } else {
        await WallKraftDatabase.removeFavorite(_wallpaper!.id);
      }
    } catch (e) {
      // DB write failed — roll back the optimistic UI toggle.
      if (mounted) {
        setState(() => _isFavorite = previousState);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorite'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _download() async {
    if (_wallpaper == null || _isDownloading) return;

    final existing =
        await DownloadManager.instance.getExistingPath(_wallpaper!.id);
    if (existing != null) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Already saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await DownloadManager.instance.download(
        _wallpaper!,
        onProgress: (p) {
          if (mounted) {
            setState(() => _downloadProgress = p.progress);
          }
        },
      );

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
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
            Text('Set Wallpaper',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacing16),
            ListTile(
              leading: const Icon(Icons.home_outlined,
                  color: AppTheme.systemBlue),
              title: const Text('Home Screen'),
              onTap: () => Navigator.pop(ctx, 'home'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline,
                  color: AppTheme.systemBlue),
              title: const Text('Lock Screen'),
              onTap: () => Navigator.pop(ctx, 'lock'),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android,
                  color: AppTheme.systemBlue),
              title: const Text('Both'),
              onTap: () => Navigator.pop(ctx, 'both'),
            ),
          ],
        ),
      ),
    );

    if (which == null || !mounted) return;

    try {
      var filePath =
          await DownloadManager.instance.getExistingPath(_wallpaper!.id);
      filePath ??= await DownloadManager.instance.download(_wallpaper!);
      final file = File(filePath);
      if (await file.exists()) {
        HapticFeedback.mediumImpact();
        final success =
            await WallpaperSetter.setWallpaper(file.path, which: which);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  success ? 'Wallpaper set' : 'Failed to set wallpaper'),
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

    // Show a loading dialog while preparing the image.
    if (!mounted) return;
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Preparing image…'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      // Download to a temp file — do not add to download history.
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/wallkraft-share-${_wallpaper!.id}.jpg');

      final response = await http.get(Uri.parse(_wallpaper!.path));
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      await file.writeAsBytes(response.bodyBytes);

      scaffold.hideCurrentSnackBar();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Wallpaper via WallKraft',
      );

      // Clean up temp file after share.
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      scaffold.hideCurrentSnackBar();
      if (mounted) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  void _toggleChrome() {
    // Guard against calling forward/reverse on a running animation.
    if (_chromeAnimController.isAnimating) return;

    if (_chromeVisible) {
      _chromeAnimController.reverse();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      _chromeAnimController.forward();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    setState(() => _chromeVisible = !_chromeVisible);
  }

  void _handleDoubleTapDown(TapDownDetails details, Size viewportSize) {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final w = _wallpaper;
    if (w == null) return;

    if (currentScale < 1.5) {
      // Use actual image pixel dimensions for accurate fill-scale math.
      final imgW = w.dimensionX.toDouble();
      final imgH = w.dimensionY.toDouble();
      final viewW = viewportSize.width;
      final viewH = viewportSize.height;

      if (imgW <= 0 || imgH <= 0 || viewW <= 0 || viewH <= 0) {
        // Fallback: zoom to 2x if dimensions are invalid.
        final tapX = details.localPosition.dx;
        final tapY = details.localPosition.dy;
        _transformController.value = Matrix4(
          2.0, 0.0, 0.0, 0.0,
          0.0, 2.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          -tapX * 2.0 + tapX, -tapY * 2.0 + tapY, 0.0, 1.0,
        );
        return;
      }

      // Scale at which the image fits within the viewport (BoxFit.contain).
      final fitScale = viewW / imgW < viewH / imgH
          ? viewW / imgW
          : viewH / imgH;

      // Scale needed so the fitted image fills the viewport height.
      final fillScale = (viewH / (imgH * fitScale))
          .clamp(2.0, 5.0);

      final tapX = details.localPosition.dx;
      final tapY = details.localPosition.dy;
      _transformController.value = Matrix4(
        fillScale, 0.0, 0.0, 0.0,
        0.0, fillScale, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        -tapX * fillScale + tapX, -tapY * fillScale + tapY, 0.0, 1.0,
      );
    } else {
      _transformController.value = Matrix4.identity();
    }
  }

  void _searchByTag(String tag) {
    Navigator.pop(context, {'searchTag': tag});
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.equal, control: true): () =>
            _transformController.value =
                Matrix4.diagonal3Values(3.0, 3.0, 1.0),
        const SingleActivator(LogicalKeyboardKey.minus, control: true): () =>
            _transformController.value = Matrix4.identity(),
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): () =>
            _transformController.value = Matrix4.identity(),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.pop(context),
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: !_isDownloading,
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop && _isDownloading && mounted) {
              final navigator = Navigator.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(ctx).colorScheme.surface,
                  title: const Text('Download in progress'),
                  content: const Text(
                      'Are you sure you want to leave? The download will be cancelled.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Stay'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Leave'),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                navigator.pop();
              }
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            extendBodyBehindAppBar: true,
            appBar: _buildAppBar(),
            body: _buildBody(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: FadeTransition(
        opacity: _chromeOpacity,
        child: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          elevation: 0,
          scrolledUnderElevation: 0,
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return GestureDetector(
                    onDoubleTapDown: (details) =>
                        _handleDoubleTapDown(details, viewportSize),
                    child: InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 1.0,
                      maxScale: 5.0,
                      boundaryMargin: EdgeInsets.zero,
                      child: _imageError
                          ? _buildImageErrorRetry()
                          : CachedNetworkImage(
                              key: ValueKey('img-$_imageLoadAttempt'),
                              imageUrl: _wallpaper!.path,
                              fit: BoxFit.contain,
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
                              errorWidget: (_, _, _) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted && !_imageError) {
                                    setState(() => _imageError = true);
                                  }
                                });
                                return const Center(
                                  child: Icon(Icons.broken_image,
                                      size: 48,
                                      color: AppTheme.tertiaryLabel),
                                );
                              },
                            ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Metadata panel (fades with chrome)
          FadeTransition(
            opacity: _chromeOpacity,
            child: _buildMetadata(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageErrorRetry() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _imageError = false;
          _imageLoadAttempt++;
        });
      },
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image,
                size: 48, color: AppTheme.tertiaryLabel),
            const SizedBox(height: AppTheme.spacing12),
            const Text(
              'Failed to load image',
              style: TextStyle(color: AppTheme.secondaryLabel),
            ),
            const SizedBox(height: AppTheme.spacing8),
            TextButton(
              onPressed: () {
                setState(() {
                  _imageError = false;
                  _imageLoadAttempt++;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.systemBlue,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
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
            // ── Info rows ────────────────────────────────────────
            _infoRow('Resolution', w.resolution),
            const Divider(),
            _infoRow('File Size', w.fileSizeFormatted),
            const Divider(),
            _infoRow('Favorites', '♥ ${_formatCount(w.favorites)}'),
            const Divider(),
            _infoRow('Category', w.category),

            // ── Tags (all, clickable) ────────────────────────────
            if (w.tags.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tags',
                        style: TextStyle(
                          color: AppTheme.secondaryLabel,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: AppTheme.spacing8),
                    Wrap(
                      spacing: AppTheme.spacing8,
                      runSpacing: AppTheme.spacing8,
                      children: w.tags.map((tag) {
                        return GestureDetector(
                          onTap: () => _searchByTag(tag.name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.secondarySystemBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.separator,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              tag.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.systemBlue,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppTheme.spacing8),

            // ── Download progress ─────────────────────────────────
            if (_isDownloading)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
                child: LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: AppTheme.secondarySystemBackground,
                  color: AppTheme.systemBlue,
                  minHeight: 3,
                ),
              ),

            // ── Action buttons (redesigned) ──────────────────────
            _actionTile(
              _isDownloading
                  ? Icons.hourglass_bottom
                  : Icons.download_outlined,
              _isDownloading
                  ? 'Downloading ${(_downloadProgress * 100).round()}%'
                  : 'Download',
              onTap: _isDownloading ? null : _download,
            ),
            _actionTile(Icons.wallpaper_outlined, 'Set Wallpaper',
                onTap: _setWallpaper),
            _actionTile(Icons.share_outlined, 'Share', onTap: _share),
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

  Widget _actionTile(IconData icon, String title, {VoidCallback? onTap}) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled ? AppTheme.systemBlue : AppTheme.tertiaryLabel,
            ),
            const SizedBox(width: AppTheme.spacing12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: enabled ? AppTheme.systemBlue : AppTheme.tertiaryLabel,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
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
