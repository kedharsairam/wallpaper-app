import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wallkraft/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('WallKraft App', () {
    testWidgets('launches and shows browse screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // The app should launch without crashing.
      // After loading, it shows either the wallpaper grid or the shimmer.
      // The bottom navigation should be visible.
      expect(find.text('Browse'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Downloads'), findsOneWidget);
    });

    testWidgets('can navigate between tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Tap on Favorites tab.
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      // Favorites screen shows either empty state or list.
      expect(find.text('Favorites'), findsOneWidget);

      // Tap on Downloads tab.
      await tester.tap(find.text('Downloads'));
      await tester.pumpAndSettle();
      expect(find.text('Downloads'), findsOneWidget);

      // Tap back to Browse tab.
      await tester.tap(find.text('Browse'));
      await tester.pumpAndSettle();
      expect(find.text('Browse'), findsOneWidget);
    });

    testWidgets('search field appears when search icon is tapped',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Find and tap the search icon button.
      final searchIcon = find.byIcon(Icons.search);
      expect(searchIcon, findsOneWidget);

      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      // Search field should now appear.
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
