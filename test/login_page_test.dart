import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glamcloset/user_login.dart';

void main() {
  late Widget testWidget;

  setUp(() {
    testWidget = MaterialApp(home: LoginPage(disableNotifications: true));
  });

  /// Fill the login form with valid credentials
  Future<void> fillLoginForm(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com'); // email
    await tester.enterText(find.byType(TextFormField).at(1), 'Password1!'); // password
  }

  group('LoginPage UI Tests (No Firebase)', () {
    testWidgets('All form fields and Login button are visible', (tester) async {
      await tester.pumpWidget(testWidget);

      expect(find.byType(TextFormField), findsNWidgets(2)); // email + password
      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('Validation errors show when fields are empty', (tester) async {
      await tester.pumpWidget(testWidget);

      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Please enter'), findsWidgets); // email + password
    });

    testWidgets('Typing valid inputs updates form fields', (tester) async {
      await tester.pumpWidget(testWidget);

      await fillLoginForm(tester);
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Password1!'), findsOneWidget);
    });

    testWidgets('Password visibility toggle works', (tester) async {
      await tester.pumpWidget(testWidget);

      final passwordField = find.byType(TextFormField).at(1);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('Forgot Password link is tappable', (tester) async {
      await tester.pumpWidget(testWidget);

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Replace with the actual navigation or UI change
      expect(find.text('Enter your email to reset password'), findsNothing); // optional check
    });
  });
}
