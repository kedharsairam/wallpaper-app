import 'package:flutter/material.dart';
import '../models/wallpaper.dart';
import '../services/database.dart';
import '../theme.dart';
import '../widgets/grid.dart';

class FavoritesScreen extends StatefulWidget {
  final VoidCallback? onBrowseTap;

  const FavoritesScreen({super.key, this.onBrowseTap});

  @override
  FavoritesScreenState createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  List<Wallpaper> _favorites = [];
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  /// Refresh the favorites list from the database.
  void refresh() => _loadFavorites();

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final faves = await WallKraftDatabase.getFavorites();
      if (mounted) setState(() => _favorites = faves);
    } catch (_) {
      if (mounted) setState(() => _favorites = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openDetail(Wallpaper w) {
    Navigator.pushNamed(
      context,
      '/detail',
      arguments: {'wallpaper': w, 'api': null},
    );
  }

  @override
  Widget build(BuildContext context) {
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

    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border,
                size: 48, color: AppTheme.tertiaryLabel),
            const SizedBox(height: AppTheme.spacing12),
            const Text(
              'No favorites',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.label,
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            const Text(
              'Favorite wallpapers to see them here',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.secondaryLabel,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextButton(
              onPressed: widget.onBrowseTap,
              child: const Text('Browse Wallpapers'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: WallpaperGrid(
        wallpapers: _favorites,
        onTap: _openDetail,
      ),
    );
  }
}
