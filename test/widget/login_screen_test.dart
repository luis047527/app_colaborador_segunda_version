import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_colaborador_segunda_version/screens/login/login_screen.dart';
import 'package:app_colaborador_segunda_version/services/auth_service.dart';

void main() {
  group('LoginScreen Semana 1', () {
    testWidgets('renders usuario, contraseña, ingresar y footer', (tester) async {
      final auth = AuthService();
      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(authService: auth)),
      );

      expect(find.text('Usuario'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Ingresar'), findsOneWidget);
      expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
      expect(find.text('Asistencia Lumibell'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('validacion vacios muestra mensajes', (tester) async {
      final auth = AuthService();
      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(authService: auth)),
      );

      // hint exists before validation, error adds second instance
      expect(find.text('Ingresa tu usuario'), findsOneWidget);
      await tester.ensureVisible(find.text('Ingresar'));
      await tester.tap(find.text('Ingresar'));
      await tester.pump();

      // after validation hint + error => 2, plus contraseña error => total 3 hints/errors
      expect(find.text('Ingresa tu usuario'), findsNWidgets(2));
      expect(find.text('Ingresa tu contraseña'), findsNWidgets(2));
    });

    testWidgets('password toggle cambia visibilidad', (tester) async {
      final auth = AuthService();
      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(authService: auth)),
      );

      // initially obscure, icon visibility_outlined
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('tap olvidaste muestra dialog pendiente', (tester) async {
      final auth = AuthService();
      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(authService: auth)),
      );

      final olvidaste = find.text('¿Olvidaste tu contraseña?');
      await tester.ensureVisible(olvidaste);
      await tester.tap(olvidaste, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Recuperación de contraseña'), findsOneWidget);
      expect(find.text('Funcionalidad pendiente de conexión con el servidor.'), findsOneWidget);
      expect(find.text('Entendido'), findsOneWidget);

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('Recuperación de contraseña'), findsNothing);
    });

    testWidgets('password corta muestra validacion longitud', (tester) async {
      final auth = AuthService();
      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(authService: auth)),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'admin@lumibell.com');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.ensureVisible(find.text('Ingresar'));
      await tester.tap(find.text('Ingresar'));
      await tester.pump();

      expect(find.text('Ingresa una contraseña válida'), findsOneWidget);
    });
  });
}
