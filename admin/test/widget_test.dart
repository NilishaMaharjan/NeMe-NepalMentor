//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/main.dart'; // Import the main file where MyApp is located
import 'package:admin/screens/dashboard.dart'; // Import the correct dashboard file

void main() {
  testWidgets('Admin Dashboard loads correctly', (WidgetTester tester) async {
    // Build the MyApp widget and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify if the DashboardPage widget is loaded.
    expect(find.byType(DashboardPage), findsOneWidget);

    // Optionally, you can test for other elements, e.g., buttons, text, etc.
    // Example:
    // expect(find.text('Admin Dashboard'), findsOneWidget); // If your dashboard has this text
  });
}
