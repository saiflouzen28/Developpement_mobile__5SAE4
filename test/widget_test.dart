import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:elearning_events_app/main.dart';
import 'package:elearning_events_app/providers/auth_provider.dart';
import 'package:elearning_events_app/providers/events_provider.dart';

void main() {
  testWidgets('App starts with login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => EventsProvider()),
        ],
        child: const MaterialApp(
          home: MyApp(),
        ),
      ),
    );

    // Verify that the login screen is displayed.
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to continue your learning journey'), findsOneWidget);
  });

  testWidgets('Login form validation works', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => EventsProvider()),
        ],
        child: const MaterialApp(
          home: MyApp(),
        ),
      ),
    );

    // Try to login with empty fields
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    // Should show validation errors
    expect(find.text('Please enter your email'), findsOneWidget);
  });
}