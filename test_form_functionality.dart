import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maika_app/main.dart' as app;

void main() {
  group('Form Functionality Tests', () {
    testWidgets('Auth form validation should work correctly', (
      WidgetTester tester,
    ) async {
      // Build the app
      app.main();
      await tester.pumpAndSettle();

      // Find the email field
      final emailField = find.byType(TextFormField).first;
      expect(emailField, findsOneWidget);

      // Find the password field
      final passwordField = find.byType(TextFormField).at(1);
      expect(passwordField, findsOneWidget);

      // Test empty form validation
      final loginButton = find.text('Iniciar Sesión');
      expect(loginButton, findsOneWidget);

      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Por favor ingresa tu email'), findsOneWidget);
      expect(find.text('Por favor ingresa tu contraseña'), findsOneWidget);

      // Test with valid data
      await tester.enterText(emailField, 'demo@example.com');
      await tester.enterText(passwordField, 'demo123');
      await tester.pumpAndSettle();

      // Tap login button
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should navigate to main app (no validation errors)
      expect(find.text('Por favor ingresa tu email'), findsNothing);
      expect(find.text('Por favor ingresa tu contraseña'), findsNothing);
    });

    testWidgets('Registration form should show name field', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // Find and tap the switch to registration mode
      final switchButton = find.text('¿No tienes cuenta? Regístrate');
      expect(switchButton, findsOneWidget);

      await tester.tap(switchButton);
      await tester.pumpAndSettle();

      // Should now show name field
      expect(
        find.byType(TextFormField),
        findsNWidgets(3),
      ); // name, email, password

      // Test registration validation
      final registerButton = find.text('Registrarse');
      expect(registerButton, findsOneWidget);

      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Should show name validation error
      expect(find.text('Por favor ingresa tu nombre'), findsOneWidget);
    });

    testWidgets('Home screen should load verse of the day', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // Login first
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.text('Iniciar Sesión');

      await tester.enterText(emailField, 'demo@example.com');
      await tester.enterText(passwordField, 'demo123');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should be on home screen
      expect(find.text('Maika'), findsOneWidget);
      expect(find.text('Versículo del Día'), findsOneWidget);
    });

    testWidgets('Navigation buttons should work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login first
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);
      final loginButton = find.text('Iniciar Sesión');

      await tester.enterText(emailField, 'demo@example.com');
      await tester.enterText(passwordField, 'demo123');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Test main navigation cards
      final chatCard = find.text('Chat con IA');
      expect(chatCard, findsOneWidget);

      final exploreCard = find.text('Explorar');
      expect(exploreCard, findsOneWidget);

      // Test small navigation cards
      final favoritesCard = find.text('Favoritos');
      expect(favoritesCard, findsOneWidget);

      final readingPlanCard = find.text('Plan de lectura');
      expect(readingPlanCard, findsOneWidget);
    });
  });
}
