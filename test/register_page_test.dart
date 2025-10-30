import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glamcloset/user_register.dart';

void main() {
  late Widget testWidget;

  setUp(() {
    testWidget = MaterialApp(home: UserRegister());

  });

  /// Fill the form with valid data
  Future<void> fillForm(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com'); // email
    await tester.enterText(find.byType(TextFormField).at(1), 'Password1!'); // password
    await tester.enterText(find.byType(TextFormField).at(2), '91234567'); // phone
    // Select city
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muscat').last);
    await tester.pumpAndSettle();
  }

  group('UserRegisterPage UI Tests (No Firebase)', () {
    testWidgets('All form fields and Register button are visible', (tester) async {
      await tester.pumpWidget(testWidget);

      // 3 TextFormFields: email, password, phone + 1 Dropdown for city
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('REGISTER'), findsOneWidget);
    });

    testWidgets('Validation errors show when fields are empty', (tester) async {
      await tester.pumpWidget(testWidget);

      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Please enter'), findsWidgets); // email, password, phone
      expect(find.textContaining('Please select a city'), findsOneWidget);
    });

    testWidgets('Typing valid inputs updates form fields', (tester) async {
      await tester.pumpWidget(testWidget);

      await fillForm(tester);
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Password1!'), findsOneWidget);
      expect(find.text('91234567'), findsOneWidget);
      expect(find.text('Muscat'), findsOneWidget);
    });

    testWidgets('Invalid email shows error', (tester) async {
      await tester.pumpWidget(testWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('Invalid phone shows error', (tester) async {
      await tester.pumpWidget(testWidget);

      await tester.enterText(find.byType(TextFormField).at(2), '1234');
      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();

      expect(find.text('Phone must start with 9 or 7 and be 8 digits'), findsOneWidget);
    });

    testWidgets('Password less than 8 chars shows error', (tester) async {
      await tester.pumpWidget(testWidget);

      await tester.enterText(find.byType(TextFormField).at(1), 'short');
      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });
  });
}
