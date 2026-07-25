import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/cancel_token.dart';
import '../api/client.dart';
import '../api/exception.dart';
import '../models/rate_limit.dart';
import '../models/wallpaper.dart';
import '../services/cache_service.dart';
import '../services/recent_searches.dart';
import '../theme.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/grid.dart';
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
  var _showSearch = false;

  List<Wallpaper> _wallpapers = [];
  var _isLoading = false;
  var _isLoadingMore = false;
  String? _error;
  var _page = 1;
  var _hasMore = true;
  List<String> _recentSearches = [];

  CancelToken? _cancelToken;

  var _rateLimitDismissed = false;

  String _categories = '111';
  String _sorting = 'toplist';
  String? _topRange;
  String? _query;

  /// Cancels any in-flight request and creates a fresh cancel token.
  void _cancelPreviousRequest() {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
  }

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      if (_showSearch) setState(() {});
    });
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _searchDebounce?.cancel();
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
          'data': response.data.map((w) => _wallpaperToJson(w)).toList(),
        };
        await CacheService.instance.save(cacheJson);
      } catch (_) {}
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
                .map((e) => Wallpaper.fromJson(e))
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
    try {
      final response = await widget.api.search(
        query: _query,
        categories: _categories,
        sorting: _sorting,
        topRange: _topRange,
        page: next,
        cancelToken: _cancelToken,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more: $e',
                style: const TextStyle(color: AppTheme.label)),
            backgroundColor: AppTheme.systemBackground,
          ),
        );
      }
    }
  }

  /// Called when user taps search/submit on keyboard.
  void _onSearchSubmitted(String query) async {
    final trimmed = query.trim();
    _query = trimmed.isNotEmpty ? trimmed : null;

    if (_query != null) {
      await RecentSearchesService.save(_query!);
    }

    _searchDebounce?.cancel();
    _load();
    // Keep search visible with the query — user dismissed via Escape/X.
  }

  /// Debounced search-as-you-type handler.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = value.trim();
      _query = trimmed.isNotEmpty ? trimmed : null;
      _load();
    });
  }

  void _openSearch() async {
    setState(() {
      _showSearch = true;
      _recentSearches = [];
    });
    _recentSearches = await RecentSearchesService.load();
    if (mounted) setState(() {});
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
      onApply: (categories, sorting, topRange) {
        setState(() {
          _categories = categories;
          _sorting = sorting;
          _topRange = topRange;
        });
        _load();
        _searchController.clear();
        if (mounted) {
          setState(() => _showSearch = false);
          _searchFocus.unfocus();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyR): _load,
        SingleActivator(LogicalKeyboardKey.keyR, control: true): _load,
        SingleActivator(LogicalKeyboardKey.escape): () {
          if (_showSearch) _closeSearch();
        },
        SingleActivator(LogicalKeyboardKey.keyF, control: true): _openSearch,
        SingleActivator(LogicalKeyboardKey.home): _scrollToTop,
        SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
            _scrollToTop,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: _showSearch ? _buildSearchField() : const Text('WallKraft'),
            actions: [
              if (_showSearch)
                TextButton(
                  onPressed: _closeSearch,
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.systemBlue)),
                )
              else
                IconButton(
                  icon: const Icon(Icons.search, color: AppTheme.secondaryLabel),
                  tooltip: 'Search',
                  onPressed: _openSearch,
                ),
                IconButton(
                  icon: const Icon(Icons.tune, color: AppTheme.secondaryLabel),
                  tooltip: 'Filters',
                  onPressed: _openFilters,
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: AppTheme.secondaryLabel),
                  tooltip: 'Settings',
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
    return Container(
      key: const ValueKey('search-field'),
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: AppTheme.label, fontSize: 16),
        decoration: const InputDecoration(
          hintText: 'Search wallpapers',
          hintStyle: TextStyle(color: AppTheme.tertiaryLabel),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          isDense: true,
          prefixIcon:
              Icon(Icons.search, color: AppTheme.secondaryLabel, size: 20),
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

    // Show recent searches when search is focused and no query yet
    if (_showSearch && _query == null && _wallpapers.isEmpty && _recentSearches.isNotEmpty) {
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
          onTap: (wallpaper) {
            Navigator.pushNamed(context, '/detail', arguments: {
              'api': widget.api,
              'wallpaper': wallpaper,
            });
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                size: 48, color: AppTheme.tertiaryLabel),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.secondaryLabel),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16, AppTheme.spacing12, AppTheme.spacing16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Recent Searches',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondaryLabel,
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
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.label)),
                  backgroundColor: AppTheme.secondarySystemBackground,
                  deleteIcon: const Icon(Icons.close,
                      size: 14, color: AppTheme.tertiaryLabel),
                  onDeleted: () async {
                    await RecentSearchesService.remove(query);
                    setState(
                        () => _recentSearches = List.from(_recentSearches)..remove(query));
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

  void _executeRecentSearch(String query) {
    _query = query;
    _searchController.text = query;
    _showSearch = false;
    _searchFocus.unfocus();
    _load();
    setState(() {});
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined,
                size: 48, color: AppTheme.tertiaryLabel),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'No wallpapers found$queryText',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.secondaryLabel),
            ),
            const SizedBox(height: AppTheme.spacing4),
            const Text(
              'Try adjusting your search or filters',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.tertiaryLabel, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}


