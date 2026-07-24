import 'package:flutter_test/flutter_test.dart';
import 'package:wallhaven_client/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const WallhavenApp());
    expect(find.text('Wallhaven'), findsOneWidget);
  });
}
