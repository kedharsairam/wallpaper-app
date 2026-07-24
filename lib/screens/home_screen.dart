import 'package:flutter/material.dart';
import '../models/wallhaven_wallpaper.dart';
import '../services/wallhaven_api.dart';
import '../widgets/wallpaper_grid.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final WallhavenApi api;

  const HomeScreen({super.key, required this.api});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<WallhavenWallpaper> _wallpapers = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMore = true;

  // Filters
  String _categories = '111';
  String _purity = '100';
  String _sorting = 'toplist';
  final String _order = 'desc';
  String? _topRange;
  String? _query;

  @override
  void initState() {
    super.initState();
    _loadWallpapers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadWallpapers() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    try {
      final response = await widget.api.search(
        query: _query,
        categories: _categories,
        purity: _purity,
        sorting: _sorting,
        order: _order,
        topRange: _topRange,
        page: 1,
      );
      setState(() {
        _wallpapers = response.data;
        _lastPage = response.meta.lastPage;
        _hasMore = _currentPage < _lastPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    try {
      final response = await widget.api.search(
        query: _query,
        categories: _categories,
        purity: _purity,
        sorting: _sorting,
        order: _order,
        topRange: _topRange,
        page: nextPage,
      );
      setState(() {
        _wallpapers.addAll(response.data);
        _currentPage = nextPage;
        _hasMore = _currentPage < _lastPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onSearch(String query) {
    _query = query.isNotEmpty ? query : null;
    _loadWallpapers();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        categories: _categories,
        purity: _purity,
        sorting: _sorting,
        topRange: _topRange,
        onApply: (categories, purity, sorting, topRange) {
          setState(() {
            _categories = categories;
            _purity = purity;
            _sorting = sorting;
            _topRange = topRange;
          });
          _loadWallpapers();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          'Wallhaven',
          style: TextStyle(
            fontFamily: 'GoogleFonts',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white70),
            onPressed: _openFilters,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadWallpapers,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search wallpapers...',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon:
              const Icon(Icons.search, color: Colors.white54),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: _onSearch,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadWallpapers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_wallpapers.isEmpty) {
      return const Center(
        child: Text(
          'No wallpapers found',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return WallpaperGrid(
      wallpapers: _wallpapers,
      isLoadingMore: _isLoadingMore,
      hasMore: _hasMore,
      scrollController: _scrollController,
      onTap: (wallpaper) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(api: widget.api, wallpaper: wallpaper),
          ),
        );
      },
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String categories;
  final String purity;
  final String sorting;
  final String? topRange;
  final void Function(String, String, String, String?) onApply;

  const _FilterSheet({
    required this.categories,
    required this.purity,
    required this.sorting,
    this.topRange,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _general;
  late bool _anime;
  late bool _people;
  late bool _sfw;
  late bool _sketchy;
  late bool _nsfw;
  late String _sorting;
  late String? _topRange;

  @override
  void initState() {
    super.initState();
    final cats = widget.categories.padRight(3, '0');
    _general = cats[0] == '1';
    _anime = cats[1] == '1';
    _people = cats[2] == '1';

    final pur = widget.purity.padRight(3, '0');
    _sfw = pur[0] == '1';
    _sketchy = pur[1] == '1';
    _nsfw = pur[2] == '1';

    _sorting = widget.sorting;
    _topRange = widget.topRange;
  }

  void _apply() {
    final cats =
        '${_general ? '1' : '0'}${_anime ? '1' : '0'}${_people ? '1' : '0'}';
    final pur =
        '${_sfw ? '1' : '0'}${_sketchy ? '1' : '0'}${_nsfw ? '1' : '0'}';
    widget.onApply(cats, pur, _sorting, _topRange);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20).copyWith(bottom: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Categories',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _filterChip('General', _general, (v) => setState(() => _general = v)),
              _filterChip('Anime', _anime, (v) => setState(() => _anime = v)),
              _filterChip('People', _people, (v) => setState(() => _people = v)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Purity',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _filterChip('SFW', _sfw, (v) => setState(() => _sfw = v)),
              _filterChip('Sketchy', _sketchy, (v) => setState(() => _sketchy = v)),
              _filterChip('NSFW', _nsfw, (v) => setState(() => _nsfw = v)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Sort by',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _sorting,
            dropdownColor: const Color(0xFF2A2A2A),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'date_added', child: Text('Date Added')),
              DropdownMenuItem(value: 'relevance', child: Text('Relevance')),
              DropdownMenuItem(value: 'random', child: Text('Random')),
              DropdownMenuItem(value: 'views', child: Text('Most Viewed')),
              DropdownMenuItem(value: 'favorites', child: Text('Most Favorited')),
              DropdownMenuItem(value: 'toplist', child: Text('Top List')),
            ],
            onChanged: (v) => setState(() => _sorting = v!),
          ),
          if (_sorting == 'toplist') ...[
            const SizedBox(height: 12),
            const Text('Top Range',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _topRange ?? '1M',
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(value: '1d', child: Text('Past 24h')),
                DropdownMenuItem(value: '3d', child: Text('Past 3 days')),
                DropdownMenuItem(value: '1w', child: Text('Past week')),
                DropdownMenuItem(value: '1M', child: Text('Past month')),
                DropdownMenuItem(value: '3M', child: Text('Past 3 months')),
                DropdownMenuItem(value: '6M', child: Text('Past 6 months')),
                DropdownMenuItem(value: '1y', child: Text('Past year')),
              ],
              onChanged: (v) => setState(() => _topRange = v),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Apply Filters',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
      selectedColor: Colors.blueAccent.withValues(alpha: 0.3),
      checkmarkColor: Colors.white,
      backgroundColor: const Color(0xFF2A2A2A),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white60,
      ),
    );
  }
}
