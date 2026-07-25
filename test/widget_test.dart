import 'package:flutter_test/flutter_test.dart';
import 'package:wallhaven_client/app.dart';
import 'package:wallhaven_client/api/client.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    final api = WallhavenApi();
    await tester.pumpWidget(WallKraftApp(api: api));
    expect(find.text('WallKraft'), findsOneWidget);
  });
}
