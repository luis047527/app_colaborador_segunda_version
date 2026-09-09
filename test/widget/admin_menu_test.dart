import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app_colaborador_segunda_version/models/usuario.dart';
import 'package:app_colaborador_segunda_version/services/auth_service.dart';
import 'package:app_colaborador_segunda_version/screens/home/home_screen.dart';
import 'package:app_colaborador_segunda_version/screens/admin/admin_menu_screen.dart';

class FakeAdmin extends AuthService {
  @override
  Usuario? get usuario => Usuario(id: 1, nombre: 'Luis', apellido: 'Bello', email: 'admin@lumibell.com', rol: 'ADMINISTRADOR', estado: 'ACTIVO');
  @override bool get isAuthenticated => true;
  @override String? get token => 't';
}
class FakeColab extends AuthService {
  @override
  Usuario? get usuario => Usuario(id: 3, nombre: 'Carlos', apellido: 'Colab', email: 'colaborador@lumibell.com', rol: 'COLABORADOR', estado: 'ACTIVO');
  @override bool get isAuthenticated => true;
  @override String? get token => 't';
}

void main() {
  testWidgets('Admin sees 4 tabs including Admin', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider<AuthService>.value(value: FakeAdmin(), child: const MaterialApp(home: HomeScreen())));
    expect(find.text('Admin'), findsWidgets);
    expect(find.byIcon(Icons.admin_panel_settings_outlined), findsOneWidget);
    expect(find.text('Inicio'), findsWidgets);
  });

  testWidgets('Colaborador sees 3 tabs without Admin', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider<AuthService>.value(value: FakeColab(), child: const MaterialApp(home: HomeScreen())));
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Horario'), findsWidgets);
  });

  testWidgets('AdminMenu shows 5 create tiles', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AdminMenuScreen())));
    expect(find.text('Crear Usuario'), findsOneWidget);
    expect(find.text('Crear Sede'), findsOneWidget);
    expect(find.text('Crear Empleado'), findsOneWidget);
    expect(find.textContaining('Crear Horario'), findsOneWidget);
    expect(find.textContaining('Asignar Horario'), findsOneWidget);
  });

  testWidgets('Create screens render forms', (tester) async {
    // spot check a couple create screens via navigation
    await tester.pumpWidget(ChangeNotifierProvider<AuthService>.value(value: FakeAdmin(), child: const MaterialApp(home: HomeScreen())));
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear Usuario'));
    await tester.pumpAndSettle();
    expect(find.text('Crear Usuario'), findsWidgets);
    expect(find.text('Nombre'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear Sede'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Crear Sede'), findsOneWidget);
  });
}
