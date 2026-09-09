import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_colaborador_segunda_version/services/usuario_service.dart';
import 'package:app_colaborador_segunda_version/services/sede_service.dart';
import 'package:app_colaborador_segunda_version/services/empleado_service.dart';
import 'package:app_colaborador_segunda_version/services/horario_service.dart';

void main() {
  group('UsuarioService', () {
    test('crearUsuario 201', () async {
      final mock = MockClient((req) async => http.Response(jsonEncode({'id': 10, 'email': 'n@lumibell.com'}), 201));
      final svc = UsuarioService(client: mock);
      final res = await svc.crearUsuario(token: 't', nombre: 'N', apellido: 'A', email: 'n@lumibell.com', password: '1234', rol: 'COLABORADOR');
      expect(res['id'], 10);
    });
    test('crearUsuario 409 throws ApiException', () async {
      final mock = MockClient((_) async => http.Response(jsonEncode({'error': 'El email ya está registrado'}), 409));
      final svc = UsuarioService(client: mock);
      expect(() => svc.crearUsuario(token: 't', nombre: 'N', apellido: 'A', email: 'dup@lumibell.com', password: '1234', rol: 'COLABORADOR'), throwsA(isA<ApiException>()));
    });
  });

  group('SedeService', () {
    test('crearSede 201', () async {
      final mock = MockClient((_) async => http.Response(jsonEncode({'id': 1, 'nombre': 'Sede X'}), 201));
      final svc = SedeService(client: mock);
      final res = await svc.crearSede(token: 't', nombre: 'Sede X', direccion: 'Av 1', latitud: -12.0, longitud: -77.0, radio: 100);
      expect(res['id'], 1);
    });
  });

  group('EmpleadoService', () {
    test('crearEmpleado 201', () async {
      final mock = MockClient((_) async => http.Response(jsonEncode({'id': 5}), 201));
      final svc = EmpleadoService(client: mock);
      final res = await svc.crearEmpleado(token: 't', usuarioId: 10, codigo: 'LUM-0004', cargo: 'Dev', modalidad: 'FULL_TIME', tipoHorario: 'FIJO', fechaIngreso: '2024-01-15');
      expect(res['id'], 5);
    });
    test('actualizarEmpleado PUT 200 (assign horario)', () async {
      final mock = MockClient((req) async {
        expect(req.method, 'PUT');
        return http.Response(jsonEncode({'id': 3, 'horario_id': 2}), 200);
      });
      final svc = EmpleadoService(client: mock);
      final res = await svc.actualizarEmpleado(token: 't', empleadoId: 3, cambios: {'horario_id': 2});
      expect(res['horario_id'], 2);
    });
  });

  group('HorarioService', () {
    test('crearHorario 201 con 7 dias', () async {
      final mock = MockClient((_) async => http.Response(jsonEncode({'id': 7}), 201));
      final svc = HorarioService(client: mock);
      final dias = List.generate(7, (i) => {'dia_semana': i+1, 'entrada': i==6?null:'10:00', 'ref_inicio': null, 'ref_fin': null, 'salida': i==6?null:'19:00', 'es_descanso': i==6});
      final res = await svc.crearHorario(token: 't', nombre: 'H', vigenciaDesde: '2026-01-01', dias: dias);
      expect(res['id'], 7);
    });
    test('crearHorario 400 throws', () async {
      final mock = MockClient((_) async => http.Response(jsonEncode({'error': 'dias debe ser'}), 400));
      final svc = HorarioService(client: mock);
      expect(() => svc.crearHorario(token: 't', nombre: 'H', vigenciaDesde: '2026-01-01', dias: []), throwsA(isA<ApiException>()));
    });
  });
}
