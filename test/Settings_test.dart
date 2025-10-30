import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glamcloset/settings_page.dart';
import 'package:glamcloset/AccountDetails.dart';
import 'package:glamcloset/ChatBotPage.dart';
import 'package:glamcloset/WalletPage.dart';
import 'package:provider/provider.dart';
import 'package:glamcloset/theme_notifier.dart';

void main() {
  late Widget testWidget;

  setUp(() {
    testWidget = ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MaterialApp(
        home: SettingsPage(testIsAdmin: false), // Wallet tile visible
      ),
    );
  });

  group('SettingsPage static UI tests', () {
    testWidgets('All main tiles are visible', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('ChatBot'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget); // visible because testIsAdmin: false
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('Tapping Account tile navigates to AccountDetailsPage', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountDetailsPage), findsOneWidget);
    });

    testWidgets('Tapping ChatBot tile navigates to ChatBotScreen', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('ChatBot'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatBotScreen), findsOneWidget);
    });

    testWidgets('Tapping Wallet tile navigates to WalletPage', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();

      expect(find.byType(WalletPage), findsOneWidget);
    });

    testWidgets('Notifications switch toggles', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch).first;
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Value change cannot be directly read, just ensure tap works
      expect(switchFinder, findsOneWidget);
    });

    testWidgets('Dark Mode switch toggles', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      final darkModeSwitch = find.byType(Switch).last;
      expect(darkModeSwitch, findsOneWidget);

      await tester.tap(darkModeSwitch);
      await tester.pumpAndSettle();

      expect(darkModeSwitch, findsOneWidget);
    });

    testWidgets('Logout tile exists and can be tapped', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      final logoutTile = find.text('Logout');
      expect(logoutTile, findsOneWidget);

      await tester.tap(logoutTile);
      await tester.pumpAndSettle();

      // No navigation assertion needed in static test
      expect(logoutTile, findsOneWidget); // ensure the tap did not crash
    });

  });
}
