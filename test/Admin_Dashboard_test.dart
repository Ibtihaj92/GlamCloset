import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:glamcloset/AdminDashboardPage.dart';
import 'package:glamcloset/theme_notifier.dart';

void main() {
  late Widget testWidget;

  setUp(() {
    testWidget = ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MaterialApp(home: AdminDashboardPage()),
    );
  });

  testWidgets('All dashboard cards are visible', (tester) async {
    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    // Find all GestureDetector cards
    final cards = find.byType(GestureDetector);
    expect(cards, findsNWidgets(5)); // you have 5 cards
  });

  testWidgets('Tapping a card has onTap handler', (tester) async {
    await tester.pumpWidget(testWidget);
    await tester.pumpAndSettle();

    final cards = find.byType(GestureDetector);

    // Make sure each card has a non-null onTap
    cards.evaluate().forEach((element) {
      final gestureDetector = element.widget as GestureDetector;
      expect(gestureDetector.onTap, isNotNull);
    });
  });
}
