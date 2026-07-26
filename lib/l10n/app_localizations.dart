import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'WallKraft'**
  String get appTitle;

  /// Bottom navigation tab: browse wallpapers
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get tabBrowse;

  /// Bottom navigation tab: favorite wallpapers
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabFavorites;

  /// Bottom navigation tab: downloaded wallpapers
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get tabDownloads;

  /// Hint text in the search field
  ///
  /// In en, this message translates to:
  /// **'Search wallpapers'**
  String get searchHint;

  /// Title above the list of recent searches
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get searchRecentTitle;

  /// Button to clear all recent searches
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get searchClearAll;

  /// Title shown when favorites list is empty
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get emptyFavoritesTitle;

  /// Subtitle shown when favorites list is empty
  ///
  /// In en, this message translates to:
  /// **'Browse wallpapers and tap the heart icon to save your favorites here.'**
  String get emptyFavoritesSubtitle;

  /// Title shown when downloads list is empty
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get emptyDownloadsTitle;

  /// Subtitle shown when downloads list is empty
  ///
  /// In en, this message translates to:
  /// **'Download wallpapers from the detail screen and they will appear here.'**
  String get emptyDownloadsSubtitle;

  /// Title shown when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get emptySearchTitle;

  /// Subtitle shown when search returns no results
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or adjust your filters.'**
  String get emptySearchSubtitle;

  /// Title shown when browse screen has no wallpapers
  ///
  /// In en, this message translates to:
  /// **'No wallpapers yet'**
  String get emptyBrowseTitle;

  /// Retry button after an error
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Error shown when pagination fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load more: {error}'**
  String failedLoadMore(String error);

  /// Error shown when sharing fails
  ///
  /// In en, this message translates to:
  /// **'Share failed: {error}'**
  String shareFailed(String error);

  /// Text attached when sharing a wallpaper
  ///
  /// In en, this message translates to:
  /// **'Wallpaper via WallKraft'**
  String get shareText;

  /// Error shown when clipboard copy fails
  ///
  /// In en, this message translates to:
  /// **'Copy failed: {error}'**
  String copyFailed(String error);

  /// Confirmation when link is copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// Context menu: open wallpaper detail
  ///
  /// In en, this message translates to:
  /// **'Open Detail'**
  String get contextDetail;

  /// Context menu: download wallpaper
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get contextDownload;

  /// Context menu: share wallpaper
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get contextShare;

  /// Context menu: copy wallpaper URL
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get contextCopyLink;

  /// Loading message shown while preparing image for sharing
  ///
  /// In en, this message translates to:
  /// **'Preparing image…'**
  String get preparingShare;

  /// Notification shown when a new version is available
  ///
  /// In en, this message translates to:
  /// **'WallKraft {version} is available'**
  String updateAvailable(String version);

  /// Button to navigate to update URL
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateAction;

  /// Error shown when the browser cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open browser'**
  String get couldNotOpenBrowser;

  /// Shown when API rate limit is exceeded
  ///
  /// In en, this message translates to:
  /// **'Rate limit reached. Resets {time}.'**
  String rateLimitReached(String time);

  /// Shows remaining API call count
  ///
  /// In en, this message translates to:
  /// **'API calls: {count} remaining'**
  String rateLimitRemaining(int count);

  /// Settings: API key section title
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get settingsApiKey;

  /// Hint in the API key text field
  ///
  /// In en, this message translates to:
  /// **'Paste your Wallhaven API key'**
  String get settingsApiKeyHint;

  /// Button to save the API key
  ///
  /// In en, this message translates to:
  /// **'Set API Key'**
  String get settingsApiKeySet;

  /// Confirmation when API key is cleared
  ///
  /// In en, this message translates to:
  /// **'API key cleared'**
  String get settingsApiKeyCleared;

  /// Link to get a Wallhaven API key
  ///
  /// In en, this message translates to:
  /// **'Get your free key'**
  String get settingsGetKey;

  /// Settings: appearance section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Theme mode: follow system
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceSystem;

  /// Theme mode: dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// Theme mode: light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// Filter sheet: categories section
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get filtersCategories;

  /// Filter category: general
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get filtersGeneral;

  /// Filter category: anime
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get filtersAnime;

  /// Filter category: people
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get filtersPeople;

  /// Filter sheet: sorting section
  ///
  /// In en, this message translates to:
  /// **'Sorting'**
  String get filtersSorting;

  /// Sort option: toplist
  ///
  /// In en, this message translates to:
  /// **'Toplist'**
  String get filtersToplist;

  /// Sort option: date added
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get filtersDateAdded;

  /// Sort option: relevance
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get filtersRelevance;

  /// Sort option: random
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get filtersRandom;

  /// Sort option: most viewed
  ///
  /// In en, this message translates to:
  /// **'Most Viewed'**
  String get filtersMostViewed;

  /// Sort option: most favorited
  ///
  /// In en, this message translates to:
  /// **'Most Favorited'**
  String get filtersMostFavorited;

  /// Filter sheet: photo type section
  ///
  /// In en, this message translates to:
  /// **'Photo Type'**
  String get filtersPhotoType;

  /// Photo type: both wallpapers and photos
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get filtersBoth;

  /// Photo type: wallpapers only
  ///
  /// In en, this message translates to:
  /// **'Wallpapers'**
  String get filtersWallpapers;

  /// Photo type: photos only
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get filtersPhotos;

  /// Filter sheet: apply button
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// Filter sheet: reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// Detail screen: download button
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get detailDownload;

  /// Detail screen: share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get detailShare;

  /// Detail screen: set as wallpaper action
  ///
  /// In en, this message translates to:
  /// **'Set Wallpaper'**
  String get detailSetWallpaper;

  /// Set wallpaper target: home screen
  ///
  /// In en, this message translates to:
  /// **'Home Screen'**
  String get detailHomeScreen;

  /// Set wallpaper target: lock screen
  ///
  /// In en, this message translates to:
  /// **'Lock Screen'**
  String get detailLockScreen;

  /// Set wallpaper target: both home and lock screen
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get detailBoth;

  /// Detail screen: favorites count label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get detailFavorites;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
