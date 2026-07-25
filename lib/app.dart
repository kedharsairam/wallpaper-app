import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api/client.dart';
import 'screens/browse.dart';
import 'screens/favorites.dart';
import 'screens/downloads.dart';
import 'screens/detail.dart';
import 'services/update_checker.dart';
import 'theme.dart';

class WallKraftApp extends StatelessWidget {
  final WallpaperApi api;
  final UpdateChecker updater;

  const WallKraftApp({super.key, required this.api, required this.updater});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WallKraft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _MainScaffold(api: api, updater: updater),
      routes: {
        '/detail': (context) => const DetailScreen(),
      },
    );
  }
}

class _MainScaffold extends StatefulWidget {
  final WallpaperApi api;
  final UpdateChecker updater;

  const _MainScaffold({required this.api, required this.updater});

  @override
  State<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<_MainScaffold> {
  var _currentTab = 0;
  final _favKey = GlobalKey<FavoritesScreenState>();
  final _dlKey = GlobalKey<DownloadsScreenState>();
  var _hasCheckedUpdate = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedUpdate) {
      _hasCheckedUpdate = true;
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    final latest = await widget.updater.checkForUpdate();
    if (latest != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WallKraft $latest is available'),
          action: SnackBarAction(
            label: 'Update',
            onPressed: () => launchUrl(
              Uri.parse('https://github.com/kedharsairam/wallpaper-app/releases/latest'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  void _switchToBrowse() {
    setState(() => _currentTab = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentTab,
        children: [
          BrowseScreen(api: widget.api),
          FavoritesScreen(key: _favKey, onBrowseTap: _switchToBrowse),
          DownloadsScreen(key: _dlKey, onBrowseTap: _switchToBrowse),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() => _currentTab = index);
          // Refresh tab data when switching to it
          if (index == 1) _favKey.currentState?.refresh();
          if (index == 2) _dlKey.currentState?.refresh();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download_outlined),
            activeIcon: Icon(Icons.download),
            label: 'Downloads',
          ),
        ],
      ),
    );
  }
}
