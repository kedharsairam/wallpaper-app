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

/// Top range filter for ranking-based sorting.
enum TopRange {
  past24h('Past 24h', '1d'),
  past3Days('Past 3 days', '3d'),
  pastWeek('Past week', '1w'),
  pastMonth('Past month', '1M'),
  past3Months('Past 3 months', '3M'),
  past6Months('Past 6 months', '6M'),
  pastYear('Past year', '1y');

  final String label;
  final String apiValue;
  const TopRange(this.label, this.apiValue);
}
