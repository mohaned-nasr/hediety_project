import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/main.dart'; // Adjust based on your app structure

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before tests run
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('Hedieaty App Integration Test - Registration and Login', () {
    testWidgets('User Registration and Login', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Tap the registration link using the Key
      final registerNavigationButton = find.byKey(Key('registerNavigationButton'));
      expect(registerNavigationButton, findsOneWidget);
      await tester.tap(registerNavigationButton);
      await tester.pumpAndSettle();

      // Fill out the registration form
      await tester.enterText(find.byType(TextField).at(0), 'Test User'); // Name
      await tester.enterText(find.byType(TextField).at(1), '1234567890'); // Phone
      await tester.enterText(find.byType(TextField).at(2), 'testuser2@example.com'); // Email
      await tester.enterText(find.byType(TextField).at(3), 'Password123'); // Password
      await tester.enterText(find.byType(TextField).at(4), 'Password123'); // Confirm Password

      // Tap the Register button using the Key
      final registerButton = find.byKey(Key('registerButton'));
      expect(registerButton, findsOneWidget);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Verify successful registration and redirection to the login page
      final loginHeader = find.text('Welcome to Hedieaty!');
      expect(loginHeader, findsOneWidget);

      // Fill out the login form
      await tester.enterText(find.byType(TextField).at(0), 'testuser@example.com'); // Email
      await tester.enterText(find.byType(TextField).at(1), 'Password123'); // Password

      // Tap the Login button using the Key
      final loginButton = find.byKey(Key('loginButton'));
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify successful login
      final homePage = find.text('Home');
      expect(homePage, findsOneWidget);
    });

  });
  testWidgets('Create Event', (WidgetTester tester) async {
    // Ensure app is logged in and on the Home page
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Tap the "Create Event" button using the Key
    final createEventButton = find.byKey(Key('createEventButton'));
    expect(createEventButton, findsOneWidget);
    await tester.tap(createEventButton);
    await tester.pumpAndSettle();

    // Fill out the event form with sample data
    await tester.enterText(find.byKey(Key('eventNameField')), 'Birthday Party');
    await tester.enterText(find.byKey(Key('eventLocationField')), 'Party Hall');
    await tester.enterText(find.byKey(Key('eventDescriptionField')), 'A fun birthday celebration');
    await tester.enterText(find.byKey(Key('eventCategoryField')), 'Celebration');

    // Tap the Add button using the Key
    final addEventButton = find.byKey(Key('addEventButton'));
    expect(addEventButton, findsOneWidget);
    await tester.tap(addEventButton);
    await tester.pumpAndSettle();

    // Verify that the event has been added (check for success message or the event in the list)
    final eventName = find.text('Birthday Party');
    expect(eventName, findsOneWidget);
  });
}
