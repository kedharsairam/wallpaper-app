import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/settings_sheet.dart';
import '../widgets/shimmer_grid.dart';

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
  Timer? _searchDebounce;
  Timer? _suggestionDebounce;
  var _showSearch = false;

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

  String _categories = '111';
  String _sorting = 'toplist';
  String? _topRange;
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
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _loadMoreToken?.cancel();
    _searchDebounce?.cancel();
    _suggestionDebounce?.cancel();
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
        topRange: _topRange,
        ratios: _photoType.apiValue,
        page: 1,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      setState(() {
        _wallpapers = response.data;
        _hasMore = _page < response.meta.lastPage;
        _isLoading = false;
      });
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
      // Try loading from cache if we have nothing to show
      if (_wallpapers.isEmpty) {
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
              });
              return;
            }
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
        topRange: _topRange,
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

    if (_query != null) {
      await RecentSearchesService.save(_query!);
    }

    setState(() => _suggestions = []);
    _searchDebounce?.cancel();
    _load();
  }

  /// Debounced search-as-you-type handler.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _suggestionDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    // Fetch autocomplete suggestions after a short pause.
    _suggestionDebounce = Timer(const Duration(milliseconds: 200), () {
      widget.api.suggestions(trimmed).then((results) {
        if (mounted) setState(() => _suggestions = results);
      });
    });

    // Trigger search after debounce.
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _query = trimmed;
      _load();
    });
  }

  void _openSearch() async {
    setState(() {
      _showSearch = true;
      _recentSearches = [];
    });
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
      _showSearch = false;
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

  void _openSettings() {
    SettingsSheet.show(context);
  }

  void _openFilters() {
    FilterSheet.show(
      context,
      categories: _categories,
      sorting: _sorting,
      topRange: _topRange,
      photoType: _photoType,
      onApply: (categories, sorting, topRange, photoType) {
        setState(() {
          _categories = categories;
          _sorting = sorting;
          _topRange = topRange;
          _photoType = photoType;
          // Clear search query when applying filters so they don't overlap.
          _query = null;
          _showSearch = false;
        });
        _searchController.clear();
        _searchFocus.unfocus();
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
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_showSearch) _closeSearch();
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _openSearch,
        const SingleActivator(LogicalKeyboardKey.home): _scrollToTop,
        const SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
            _scrollToTop,
      },
      child: Focus(
        autofocus: true,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: _showSearch ? _buildSearchField() : const Text('WallKraft'),
              centerTitle: true,
              actions: [
                if (_showSearch)
                  TextButton(
                    onPressed: _closeSearch,
                    child: const Text('Cancel',
                        style: TextStyle(color: AppTheme.systemBlue)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Search',
                    onPressed: _openSearch,
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune),
                    tooltip: 'Filters',
                    onPressed: _openFilters,
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'About',
                    onPressed: _openSettings,
                  ),
              ],
            ),
          body: _body(),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 36,
      child: TextField(
        key: const ValueKey('search-field'),
        controller: _searchController,
        focusNode: _searchFocus,
        cursorColor: AppTheme.systemBlue,
        style: TextStyle(
          color: isDark ? AppTheme.label : AppTheme.lightLabel,
          fontSize: 16,
          height: 1.2,
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
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          isDense: true,
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: Icon(Icons.search,
                color: isDark ? AppTheme.secondaryLabel : AppTheme.lightSecondaryLabel,
                size: 18),
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
    // Loading state — shimmer placeholder
    if (_isLoading) {
      return const ShimmerGrid();
    }

    final banner = _buildRateLimitBanner();
    Widget content;

    // Show search suggestions when user is typing
    if (_showSearch && _query != null && _suggestions.isNotEmpty) {
      content = _buildSuggestions();
    } else if (_showSearch && _query == null && _wallpapers.isEmpty && _recentSearches.isNotEmpty) {
      content = _buildRecentSearches();
    } else if (_error != null) {
      content = _buildErrorState();
    } else if (_wallpapers.isEmpty) {
      content = _buildEmptyState();
    } else {
      content = RefreshIndicator(
        onRefresh: _load,
        child: WallpaperGrid(
          wallpapers: _wallpapers,
          isLoadingMore: _isLoadingMore,
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
                _showSearch = true;
              });
              _searchController.text = tag;
              _searchFocus.requestFocus();
              await RecentSearchesService.save(tag);
              _load();
            }
          },
        ),
      );
    }

    // Wrap all non-loading states with rate limit banner
    return Column(
      children: [
        banner,
        Expanded(child: content),
      ],
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
    _showSearch = true;
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
