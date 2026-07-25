import 'package:flutter_test/flutter_test.dart';
import 'package:wallhaven_client/app.dart';
import 'package:wallhaven_client/api/client.dart';
import 'package:wallhaven_client/models/wallpaper.dart';
import 'package:wallhaven_client/services/update_checker.dart';

void main() {
  test('WallhavenApi can be instantiated', () {
    final api = WallhavenApi();
    expect(api, isNotNull);
  });

  testWidgets('App renders app bar title', (WidgetTester tester) async {
    final api = WallhavenApi();
    final updater = UpdateChecker(currentVersion: '1.0.0');
    await tester.pumpWidget(WallKraftApp(api: api, updater: updater));
    expect(find.text('WallKraft'), findsOneWidget);
  });

  test('Wallpaper fromJson handles empty data gracefully', () {
    final result = WallhavenResponse.fromJson({
      'data': [],
      'meta': {'current_page': 1, 'last_page': 0, 'per_page': 24, 'total': 0},
    });
    expect(result.data, isEmpty);
    expect(result.meta.total, 0);
  });

  test('Wallpaper fromJson handles null fields gracefully', () {
    final wp = Wallpaper.fromJson({
      'id': '123',
      'url': null,
      'path': null,
      'thumbs': null,
      'tags': null,
    });
    expect(wp.id, '123');
    expect(wp.url, '');
    expect(wp.thumbnail, '');
    expect(wp.tags, isEmpty);
  });
}
