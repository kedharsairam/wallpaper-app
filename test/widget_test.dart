import 'package:flutter_test/flutter_test.dart';
import 'package:wallhaven_client/app.dart';
import 'package:wallhaven_client/api/client.dart';

void main() {
  testWidgets('App renders app bar title', (WidgetTester tester) async {
    final api = WallhavenApi();
    await tester.pumpWidget(WallKraftApp(api: api));
    // App bar renders synchronously before API calls complete
    expect(find.text('WallKraft'), findsOneWidget);
  });
}
