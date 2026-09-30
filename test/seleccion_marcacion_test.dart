import 'package:flutter_test/flutter_test.dart';
import 'package:app_colaborador_segunda_version/models/seleccion_marcacion.dart';

void main() {
  final full = <String, dynamic>{'entrada': '09:00', 'salida': '18:00', 'ref_inicio': '13:00', 'ref_fin': '14:00', 'es_descanso': 0};
  final simple = {...full, 'ref_inicio': null, 'ref_fin': null};

  test('la jornada con refrigerio avanza por cada tipo sin duplicarlo', () {
    final accepted = <String>[];
    for (final type in SeleccionMarcacion.apiSequence) {
      final selection = SeleccionMarcacion(full, accepted);
      expect(selection.next, type);
      expect(selection.compatible, isTrue);
      accepted.add(type);
    }
    final complete = SeleccionMarcacion(full, accepted);
    expect(complete.next, isNull);
    expect(complete.compatible, isFalse);
  });

  test('sin refrigerio ofrece entrada y salida y bloquea salida incompatible con API', () {
    final start = SeleccionMarcacion(simple, []);
    expect(start.types, ['ENTRADA', 'SALIDA']);
    expect(start.compatible, isTrue);
    final end = SeleccionMarcacion(simple, ['ENTRADA']);
    expect(end.next, 'SALIDA');
    expect(end.compatible, isFalse);
    expect(end.message, isNotNull);
  });

  test('descanso, horario ausente o refrigerio incompleto no permiten registrar', () {
    for (final day in [null, {...full, 'es_descanso': 1}, {...full, 'ref_fin': null}]) {
      final selection = SeleccionMarcacion(day, []);
      expect(selection.next, isNull);
      expect(selection.compatible, isFalse);
    }
  });

  test('secuencia rota, duplicados y exceso requieren revisión', () {
    for (final accepted in [
      ['SALIDA'],
      ['ENTRADA', 'ENTRADA'],
      [...SeleccionMarcacion.apiSequence, 'SALIDA'],
    ]) {
      final selection = SeleccionMarcacion(full, accepted);
      expect(selection.next, isNull);
      expect(selection.compatible, isFalse);
      expect(selection.message, contains('revisión'));
    }
  });
}
