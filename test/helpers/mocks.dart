import 'package:mocktail/mocktail.dart';
import 'package:wallkraft/api/client.dart';
import 'package:wallkraft/models/wallpaper.dart';

/// Manual mock for [WallpaperApi] using mocktail.
class MockWallpaperApi extends Mock implements WallpaperApi {
  /// Stub [search] to return the given response.
  void mockSearch(WallpaperResponse response) {
    when(() => search(
          query: any(named: 'query'),
          categories: any(named: 'categories'),
          purity: any(named: 'purity'),
          sorting: any(named: 'sorting'),
          order: any(named: 'order'),
          topRange: any(named: 'topRange'),
          ratios: any(named: 'ratios'),
          page: any(named: 'page'),
          cancelToken: any(named: 'cancelToken'),
        )).thenAnswer((_) async => response);
  }

  /// Stub [search] to throw the given error.
  void mockSearchError(Object error) {
    when(() => search(
          query: any(named: 'query'),
          categories: any(named: 'categories'),
          purity: any(named: 'purity'),
          sorting: any(named: 'sorting'),
          order: any(named: 'order'),
          topRange: any(named: 'topRange'),
          ratios: any(named: 'ratios'),
          page: any(named: 'page'),
          cancelToken: any(named: 'cancelToken'),
        )).thenThrow(error);
  }

  /// Stub [wallpaper] to return the given wallpaper.
  void mockWallpaper(Wallpaper wp) {
    when(() => wallpaper(
          any(),
          cancelToken: any(named: 'cancelToken'),
        )).thenAnswer((_) async => wp);
  }

  /// Stub [wallpaper] to throw the given error.
  void mockWallpaperError(Object error) {
    when(() => wallpaper(
          any(),
          cancelToken: any(named: 'cancelToken'),
        )).thenThrow(error);
  }

  /// Stub [suggestions] to return the given list.
  void mockSuggestions(List<String> results) {
    when(() => suggestions(any())).thenAnswer((_) async => results);
  }
}
