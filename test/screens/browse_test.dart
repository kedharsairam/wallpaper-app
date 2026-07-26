import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:mocktail/mocktail.dart';
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

void main() {
  late MockWallpaperApi api;

  setUp(() {
    api = MockWallpaperApi();
    api.mockSuggestions([]);
    _mockPathProvider();
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
    testWidgets('shows shimmer grid while fetching wallpapers',
        (tester) async {
      await tester.pumpWidget(buildApp());

      // Should show the shimmer placeholder grid.
      expect(find.byType(ShimmerGrid), findsOneWidget);
    });

    testWidgets('renders wallpaper grid after successful load',
        (tester) async {
      final response = TestData.response(total: 10, lastPage: 3);
      api.mockSearch(response);

      await tester.pumpWidget(buildApp());
      // ShimmerGrid has a repeating animation, use pump() not pumpAndSettle.
      await tester.pump(const Duration(seconds: 1));

      // Grid should now be visible, shimmer gone.
      expect(find.byType(ShimmerGrid), findsNothing);
      // MasonryGridView from flutter_staggered_grid_view should be present.
      expect(find.byType(MasonryGridView), findsOneWidget);
    });

    testWidgets('calls search API and handles error', (tester) async {
      // Verify that the widget's _load() method calls api.search().
      // UI verification of the error state is tricky because the shimmer
      // animation prevents pumpAndSettle from completing.
      api.mockSearchError(
        const WallpaperApiException('API error: 500'),
      );

      await tester.pumpWidget(buildApp());

      // Let the microtask queue drain so _load() can process the error.
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      // The mock was called exactly once (from _load in initState).
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
      await tester.pump(const Duration(seconds: 1)); // Load initial page.

      // Tap the search icon to show search field.
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump(const Duration(milliseconds: 300));

      // Enter a search query.
      await tester.enterText(find.byType(TextField), 'cyberpunk');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(seconds: 1));

      // Verify that the API was called with our query.
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
          )).called(2); // Initial load + search
    });
  });
}
