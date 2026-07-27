/// Wallpaper category filter options.
enum Category {
  general('General'),
  anime('Anime'),
  people('People');

  final String label;
  const Category(this.label);

  /// Parses a category string from the API (e.g., "general" → Category.general).
  static Category fromApi(String value) {
    switch (value) {
      case 'general':
        return Category.general;
      case 'anime':
        return Category.anime;
      case 'people':
        return Category.people;
      default:
        return Category.general;
    }
  }
}

/// Sort options for wallpaper search.
enum SortOption {
  dateAdded('Date Added', 'date_added'),
  relevance('Relevance', 'relevance'),
  random('Random', 'random'),
  mostViewed('Most Viewed', 'views'),
  mostFavorited('Most Favorited', 'favorites'),
  topList('Top List', 'toplist');

  final String label;
  final String apiValue;
  const SortOption(this.label, this.apiValue);

  static SortOption fromApi(String value) {
    return SortOption.values.firstWhere(
      (o) => o.apiValue == value,
      orElse: () => SortOption.dateAdded,
    );
  }
}

/// Photo orientation filter.
///
/// Maps to the `ratios` API parameter for aspect-ratio-based filtering.
enum PhotoType {
  both('All', null),
  portrait('Portrait', '9x16,2x3,3x4,10x16'),
  landscape('Landscape', '16x9,4x3,3x2,16x10');

  final String label;
  final String? apiValue; // null = no filter (returns both)
  const PhotoType(this.label, this.apiValue);
}

/// Top range filter for ranking-based sorting.
enum TopRange {
  pastWeek('Past week', '1w'),
  pastMonth('Past month', '1M'),
  past6Months('Past 6 months', '6M'),
  pastYear('Past year', '1y');

  final String label;
  final String apiValue;
  const TopRange(this.label, this.apiValue);
}
