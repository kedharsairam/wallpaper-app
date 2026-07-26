import 'package:flutter/material.dart';
import '../models/wallpaper.dart';
import '../services/database.dart';

import '../widgets/empty_illustrations.dart';
import '../widgets/empty_state.dart';
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
    } catch (e) {
      debugPrint('[Favorites] Load failed: $e');
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
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_favorites.isEmpty) {
      return EmptyState(
        illustration: Illustration.favorites,
        title: 'No favorites',
        subtitle: 'Favorite wallpapers to see them here',
        action: TextButton(
          onPressed: widget.onBrowseTap,
          child: const Text('Browse Wallpapers'),
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
