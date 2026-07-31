// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WallKraft';

  @override
  String get tabBrowse => 'Browse';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get tabDownloads => 'Downloads';

  @override
  String get searchHint => 'Search wallpapers';

  @override
  String get searchRecentTitle => 'Recent Searches';

  @override
  String get searchClearAll => 'Clear All';

  @override
  String get emptyFavoritesTitle => 'No favorites yet';

  @override
  String get emptyFavoritesSubtitle => 'Browse wallpapers and tap the heart icon to save your favorites here.';

  @override
  String get emptyDownloadsTitle => 'No downloads yet';

  @override
  String get emptyDownloadsSubtitle => 'Download wallpapers from the detail screen and they will appear here.';

  @override
  String get emptySearchTitle => 'No results found';

  @override
  String get emptySearchSubtitle => 'Try a different search term or adjust your filters.';

  @override
  String get emptyBrowseTitle => 'No wallpapers yet';

  @override
  String get retry => 'Retry';

  @override
  String failedLoadMore(String error) {
    return 'Failed to load more: $error';
  }

  @override
  String shareFailed(String error) {
    return 'Share failed: $error';
  }

  @override
  String get shareText => 'Wallpaper via WallKraft';

  @override
  String copyFailed(String error) {
    return 'Copy failed: $error';
  }

  @override
  String get linkCopied => 'Link copied';

  @override
  String get contextDetail => 'Open Detail';

  @override
  String get contextDownload => 'Download';

  @override
  String get contextShare => 'Share';

  @override
  String get contextCopyLink => 'Copy Link';

  @override
  String get preparingShare => 'Preparing image…';

  @override
  String updateAvailable(String version) {
    return 'WallKraft $version is available';
  }

  @override
  String get updateAction => 'Update';

  @override
  String get couldNotOpenBrowser => 'Could not open browser';

  @override
  String rateLimitReached(String time) {
    return 'Rate limit reached. Resets $time.';
  }

  @override
  String rateLimitRemaining(int count) {
    return 'API calls: $count remaining';
  }

  @override
  String get settingsApiKey => 'API Key';

  @override
  String get settingsApiKeyHint => 'Paste your Wallhaven API key';

  @override
  String get settingsApiKeySet => 'Set API Key';

  @override
  String get settingsApiKeyCleared => 'API key cleared';

  @override
  String get settingsGetKey => 'Get your free key';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceLight => 'Light';

  @override
  String get filtersCategories => 'Categories';

  @override
  String get filtersGeneral => 'General';

  @override
  String get filtersAnime => 'Anime';

  @override
  String get filtersPeople => 'People';

  @override
  String get filtersSorting => 'Sorting';

  @override
  String get filtersDateAdded => 'Date Added';

  @override
  String get filtersRandom => 'Random';

  @override
  String get filtersMostViewed => 'Most Viewed';

  @override
  String get filtersMostFavorited => 'Most Favorited';

  @override
  String get filtersPhotoType => 'Photo Type';

  @override
  String get filtersBoth => 'Both';

  @override
  String get filtersWallpapers => 'Wallpapers';

  @override
  String get filtersPhotos => 'Photos';

  @override
  String get filterApply => 'Apply';

  @override
  String get filterReset => 'Reset';

  @override
  String get detailDownload => 'Download';

  @override
  String get detailShare => 'Share';

  @override
  String get detailSetWallpaper => 'Set Wallpaper';

  @override
  String get detailHomeScreen => 'Home Screen';

  @override
  String get detailLockScreen => 'Lock Screen';

  @override
  String get detailBoth => 'Both';

  @override
  String get detailFavorites => 'Favorites';
}
