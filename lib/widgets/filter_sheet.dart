import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme.dart';

/// Filter sheet for search: categories, sort order, top range.
///
/// Changes apply immediately on selection (no Apply button).
class FilterSheet extends StatefulWidget {
  final String categories;
  final String sorting;
  final String? topRange;
  final void Function(String categories, String sorting, String? topRange)
      onApply;

  const FilterSheet({
    super.key,
    required this.categories,
    required this.sorting,
    this.topRange,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required String categories,
    required String sorting,
    String? topRange,
    required void Function(String, String, String?) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FilterSheet(
        categories: categories,
        sorting: sorting,
        topRange: topRange,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late bool _general;
  late bool _anime;
  late bool _people;
  late SortOption _sorting;
  late TopRange _topRange;

  @override
  void initState() {
    super.initState();
    final cats = widget.categories.padRight(3, '0');
    _general = cats[0] == '1';
    _anime = cats[1] == '1';
    _people = cats[2] == '1';
    _sorting = SortOption.fromApi(widget.sorting);
    _topRange = TopRange.values.firstWhere(
      (r) => r.apiValue == (widget.topRange ?? '1M'),
      orElse: () => TopRange.pastMonth,
    );
  }

  void _apply() {
    final cats =
        '${_general ? '1' : '0'}${_anime ? '1' : '0'}${_people ? '1' : '0'}';
    widget.onApply(cats, _sorting.apiValue,
        _sorting == SortOption.topList ? _topRange.apiValue : null);
  }

  void _toggleCategory(Category cat, bool value) {
    // Ensure at least one category stays selected
    final cats = [_general, _anime, _people];
    final activeCount = cats.where((c) => c).length;
    final idx = _categoryIndex(cat);
    if (!value && activeCount <= 1 && cats[idx]) return;

    setState(() {
      if (cat == Category.general) _general = value;
      if (cat == Category.anime) _anime = value;
      if (cat == Category.people) _people = value;
    });
    _apply();
  }

  int _categoryIndex(Category cat) {
    switch (cat) {
      case Category.general:
        return 0;
      case Category.anime:
        return 1;
      case Category.people:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16, AppTheme.spacing20, AppTheme.spacing16, 32),
      decoration: const BoxDecoration(
        color: AppTheme.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grabber
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
          const Text('Categories', style: AppTheme.headline),
          const SizedBox(height: AppTheme.spacing8),
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: [
              _buildCategoryChip(Category.general, _general),
              _buildCategoryChip(Category.anime, _anime),
              _buildCategoryChip(Category.people, _people),
            ],
          ),
          const SizedBox(height: AppTheme.spacing20),
          const Text('Sort by', style: AppTheme.headline),
          const SizedBox(height: AppTheme.spacing8),
          DropdownButtonFormField<SortOption>(
            initialValue: _sorting,
            dropdownColor: AppTheme.secondarySystemBackground,
            style: const TextStyle(color: AppTheme.label),
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppTheme.secondarySystemBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide.none,
              ),
            ),
            items: SortOption.values
                .map((o) =>
                    DropdownMenuItem(value: o, child: Text(o.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _sorting = v);
                _apply();
              }
            },
          ),
          if (_sorting == SortOption.topList) ...[
            const SizedBox(height: AppTheme.spacing12),
            const Text('Top Range', style: AppTheme.headline),
            const SizedBox(height: AppTheme.spacing8),
            DropdownButtonFormField<TopRange>(
              initialValue: _topRange,
              dropdownColor: AppTheme.secondarySystemBackground,
              style: const TextStyle(color: AppTheme.label),
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppTheme.secondarySystemBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide.none,
                ),
              ),
              items: TopRange.values
                  .map((r) =>
                      DropdownMenuItem(value: r, child: Text(r.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _topRange = v);
                  _apply();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(Category cat, bool selected) {
    return GestureDetector(
      onTap: () => _toggleCategory(cat, !selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.systemBlue.withValues(alpha: 0.3)
              : AppTheme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          cat.label,
          style: TextStyle(
            color: selected ? AppTheme.label : AppTheme.secondaryLabel,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
