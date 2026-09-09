import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app_colaborador_segunda_version/models/usuario.dart';
import 'package:app_colaborador_segunda_version/services/auth_service.dart';
import 'package:app_colaborador_segunda_version/screens/inicio/inicio_screen.dart';
import 'package:app_colaborador_segunda_version/screens/perfil/perfil_screen.dart';
import 'package:app_colaborador_segunda_version/screens/horario/horario_screen.dart';

class FakeAuth extends AuthService {
  @override
  Usuario? get usuario => Usuario(
        id: 3,
        nombre: 'Carlos',
        apellido: 'Colaborador',
        email: 'colaborador@lumibell.com',
        rol: 'COLABORADOR',
        estado: 'ACTIVO',
      );
  @override
  bool get isAuthenticated => true;
  @override
  String? get token => 't';
}

Widget wrap(Widget child) => ChangeNotifierProvider<AuthService>.value(
      value: FakeAuth(),
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('InicioScreen muestra bienvenida y rango', (tester) async {
    await tester.pumpWidget(wrap(const InicioScreen()));
    expect(find.textContaining('Bienvenido, Carlos Colaborador'), findsOneWidget);
    expect(find.text('COLABORADOR'), findsOneWidget);
    expect(find.textContaining('Semana 1'), findsOneWidget);
  });

  testWidgets('PerfilScreen muestra datos usuario', (tester) async {
    await tester.pumpWidget(wrap(const PerfilScreen()));
    expect(find.text('Carlos Colaborador'), findsOneWidget);
    expect(find.text('colaborador@lumibell.com'), findsOneWidget);
    expect(find.textContaining('Rol: COLABORADOR'), findsOneWidget);
    expect(find.text('Sede'), findsOneWidget);
  });

  testWidgets('HorarioScreen placeholder muestra cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: HorarioScreen())));
    expect(find.textContaining('Mi Horario'), findsOneWidget);
    expect(find.text('Horario asignado'), findsOneWidget);
    expect(find.text('Horas requeridas'), findsOneWidget);
  });
}
