import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_colaborador_segunda_version/screens/asistencia/asistencia_screen.dart';
import 'package:app_colaborador_segunda_version/services/api_service.dart';

class _Api extends ApiService {
  _Api() : super('test');
  String? siteError;
  final paths = <String>[];

  @override
  Future<dynamic> get(String path) async {
    paths.add(path);
    if (path == '/api/empleados/me') return {'id': 3, 'sede_id': 1};
    if (path == '/api/empleados/3/horario') {
      return {'fecha': '2026-10-01', 'dia': {'entrada': '09:00', 'salida': '14:00', 'es_descanso': 0}};
    }
    if (path == '/api/empleados/me/sede') {
      if (siteError != null) throw ApiException(siteError!);
      return {'id': 1, 'nombre': 'Sede Lima', 'latitud': -12.04, 'longitud': -77.04, 'radio_permitido_metros': 100};
    }
    if (path.startsWith('/api/marcaciones/mio?')) return {'marcaciones': []};
    throw StateError('Consulta inesperada: $path');
  }
}

void main() {
  Future<void> showScreen(WidgetTester tester, _Api api) async {
    await tester.pumpWidget(MaterialApp(home: AsistenciaScreen(api: api, usuarioId: 3, onLogout: () {})));
    await tester.pumpAndSettle();
  }

  testWidgets('sede sin estado habilita validar GPS pero mantiene escaneo bloqueado', (tester) async {
    final api = _Api();
    await showScreen(tester, api);
    expect(find.text('Sede Lima'), findsOneWidget);
    final validate = tester.widget<FilledButton>(find.byWidgetPredicate((widget) => widget is FilledButton));
    expect(validate.onPressed, isNotNull);
    final dropdown = tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
    expect(dropdown.onChanged, isNull);
    expect(api.paths, contains('/api/empleados/me/sede'));
    expect(api.paths.any((path) => path.startsWith('/api/sedes/')), isFalse);
  });

  for (final message in ['Colaborador no activo', 'Sede no disponible']) {
    testWidgets('$message bloquea GPS y permite recuperar la sede al reintentar', (tester) async {
      final api = _Api()..siteError = message;
      await showScreen(tester, api);
      expect(find.text(message), findsWidgets);
      expect(tester.widget<FilledButton>(find.byWidgetPredicate((widget) => widget is FilledButton)).onPressed, isNull);
      api.siteError = null;
      final retry = find.text('Reintentar consulta de sede');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text('Sede Lima'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byWidgetPredicate((widget) => widget is FilledButton)).onPressed, isNotNull);
    });
  }
}
