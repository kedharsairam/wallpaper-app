import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme.dart';

/// Filter sheet: categories, photo type, sort order, top range.
///
/// All changes are staged locally. Tapping "Apply Filters" commits them
/// and dismisses the sheet.
class FilterSheet extends StatefulWidget {
  final String categories;
  final String sorting;
  final String? topRange;
  final PhotoType photoType;
  final void Function(String categories, String sorting, String? topRange,
      PhotoType photoType) onApply;

  const FilterSheet({
    super.key,
    required this.categories,
    required this.sorting,
    this.topRange,
    this.photoType = PhotoType.both,
    required this.onApply,
  });

  /// Convenience method to show the filter sheet as a modal bottom sheet.
  static void show(
    BuildContext context, {
    required String categories,
    required String sorting,
    String? topRange,
    PhotoType photoType = PhotoType.both,
    required void Function(String, String, String?, PhotoType) onApply,
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
        photoType: photoType,
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
  late PhotoType _photoType;

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
    _photoType = widget.photoType;
  }

  void _apply() {
    final cats =
        '${_general ? '1' : '0'}${_anime ? '1' : '0'}${_people ? '1' : '0'}';
    widget.onApply(cats, _sorting.apiValue,
        _sorting == SortOption.topList ? _topRange.apiValue : null, _photoType);
    Navigator.pop(context);
  }

  void _toggleCategory(int index) {
    setState(() {
      switch (index) {
        case 0: _general = !_general;
        case 1: _anime = !_anime;
        case 2: _people = !_people;
      }
      // Ensure at least one category stays selected
      if (!_general && !_anime && !_people) {
        switch (index) {
          case 0: _general = true;
          case 1: _anime = true;
          case 2: _people = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16, AppTheme.spacing20, AppTheme.spacing16, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),

          // ── Categories ──────────────────────────────────────────
          Text('Categories',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacing8),
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: [
              _buildCategoryChip('General', _general, () => _toggleCategory(0)),
              _buildCategoryChip('Anime', _anime, () => _toggleCategory(1)),
              _buildCategoryChip('People', _people, () => _toggleCategory(2)),
            ],
          ),

          const SizedBox(height: AppTheme.spacing20),

          // ── Photo Type ──────────────────────────────────────────
          Text('Photo Type',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacing8),
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: PhotoType.values.map((pt) {
              final selected = _photoType == pt;
              return GestureDetector(
                onTap: () => setState(() => _photoType = pt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.systemBlue.withValues(alpha: 0.3)
                        : (isDark
                            ? AppTheme.secondarySystemBackground
                            : AppTheme.lightSecondaryBackground),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pt.label,
                    style: TextStyle(
                      color: selected
                          ? (isDark ? AppTheme.label : AppTheme.lightLabel)
                          : (isDark
                              ? AppTheme.secondaryLabel
                              : AppTheme.lightSecondaryLabel),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppTheme.spacing20),

          // ── Sort By ─────────────────────────────────────────────
          const SizedBox(height: AppTheme.spacing4),
          _buildDropdown<SortOption>(
            label: 'Sort by',
            value: _sorting,
            items: SortOption.values,
            itemLabel: (o) => o.label,
            onChanged: (v) => setState(() => _sorting = v),
          ),

          // ── Top Range ───────────────────────────────────────────
          if (_sorting == SortOption.topList) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildDropdown<TopRange>(
              label: 'Top Range',
              value: _topRange,
              items: TopRange.values,
              itemLabel: (r) => r.label,
              onChanged: (v) => setState(() => _topRange = v),
            ),
          ],

          const SizedBox(height: AppTheme.spacing24),

          // ── Apply Button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.systemBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Bottom safe area spacing
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  /// Builds a styled dropdown with label, consistent with the filter sheet design.
  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppTheme.secondarySystemBackground
        : AppTheme.lightSecondaryBackground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        DropdownButtonFormField<T>(
          initialValue: value,
          dropdownColor: surfaceColor,
          icon: Icon(Icons.expand_more_rounded,
              color: isDark ? AppTheme.label : AppTheme.lightLabel),
          style: TextStyle(
            color: isDark ? AppTheme.label : AppTheme.lightLabel,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark
                    ? AppTheme.separator
                    : AppTheme.lightSeparator,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark
                    ? AppTheme.separator.withValues(alpha: 0.3)
                    : AppTheme.lightSeparator.withValues(alpha: 0.3),
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(itemLabel(item)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, bool selected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.systemBlue.withValues(alpha: 0.3)
              : (isDark
                  ? AppTheme.secondarySystemBackground
                  : AppTheme.lightSecondaryBackground),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? (isDark ? AppTheme.label : AppTheme.lightLabel)
                : (isDark
                    ? AppTheme.secondaryLabel
                    : AppTheme.lightSecondaryLabel),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
