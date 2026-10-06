import 'package:flutter_test/flutter_test.dart';
import 'package:ev_charging_station/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EVChargingApp());
    expect(find.byType(EVChargingApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.byType(EVChargingApp), findsOneWidget);
  });
}
