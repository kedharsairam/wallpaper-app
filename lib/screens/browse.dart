import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/cancel_token.dart';
import '../api/client.dart';
import '../api/exception.dart';
import '../models/category.dart';
import '../models/rate_limit.dart';
import '../models/wallpaper.dart';
import '../services/cache_service.dart';
import '../services/recent_searches.dart';
import '../theme.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/grid.dart';
import '../widgets/empty_illustrations.dart';
import '../widgets/empty_state.dart';

class BrowseScreen extends StatefulWidget {
  final WallpaperApi api;

  const BrowseScreen({super.key, required this.api});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  List<Wallpaper> _wallpapers = [];
  var _isLoading = false;
  var _isLoadingMore = false;
  String? _error;
  var _page = 1;
  var _hasMore = true;
  List<String> _recentSearches = [];
  List<String> _suggestions = [];

  CancelToken? _cancelToken;
  CancelToken? _loadMoreToken;

  var _rateLimitDismissed = false;
  var _isHome = true;

  String _categories = '111';
  String _sorting = 'date_added';
  String? _query;
  PhotoType _photoType = PhotoType.both;

  /// Cancels any in-flight [search] request and creates a fresh token.
  /// Does NOT cancel [_loadMoreToken] — pagination runs independently.
  void _cancelPreviousRequest() {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Populate grid behind the homepage overlay from cache so the first
    // tap transitions instantly instead of showing a blank frame.
    _warmCache();
  }

  /// Loads the last successful search results from cache and populates the
  /// grid behind the homepage overlay. The homepage stays visible until the
  /// user interacts; when they do, the grid is already there.
  Future<void> _warmCache() async {
    try {
      final cached = await CacheService.instance.load();
      if (cached == null || !mounted) return;
      final rawData = cached['data'];
      if (rawData is! List) return;
      final restored = rawData
          .whereType<Map<String, dynamic>>()
          .map(Wallpaper.fromJson)
          .toList();
      if (restored.isEmpty) return;
      setState(() {
        _wallpapers = restored;
        _hasMore = false;
      });
      for (final w in restored) {
        final thumbUrl = w.thumbnailOriginal ?? w.thumbnail;
        if (thumbUrl.isNotEmpty) {
          unawaited(precacheImage(
            CachedNetworkImageProvider(thumbUrl),
            context,
          ));
        }
      }
    } catch (e) {
      debugPrint('[Browse] Cache warm failed: $e');
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _loadMoreToken?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pixels = _scrollController.position.pixels;
    if (pixels >= _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    if (_isLoading) return;
    _cancelPreviousRequest();
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });
    try {
      final response = await widget.api.search(
        query: _query,
        categories: _categories,
        sorting: _sorting,
        ratios: _photoType.apiValue,
        page: 1,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      setState(() {
        _wallpapers = response.data;
        _hasMore = _page < response.meta.lastPage;
        _isLoading = false;
        _isHome = false; // transition from homepage when data is ready
      });
      // Pre-cache thumbnails so the grid shows images instantly.
      for (final w in response.data) {
        final thumbUrl = w.thumbnailOriginal ?? w.thumbnail;
        if (thumbUrl.isNotEmpty) {
          unawaited(precacheImage(
            CachedNetworkImageProvider(thumbUrl),
            context,
          ));
        }
      }

      // Cache raw JSON for offline fallback
      try {
        final cacheJson = {
          'data': response.data.map(_wallpaperToJson).toList(),
        };
        await CacheService.instance.save(cacheJson);
      } catch (e) {
        debugPrint('[Browse] Cache save failed: $e');
      }
    } on CancelledException {
      // Request was intentionally cancelled — ignore.
    } catch (e) {
      if (!mounted) return;
      // If we already have data (e.g., from _warmCache), keep it silently.
      if (_wallpapers.isNotEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      // Try loading from cache as a last resort.
      final cached = await CacheService.instance.load();
      if (cached != null && mounted) {
        final rawData = cached['data'];
        if (rawData is List) {
          final restored = rawData
              .whereType<Map<String, dynamic>>()
              .map(Wallpaper.fromJson)
              .toList();
          if (restored.isNotEmpty) {
            setState(() {
              _wallpapers = restored;
              _error = null;
              _isLoading = false;
              _hasMore = false;
              _isHome = false;
            });
            for (final w in restored) {
              final thumbUrl = w.thumbnailOriginal ?? w.thumbnail;
              if (thumbUrl.isNotEmpty) {
                unawaited(precacheImage(
                  CachedNetworkImageProvider(thumbUrl),
                  context,
                ));
              }
            }
            return;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    if (_page < 1) return;
    setState(() => _isLoadingMore = true);
    final next = _page + 1;

    // Use a dedicated token so pagination isn't cancelled by _load().
    _loadMoreToken?.cancel();
    _loadMoreToken = CancelToken();

    try {
      final response = await widget.api.search(
        query: _query,
        categories: _categories,
        sorting: _sorting,
        ratios: _photoType.apiValue,
        page: next,
        cancelToken: _loadMoreToken,
      );
      if (!mounted) return;
      setState(() {
        _wallpapers.addAll(response.data);
        _page = next;
        _hasMore = _page < response.meta.lastPage;
        _isLoadingMore = false;
      });
    } on CancelledException {
      // Ignore intentional cancellations.
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more: $e')),
      );
    }
  }

  /// Called when user taps search/submit on keyboard.
  void _onSearchSubmitted(String query) async {
    final trimmed = query.trim();
    _query = trimmed.isNotEmpty ? trimmed : null;
    if (_query == null) return; // empty search — nothing to do
    setState(() => _isHome = false);

    if (_query != null) {
      await RecentSearchesService.save(_query!);
    }

    setState(() => _suggestions = []);
    _load();
  }

  /// Clears suggestions when the search field is cleared.
  void _onSearchChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
    }
  }

  void _openSearch() async {
    setState(() => _isHome = false);
    final searches = await RecentSearchesService.load();
    if (mounted) setState(() => _recentSearches = searches);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _closeSearch() {
    setState(() {
      _recentSearches = [];
      _suggestions = [];
    });
    _searchController.clear();
    _searchFocus.unfocus();
    if (_query != null) {
      _query = null;
      _load();
    }
  }

  /// Returns to the homepage. The browse grid stays alive underneath
  /// (scroll position preserved).
  void _goHome() {
    if (_isHome) return;
    setState(() {
      _isHome = true;
      _suggestions = [];
      _recentSearches = [];
    });
    _searchController.clear();
    _searchFocus.unfocus();
  }

  /// Picks a quick filter from the homepage and switches to browse mode
  /// only when data is ready — no loading flash, no blank state.
  void _onQuickFilter(String sorting) {
    setState(() {
      _sorting = sorting;
      _query = null;
    });
    _searchController.clear();
    _searchFocus.unfocus();
    _load();
  }

  void _openFilters() {
    FilterSheet.show(
      context,
      categories: _categories,
      sorting: _sorting,
      photoType: _photoType,
      onApply: (categories, sorting, photoType) {
        setState(() {
          _isHome = false;
          _categories = categories;
          _sorting = sorting;
          _photoType = photoType;
        });
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyR): _load,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): _load,
        const SingleActivator(LogicalKeyboardKey.escape): _closeSearch,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _openSearch,
        const SingleActivator(LogicalKeyboardKey.home): _scrollToTop,
        const SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
            _scrollToTop,
      },
      child: Focus(
        autofocus: true,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _isHome ? null : AppBar(
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildSearchField(),
              ),
              centerTitle: false,
              titleSpacing: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: IconButton(
                  icon: const Icon(Icons.home_outlined),
                  tooltip: 'Home',
                  onPressed: _goHome,
                ),
              ),
              actions: const [SizedBox(width: 8)],
            ),
          body: _body(),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppTheme.secondaryLabel : AppTheme.lightSecondaryLabel;
    return SizedBox(
      height: 40,
      child: TextField(
        key: const ValueKey('search-field'),
        controller: _searchController,
        focusNode: _searchFocus,
        cursorColor: AppTheme.systemBlue,
        style: TextStyle(
          color: isDark ? AppTheme.label : AppTheme.lightLabel,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Search wallpapers',
          hintStyle: TextStyle(
              color: isDark ? AppTheme.tertiaryLabel : AppTheme.lightTertiaryLabel),
          filled: true,
          fillColor: isDark
              ? AppTheme.secondarySystemBackground
              : AppTheme.lightSecondaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          isDense: true,
          suffixIconConstraints: const BoxConstraints(minWidth: 64, minHeight: 36),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.search, color: iconColor, size: 18),
                  onPressed: () => _onSearchSubmitted(_searchController.text),
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Search',
                ),
                IconButton(
                  icon: Icon(Icons.tune, color: iconColor, size: 18),
                  onPressed: _openFilters,
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Filters',
                ),
              ],
            ),
          ),
        ),
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
      ),
    );
  }

  Widget _buildRateLimitBanner() {
    final rateLimit = RateLimitState.instance;
    if (rateLimit.remaining > 10 || rateLimit.remaining == 45) {
      return const SizedBox.shrink();
    }
    if (_rateLimitDismissed) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: AppTheme.spacing16,
        right: AppTheme.spacing4,
        top: AppTheme.spacing8,
        bottom: AppTheme.spacing8,
      ),
      color: AppTheme.systemBlue.withValues(alpha: 0.15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rateLimit.isLimited
                  ? 'Rate limit reached. Resets ${rateLimit.resetTimeFormatted}.'
                  : 'API calls: ${rateLimit.remaining} remaining',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.systemBlue,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppTheme.systemBlue),
            onPressed: () => setState(() => _rateLimitDismissed = true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }

  Widget _body() {
    // Determine what to show on top of the persistent grid layer.
    Widget? overlay;

    if (_isHome) {
      overlay = _buildHomePage();
    } else if (_isLoading) {
      // Keep the grid visible — no loading spinner, no empty state flash.
    } else if (_query != null && _suggestions.isNotEmpty) {
      overlay = _buildSuggestions();
    } else if (_searchFocus.hasFocus && _query == null &&
        _recentSearches.isNotEmpty && _wallpapers.isEmpty) {
      overlay = _buildRecentSearches();
    } else if (_error != null) {
      overlay = _buildErrorState();
    } else if (_wallpapers.isEmpty) {
      overlay = _buildEmptyState();
    }
    // else: no overlay — grid shows through

    // Stack layout:
    //   Layer 0 — Grid (persistent, keeps scroll position alive)
    //   Layer 1 — Homepage or browse overlay (covers grid when active)
    return Stack(
      fit: StackFit.expand,
      children: [
        // Always render the grid frame to avoid blank flash during loading.
        // When wallpapers is empty, the child widget just shows nothing.
        _buildBrowseGrid(),
        ?overlay,
      ],
    );
  }

  /// The browse-mode grid with pagination, detail navigation, and rate limit banner.
  Widget _buildBrowseGrid() {
    return Column(
      children: [
        _buildRateLimitBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: WallpaperGrid(
              wallpapers: _wallpapers,
              hasMore: _hasMore,
              scrollController: _scrollController,
              onTap: (wallpaper) async {
                final result = await Navigator.pushNamed<Map<String, dynamic>>(
                  context,
                  '/detail',
                  arguments: {
                    'api': widget.api,
                    'wallpaper': wallpaper,
                  },
                );
                if (!mounted) return;
                // Handle tag search from detail screen
                if (result != null && result['searchTag'] is String) {
                  final tag = result['searchTag'] as String;
                  setState(() {
                    _query = tag;
                  });
                  _searchController.text = tag;
                  _searchFocus.requestFocus();
                  await RecentSearchesService.save(tag);
                  _load();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Homepage layout: search bar at exact center, branding above, chips below.
  Widget _buildHomePage() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hintColor = isDark ? AppTheme.tertiaryLabel : AppTheme.lightTertiaryLabel;

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // ── Upper half: branding pushed toward center ──────────────
          Expanded(
            flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                child: Column(
                  children: [
                    Text(
                      'WallKraft',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse Wallpapers',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),

        // ── Search bar — exact vertical + horizontal center ─────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  cursorColor: AppTheme.systemBlue,
                  style: TextStyle(
                    color: isDark ? AppTheme.label : AppTheme.lightLabel,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search wallpapers',
                    hintStyle: TextStyle(color: hintColor),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.secondarySystemBackground
                        : AppTheme.lightSecondaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 0),
                    isDense: true,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.search, color: hintColor, size: 18),
                            onPressed: () =>
                                _onSearchSubmitted(_searchController.text),
                            splashRadius: 14,
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: 'Search',
                          ),
                          IconButton(
                            icon: Icon(Icons.tune, color: hintColor, size: 18),
                            onPressed: _openFilters,
                            splashRadius: 14,
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: 'Filters',
                          ),
                        ],
                      ),
                    ),
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 64, minHeight: 36),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _onSearchSubmitted,
                ),
              ),
            ),
          ),
        ),

        // ── Lower half: chips pushed toward center ────────────────
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacing16),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppTheme.spacing8,
                  children: [
                    _quickFilterChip(
                        Icons.local_fire_department, 'Hot', 'hot'),
                    _quickFilterChip(Icons.schedule, 'Latest', 'date_added'),
                    _quickFilterChip(
                        Icons.favorite_outlined, 'Most Favorited', 'favorites'),
                  ],
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _quickFilterChip(IconData icon, String label, String sorting) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ActionChip(
      avatar: Icon(icon, size: 16,
          color: isDark ? AppTheme.secondaryLabel : AppTheme.lightSecondaryLabel),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: () => _onQuickFilter(sorting),
      backgroundColor: isDark
          ? AppTheme.secondarySystemBackground
          : AppTheme.lightSecondaryBackground,
      side: BorderSide(
        color: isDark ? AppTheme.separator : AppTheme.lightSeparator,
        width: 0.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextButton(
              onPressed: _load,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.systemBlue,
                minimumSize: const Size(0, AppTheme.spacing44),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16, AppTheme.spacing12, AppTheme.spacing16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent Searches',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.secondaryLabel
                        : AppTheme.lightSecondaryLabel,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await RecentSearchesService.clearAll();
                  setState(() => _recentSearches = []);
                },
                child: const Text('Clear All',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.systemBlue,
                    )),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: _recentSearches.map((query) {
              return GestureDetector(
                onTap: () => _executeRecentSearch(query),
                child: Chip(
                  label: Text(query,
                      style: TextStyle(
                          fontSize: 13,
                          color:
                              isDark ? AppTheme.label : AppTheme.lightLabel)),
                  backgroundColor: isDark
                      ? AppTheme.secondarySystemBackground
                      : AppTheme.lightSecondaryBackground,
                  deleteIcon: Icon(Icons.close,
                      size: 14,
                      color: isDark
                          ? AppTheme.tertiaryLabel
                          : AppTheme.lightTertiaryLabel),
                  onDeleted: () async {
                    await RecentSearchesService.remove(query);
                    setState(() => _recentSearches =
                        List.from(_recentSearches)..remove(query));
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16, AppTheme.spacing8, AppTheme.spacing16, 0),
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          dense: true,
          leading: Icon(Icons.search,
              size: 18,
              color: isDark
                  ? AppTheme.tertiaryLabel
                  : AppTheme.lightTertiaryLabel),
          title: Text(suggestion,
              style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppTheme.label : AppTheme.lightLabel)),
          onTap: () {
            _onSearchSubmitted(suggestion);
            setState(() => _suggestions = []);
          },
        );
      },
    );
  }

  void _executeRecentSearch(String query) {
    _query = query;
    _searchController.text = query;
    _searchFocus.requestFocus();
    _load();
  }

  /// Serializes a wallpaper to a plain JSON-compatible map for caching.
  Map<String, dynamic> _wallpaperToJson(Wallpaper w) {
    return {
      'id': w.id,
      'url': w.url,
      'path': w.path,
      'thumbs': {
        'small': w.thumbnail,
        if (w.thumbnailLarge != null) 'large': w.thumbnailLarge,
        if (w.thumbnailOriginal != null) 'original': w.thumbnailOriginal,
      },
      'dimension_x': w.dimensionX,
      'dimension_y': w.dimensionY,
      'ratio': w.ratio,
      'file_size': w.fileSize,
      'favorites': w.favorites,
      'category': w.category,
      'tags': w.tags.map((t) => {'id': t.id, 'name': t.name}).toList(),
    };
  }

  Widget _buildEmptyState() {
    final queryText = _query != null ? ' for "$_query"' : '';
    return EmptyState(
      illustration: _query != null ? Illustration.search : Illustration.browse,
      title: 'No wallpapers found$queryText',
      subtitle: 'Try adjusting your search or filters',
    );
  }
}


