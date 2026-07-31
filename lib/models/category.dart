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
  hot('Hot', 'hot'),
  latest('Latest', 'date_added'),
  random('Random', 'random'),
  mostFavorited('Most Favorited', 'favorites');

  final String label;
  final String apiValue;
  const SortOption(this.label, this.apiValue);

  static SortOption fromApi(String value) {
    return SortOption.values.firstWhere(
      (o) => o.apiValue == value,
      orElse: () => SortOption.latest,
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


