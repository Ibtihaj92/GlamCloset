import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glamcloset/UsersManagementPage.dart';

void main() {
  final testUsers = [
    {"id": "1", "email": "user1@test.com", "phone": "12345"},
    {"id": "2", "email": "user2@test.com", "phone": "67890"},
  ];

  // Helper function to create the widget
  Widget createWidget(List<Map<String, String>> users) {
    return MaterialApp(home: UsersManagementPage(testUsers: users));
  }

  testWidgets('Displays all users correctly', (tester) async {
    await tester.pumpWidget(createWidget(testUsers));
    await tester.pumpAndSettle();

    // Verify both users are displayed
    expect(find.text('user1@test.com'), findsOneWidget);
    expect(find.text('user2@test.com'), findsOneWidget);

    // Verify delete buttons exist
    expect(find.byIcon(Icons.delete), findsNWidgets(2));
  });

  testWidgets('Delete button removes a user', (tester) async {
    await tester.pumpWidget(createWidget(testUsers));
    await tester.pumpAndSettle();

    // Tap delete button for first user
    await tester.tap(find.byIcon(Icons.delete).first);
    await tester.pumpAndSettle();

    // First user should be removed
    expect(find.text('user1@test.com'), findsNothing);
    // Second user should remain
    expect(find.text('user2@test.com'), findsOneWidget);

    // Only one delete button should remain
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('Shows "No users available" when list is empty', (tester) async {
    await tester.pumpWidget(createWidget([]));
    await tester.pumpAndSettle();

    // Empty state text should be visible
    expect(find.text('No users available'), findsOneWidget);

    // No delete buttons should be visible
    expect(find.byIcon(Icons.delete), findsNothing);
  });
}
