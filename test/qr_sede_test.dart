import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app_colaborador_segunda_version/screens/asistencia/qr_sede_screen.dart';
import 'package:app_colaborador_segunda_version/services/api_service.dart';

class _Api extends ApiService {
  _Api() : super('test');
  final posts = <String>[];
  final downloads = <String>[];
  String value = 'LUMIBELL-SEDE-1-AAAA1111';
  bool missing = false;
  bool fail = false;
  @override
  Future<dynamic> get(String path) async {
    if (path == '/api/sedes') return [{'id': 1, 'nombre': 'Lima', 'estado': 'ACTIVA'}, {'id': 2, 'nombre': 'Sur', 'estado': 'ACTIVA'}];
    if (fail) throw ApiException('Sin autorización', statusCode: 403);
    if (missing || path == '/api/sedes/2/qr') throw ApiException('Sede sin QR generado, use POST /api/sedes/:id/qr', statusCode: 404);
    return {'qr_valor': value};
  }
  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    posts.add(path);
    value = 'LUMIBELL-SEDE-1-BBBB2222';
    return {'qr_valor': value};
  }
  @override
  Future<Uint8List> getPng(String path) async {
    downloads.add(path);
    return Uint8List.fromList([1, 2, 3]);
  }
}

void main() {
  Future<void> open(WidgetTester tester, _Api api, {Future<void> Function(Uint8List, String)? save}) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: QrSedeScreen(api: api, savePng: save)));
    await tester.pumpAndSettle();
  }
  Future<void> tap(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    if (text == 'Regenerar QR') {
      // La pantalla mantiene un indicador activo mientras espera confirmación.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    } else {
      await tester.pumpAndSettle();
    }
  }
  testWidgets('consulta sin rotar; cancelar preserva y confirmar regenera', (tester) async {
    final api = _Api();
    await open(tester, api);
    expect(api.posts, isEmpty);
    expect(find.byType(QrImageView), findsOneWidget);
    await tap(tester, 'Regenerar QR');
    await tap(tester, 'Cancelar');
    expect(api.posts, isEmpty);
    await tap(tester, 'Regenerar QR');
    await tap(tester, 'Regenerar');
    expect(api.posts, ['/api/sedes/1/qr']);
    expect(find.byType(QrImageView), findsOneWidget);
  });
  testWidgets('sede sin QR permite generar y cambiar sede elimina el anterior', (tester) async {
    final api = _Api()..missing = true;
    await open(tester, api);
    await tap(tester, 'Generar QR');
    expect(api.posts, ['/api/sedes/1/qr']);
    final dropdown = find.byType(DropdownButton<int>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sur').last);
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
  });
  testWidgets('descarga bytes del endpoint PNG sin regenerar', (tester) async {
    final api = _Api();
    String? savedName;
    await open(tester, api, save: (bytes, name) async {
      expect(bytes, [1, 2, 3]); savedName = name;
    });
    await tap(tester, 'Descargar PNG');
    expect(api.downloads, ['/api/sedes/1/qr?formato=png']);
    expect(savedName, 'lumibell-sede-1');
    expect(api.posts, isEmpty);
  });
  testWidgets('error de permisos no se confunde con sede sin QR', (tester) async {
    await open(tester, _Api()..fail = true);
    expect(find.text('Sin autorización'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byWidgetPredicate((w) => w is FilledButton));
    expect(button.onPressed, isNull);
  });
}
