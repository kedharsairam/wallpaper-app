import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallkraft/api/exception.dart';
import 'package:wallkraft/screens/browse.dart';
import 'package:wallkraft/widgets/shimmer_grid.dart';
import '../helpers/mocks.dart';
import '../helpers/test_data.dart';

/// Sets up mock handlers for [path_provider] method channels so that
/// [CachedNetworkImage] and [CacheService] can function in tests.
void _mockPathProvider() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'getTemporaryDirectory':
        return Directory.systemTemp.path;
      case 'getApplicationDocumentsDirectory':
        return Directory.systemTemp.path;
      case 'getApplicationSupportDirectory':
        return Directory.systemTemp.path;
      case 'getStorageDirectory':
        return Directory.systemTemp.path;
    }
    return null;
  });
}

/// Helper to enter browse mode by tapping a quick filter chip on the homepage.
/// Caller must have stubbed api.search() first.
Future<void> enterBrowseMode(WidgetTester tester) async {
  await tester.tap(find.text('Latest'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  late MockWallpaperApi api;

  setUp(() {
    api = MockWallpaperApi();
    api.mockSuggestions([]);
    _mockPathProvider();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  Widget buildApp() {
    return MaterialApp(
      home: BrowseScreen(api: api),
    );
  }

  group('BrowseScreen', () {
    testWidgets('starts on homepage, transitions to browse mode on filter tap',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Should start on the homepage with branding visible.
      expect(find.text('WallKraft'), findsOneWidget);
      expect(find.byType(ShimmerGrid), findsNothing);

      // Stub search and tap a quick filter to enter browse mode.
      api.mockSearch(TestData.response(total: 10));
      await enterBrowseMode(tester);

      // Homepage is gone, grid is visible.
      expect(find.text('WallKraft'), findsNothing);
      expect(find.byType(ShimmerGrid), findsNothing);
      expect(find.byType(MasonryGridView), findsOneWidget);
    });

    testWidgets('renders wallpaper grid after successful load',
        (tester) async {
      final response = TestData.response(total: 10, lastPage: 3);
      api.mockSearch(response);

      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Enter browse mode via quick filter chip.
      await enterBrowseMode(tester);

      // Grid should now be visible.
      expect(find.byType(ShimmerGrid), findsNothing);
      expect(find.byType(MasonryGridView), findsOneWidget);
    });

    testWidgets('calls search API when entering browse mode',
        (tester) async {
      // Stub search to throw so we can verify the call without loading.
      api.mockSearchError(
        const WallpaperApiException('API error: 500'),
      );

      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Enter browse mode — this triggers _load() via _onQuickFilter.
      await enterBrowseMode(tester);
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      // The mock was called exactly once (from _load).
      verify(() => api.search(
            query: any(named: 'query'),
            page: any(named: 'page'),
            cancelToken: any(named: 'cancelToken'),
            categories: any(named: 'categories'),
            purity: any(named: 'purity'),
            sorting: any(named: 'sorting'),
            order: any(named: 'order'),
            topRange: any(named: 'topRange'),
            ratios: any(named: 'ratios'),
          )).called(1);
    });

    testWidgets('uses search query in API call when submitted',
        (tester) async {
      final response = TestData.response(total: 1);
      api.mockSearch(response);

      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Enter browse mode (first API call).
      await enterBrowseMode(tester);

      // Find the search TextField in the app bar.
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter a search query and submit.
      await tester.enterText(searchField, 'cyberpunk');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(seconds: 1));

      // API called twice: initial load + search.
      verify(() => api.search(
            query: any(named: 'query'),
            page: any(named: 'page'),
            cancelToken: any(named: 'cancelToken'),
            categories: any(named: 'categories'),
            purity: any(named: 'purity'),
            sorting: any(named: 'sorting'),
            order: any(named: 'order'),
            topRange: any(named: 'topRange'),
            ratios: any(named: 'ratios'),
          )).called(2);
    });
  });
}
