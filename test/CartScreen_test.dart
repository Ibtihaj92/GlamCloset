import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glamcloset/CartScreen.dart';

void main() {
  final fakeCartItems = [
    {'id': '1', 'title': 'Omani Dress', 'price': '50', 'age': '25', 'image': null},
    {'id': '2', 'title': 'Abaya', 'price': '30', 'age': '20', 'image': null},
  ];

  late Widget testWidget;

  setUp(() {
    testWidget = MaterialApp(
      home: CartScreen(rentedItems: fakeCartItems, skipFirebase: true),
    );
  });

  testWidgets('Displays all cart items and totals', (tester) async {
    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    // Cart items
    expect(find.text('Omani Dress'), findsOneWidget);
    expect(find.text('Abaya'), findsOneWidget);

    // Totals
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Deposit Security'), findsOneWidget);
    expect(find.text('40.00 OMR'), findsOneWidget); // 2*20 OMR
    expect(find.text('Grand Total'), findsOneWidget);
    expect(find.text('120.00 OMR'), findsOneWidget); // 50+30+40
  });

  testWidgets('Deleting an item removes it from the list', (tester) async {
    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Omani Dress'), findsNothing);
    expect(find.text('Abaya'), findsOneWidget);
  });
}
