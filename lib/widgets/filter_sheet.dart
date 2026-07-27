import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme.dart';

/// Filter sheet following Apple design patterns: clean, minimal, intentional.
///
/// Uses sentence-case headers, checkmark selection, a segmented control,
/// and a grouped list layout. All changes are staged locally; tap Apply
/// at the top-right to commit and dismiss.
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
      useSafeArea: true,
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
    final text = isDark ? AppTheme.label : AppTheme.lightLabel;
    final separator =
        isDark ? AppTheme.separator : AppTheme.lightSeparator;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.systemBackground
            : AppTheme.lightSystemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.tertiaryLabel
                        : AppTheme.lightTertiaryLabel,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            // Title
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                children: [
                  _sectionHeader('Categories', isDark),
                  const SizedBox(height: 10),
                  _buildCategoryRow(isDark, separator),

                  const SizedBox(height: 24),

                  _sectionHeader('Photo Type', isDark),
                  const SizedBox(height: 10),
                  _buildSegmentedControl(isDark, separator),

                  const SizedBox(height: 24),

                  _sectionHeader('Sort By', isDark),
                  const SizedBox(height: 6),
                  _buildCheckmarkList(
                    items: SortOption.values,
                    selectedItem: _sorting,
                    onSelected: (v) => setState(() => _sorting = v),
                    labelBuilder: (v) => v.label,
                    isDark: isDark,
                    separator: separator,
                  ),

                  if (_sorting == SortOption.topList) ...[
                    const SizedBox(height: 24),
                    _sectionHeader('Top Range', isDark),
                    const SizedBox(height: 6),
                    _buildCheckmarkList(
                      items: TopRange.values,
                      selectedItem: _topRange,
                      onSelected: (v) => setState(() => _topRange = v),
                      labelBuilder: (v) => v.label,
                      isDark: isDark,
                      separator: separator,
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.systemBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark
            ? AppTheme.secondaryLabel
            : AppTheme.lightSecondaryLabel,
      ),
    );
  }

  // ── Categories ────────────────────────────────────────────────────

  Widget _buildCategoryRow(bool isDark, Color separator) {
    return Row(
      children: [
        _categoryPill('General', _general, () => _toggleCategory(0), isDark),
        const SizedBox(width: 8),
        _categoryPill('Anime', _anime, () => _toggleCategory(1), isDark),
        const SizedBox(width: 8),
        _categoryPill('People', _people, () => _toggleCategory(2), isDark),
      ],
    );
  }

  Widget _categoryPill(
      String label, bool selected, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.systemBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.systemBlue
                  : (isDark ? AppTheme.separator : AppTheme.lightSeparator),
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : (isDark ? AppTheme.label : AppTheme.lightLabel),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Photo Type Segmented Control ──────────────────────────────────

  Widget _buildSegmentedControl(bool isDark, Color separator) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: separator, width: 1),
      ),
      child: Row(
        children: PhotoType.values.map((pt) {
          final selected = _photoType == pt;
          final isFirst = pt == PhotoType.values.first;
          final isLast = pt == PhotoType.values.last;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _photoType = pt),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.systemBlue : Colors.transparent,
                  borderRadius: isFirst
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          bottomLeft: Radius.circular(11))
                      : (isLast
                          ? const BorderRadius.only(
                              topRight: Radius.circular(11),
                              bottomRight: Radius.circular(11))
                          : null),
                  border: !isLast
                      ? Border(
                          right: BorderSide(color: separator, width: 1))
                      : null,
                ),
                child: Text(
                  pt.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : (isDark ? AppTheme.label : AppTheme.lightLabel),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Generic Checkmark List ────────────────────────────────────────

  Widget _buildCheckmarkList<T>({
    required List<T> items,
    required T selectedItem,
    required ValueChanged<T> onSelected,
    required String Function(T) labelBuilder,
    required bool isDark,
    required Color separator,
  }) {
    final bg = isDark
        ? AppTheme.secondarySystemBackground
        : AppTheme.lightSecondaryBackground;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final selected = item == selectedItem;
          final isLast = index == items.length - 1;
          return GestureDetector(
            onTap: () => onSelected(item),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                border: !isLast
                    ? Border(
                        bottom: BorderSide(color: separator, width: 0.5))
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    labelBuilder(item),
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppTheme.label : AppTheme.lightLabel,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    const Icon(Icons.check,
                        size: 18, color: AppTheme.systemBlue),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
