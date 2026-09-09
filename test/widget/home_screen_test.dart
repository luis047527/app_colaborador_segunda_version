import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app_colaborador_segunda_version/models/usuario.dart';
import 'package:app_colaborador_segunda_version/services/auth_service.dart';
import 'package:app_colaborador_segunda_version/screens/home/home_screen.dart';

class FakeAuthService extends AuthService {
  @override
  String? get token => 'fake-token';
  @override
  Usuario? get usuario => Usuario(
        id: 1,
        nombre: 'Luis',
        apellido: 'Bello',
        email: 'admin@lumibell.com',
        rol: 'ADMINISTRADOR',
        estado: 'ACTIVO',
      );
  @override
  bool get isAuthenticated => true;
}

void main() {
  Widget wrap(Widget child, AuthService auth) {
    return ChangeNotifierProvider<AuthService>.value(
      value: auth,
      child: MaterialApp(home: child),
    );
  }

  group('HomeScreen scaffold Semana 1', () {
    testWidgets('shows NavigationBar with 3 destinations', (tester) async {
      await tester.pumpWidget(wrap(const HomeScreen(), FakeAuthService()));
      expect(find.text('Inicio'), findsWidgets);
      expect(find.text('Horario'), findsWidgets);
      expect(find.text('Perfil'), findsWidgets);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('navigates between Inicio/Horario/Perfil', (tester) async {
      await tester.pumpWidget(wrap(const HomeScreen(), FakeAuthService()));

      // Initial InicioScreen shows Bienvenido
      expect(find.textContaining('Bienvenido'), findsOneWidget);

      // Tap Horario
      await tester.tap(find.text('Horario'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Mi Horario'), findsOneWidget);

      // Tap Perfil
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('admin@lumibell.com'), findsOneWidget);
    });

    testWidgets('appBar title changes with index', (tester) async {
      await tester.pumpWidget(wrap(const HomeScreen(), FakeAuthService()));
      expect(find.widgetWithText(AppBar, 'Inicio'), findsOneWidget);
      await tester.tap(find.text('Horario'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Horario'), findsOneWidget);
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Perfil'), findsOneWidget);
    });
  });
}
