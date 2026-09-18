import 'package:flutter_test/flutter_test.dart';
import 'package:b2b_system/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const WarehouseEliteApp());
    expect(find.text('Warehouse Elite'), findsOneWidget);
  });
}
