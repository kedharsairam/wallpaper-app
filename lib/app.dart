import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api/client.dart';
import 'screens/browse.dart';
import 'screens/favorites.dart';
import 'screens/downloads.dart';
import 'screens/settings_screen.dart';
import 'screens/detail.dart';
import 'services/update_checker.dart';
import 'services/theme_service.dart';
import 'theme.dart';
import 'l10n/app_localizations.dart';

/// Root app widget with theme mode management.
///
/// Theme preference is persisted and restored across sessions.
class WallKraftApp extends StatefulWidget {
  final WallpaperApi api;
  final UpdateChecker updater;

  const WallKraftApp({super.key, required this.api, required this.updater});

  @override
  State<WallKraftApp> createState() => WallKraftAppState();

  /// Allow child widgets to trigger a theme change by calling this.
  static WallKraftAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<WallKraftAppState>();
  }
}

class WallKraftAppState extends State<WallKraftApp> {
  var _themeMode = ThemeMode.system;
  var _themeLoaded = false;

  /// The current theme mode (may differ from saved during init).
  ThemeMode get currentThemeMode => _themeMode;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await ThemeService.load();
    if (mounted) {
      setState(() {
        _themeMode = mode;
        _themeLoaded = true;
      });
    }
  }

  /// Called from settings sheet when user changes theme.
  Future<void> setThemeMode(ThemeMode mode) async {
    await ThemeService.save(mode);
    if (mounted) setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WallKraft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeLoaded ? _themeMode : ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _MainScaffold(api: widget.api, updater: widget.updater),
      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          return MaterialPageRoute<Map<String, dynamic>>(
            settings: settings,
            builder: (context) => const DetailScreen(),
          );
        }
        return null;
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

class _MainScaffoldState extends State<_MainScaffold>
    with WidgetsBindingObserver {
  var _currentTab = 0;
  final _favKey = GlobalKey<FavoritesScreenState>();
  final _dlKey = GlobalKey<DownloadsScreenState>();
  var _hasCheckedUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Handle deep link that launched the app (app shortcuts).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initial = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
      if (initial.isNotEmpty && initial != '/') {
        _handleDeepLink(initial);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    _handleDeepLink(routeInformation.uri.toString());
    return Future.value(true);
  }

  void _handleDeepLink(String route) {
    if (!mounted) return;
    final uri = Uri.tryParse(route);
    if (uri == null) return;
    switch (uri.host) {
      case 'search':
        _switchToBrowse();
      case 'favorites':
        setState(() => _currentTab = 1);
      case 'downloads':
        setState(() => _currentTab = 2);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedUpdate) {
      _hasCheckedUpdate = true;
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final latest = await widget.updater.checkForUpdate();
      if (latest != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WallKraft $latest is available'),
            action: SnackBarAction(
              label: 'Update',
              onPressed: () async {
                final uri = Uri.parse(
                    'https://github.com/kedharsairam/wallpaper-app/releases/latest');
                final launched = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!launched && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open browser')),
                  );
                }
              },
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      debugPrint('[UPDATE CHECK FAILED] $e');
    }
  }

  void _switchToBrowse() {
    setState(() => _currentTab = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentTab,
        children: [
          BrowseScreen(api: widget.api),
          FavoritesScreen(key: _favKey, onBrowseTap: _switchToBrowse),
          DownloadsScreen(key: _dlKey, onBrowseTap: _switchToBrowse),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
                color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (index) {
            setState(() => _currentTab = index);
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
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
