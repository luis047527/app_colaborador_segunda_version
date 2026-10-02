import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_colaborador_segunda_version/services/api_service.dart';

void main() {
  test('descarga PNG con Bearer y Accept sin colocar token en URL', () async {
    final bytes = [137, 80, 78, 71, 13, 10, 26, 10, 1];
    await http.runWithClient(() async {
      expect(await ApiService('session-test').getPng('/api/sedes/1/qr?formato=png'), bytes);
    }, () => MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer session-test');
      expect(request.headers['Accept'], 'image/png');
      expect(request.url.query, 'formato=png');
      return http.Response.bytes(bytes, 200, headers: {'content-type': 'image/png'});
    }));
  });
  test('error HTTP conserva mensaje y estado', () async {
    await http.runWithClient(() async {
      await expectLater(ApiService('test').getPng('/api/sedes/1/qr?formato=png'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'estado', 403).having((e) => e.message, 'mensaje', 'No autorizado')));
    }, () => MockClient((_) async => http.Response('{"error":"No autorizado"}', 403)));
  });
  test('no guarda JSON como si fuera PNG', () async {
    await http.runWithClient(() async {
      await expectLater(ApiService('test').getPng('/api/sedes/1/qr?formato=png'), throwsA(isA<ApiException>()));
    }, () => MockClient((_) async => http.Response('{}', 200, headers: {'content-type': 'application/json'})));
  });
}
