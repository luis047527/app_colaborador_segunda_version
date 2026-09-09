import 'package:flutter_test/flutter_test.dart';
import 'package:app_colaborador_segunda_version/models/usuario.dart';

void main() {
  group('Usuario', () {
    test('fromJson parses fields', () {
      final json = {
        'id': 1,
        'nombre': 'Luis',
        'apellido': 'Bello',
        'email': 'admin@lumibell.com',
        'foto_url': null,
        'rol': 'ADMINISTRADOR',
        'estado': 'ACTIVO',
      };
      final u = Usuario.fromJson(json);
      expect(u.id, 1);
      expect(u.nombre, 'Luis');
      expect(u.apellido, 'Bello');
      expect(u.email, 'admin@lumibell.com');
      expect(u.rol, 'ADMINISTRADOR');
      expect(u.estado, 'ACTIVO');
      expect(u.fotoUrl, isNull);
    });

    test('nombreCompleto concatenates', () {
      final u = Usuario(
        id: 2,
        nombre: 'Maria',
        apellido: 'Supervisor',
        email: 'supervisor@lumibell.com',
        rol: 'SUPERVISOR',
        estado: 'ACTIVO',
      );
      expect(u.nombreCompleto, 'Maria Supervisor');
    });
  });
}
