import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_colaborador_segunda_version/services/auth_service.dart';

void main() {
  group('AuthService Semana 1', () {
    test('login 200 parses token + usuario y notifica', () async {
      final mock = MockClient((req) async {
        expect(req.url.path, '/api/auth/login');
        expect(req.method, 'POST');
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['email'], 'admin@lumibell.com');
        return http.Response(
          jsonEncode({
            'token': 'fake-jwt-token',
            'usuario': {
              'id': 1,
              'nombre': 'Luis',
              'apellido': 'Bello',
              'email': 'admin@lumibell.com',
              'foto_url': null,
              'rol': 'ADMINISTRADOR',
              'estado': 'ACTIVO',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final auth = AuthService(client: mock);
      var notified = false;
      auth.addListener(() => notified = true);

      await auth.login('admin@lumibell.com', 'Lumibell2026');

      expect(auth.isAuthenticated, isTrue);
      expect(auth.token, 'fake-jwt-token');
      expect(auth.usuario?.email, 'admin@lumibell.com');
      expect(auth.usuario?.nombreCompleto, 'Luis Bello');
      expect(notified, isTrue);
    });

    test('login 401 throws Credenciales inválidas', () async {
      final mock = MockClient((_) async => http.Response(jsonEncode({'error': 'any'}), 401));
      final auth = AuthService(client: mock);
      expect(
        () => auth.login('bad@lumibell.com', 'wrong'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Credenciales inválidas')),
      );
      expect(auth.isAuthenticated, isFalse);
    });

    test('login 403 throws Usuario inactivo o bloqueado', () async {
      final mock = MockClient((_) async => http.Response(jsonEncode({'error': 'any'}), 403));
      final auth = AuthService(client: mock);
      expect(
        () => auth.login('blocked@lumibell.com', 'Lumibell2026'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Usuario inactivo o bloqueado')),
      );
    });

    test('login 400 con error del body propaga mensaje', () async {
      final mock = MockClient((_) async => http.Response(jsonEncode({'error': 'email y password son obligatorios'}), 400));
      final auth = AuthService(client: mock);
      expect(
        () => auth.login('', ''),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'email y password son obligatorios')),
      );
    });

    test('login network exception propaga (manejado por LoginScreen como No se pudo conectar)', () async {
      final mock = MockClient((_) async => throw Exception('network'));
      final auth = AuthService(client: mock);
      expect(() => auth.login('a@b.com', '1234'), throwsException);
    });

    test('logout limpia token y usuario y notifica', () async {
      final mock = MockClient((_) async => http.Response(
            jsonEncode({
              'token': 't',
              'usuario': {'id': 1, 'nombre': 'A', 'apellido': 'B', 'email': 'a@b.com', 'foto_url': null, 'rol': 'COLABORADOR', 'estado': 'ACTIVO'}
            }),
            200,
          ));
      final auth = AuthService(client: mock);
      await auth.login('a@b.com', '1234');
      expect(auth.isAuthenticated, isTrue);
      var notified = false;
      auth.addListener(() => notified = true);
      auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.token, isNull);
      expect(auth.usuario, isNull);
      expect(notified, isTrue);
    });
  });
}
