/// Opciones de presentación. El servidor sigue siendo autoridad del registro.
class SeleccionMarcacion {
  SeleccionMarcacion(Map<String, dynamic>? day, List<String> accepted) {
    if (day == null) {
      message = 'No se pudo obtener el horario. Reintenta la consulta antes de marcar.';
      return;
    }
    if (day['es_descanso'] == true || day['es_descanso'] == 1) {
      message = 'Hoy es tu día de descanso.';
      return;
    }
    if (day['entrada'] == null || day['salida'] == null ||
        (day['ref_inicio'] == null) != (day['ref_fin'] == null)) {
      message = 'El horario está incompleto. Contacta al administrador.';
      return;
    }
    types = day['ref_inicio'] == null ? ['ENTRADA', 'SALIDA'] : List.of(apiSequence);
    for (var i = 0; i < accepted.length; i++) {
      if (i >= types.length || accepted[i] != types[i]) {
        message = 'Las marcaciones de hoy requieren revisión. Contacta a tu supervisor.';
        return;
      }
    }
    if (accepted.length == types.length) {
      message = 'Ya completaste las marcaciones de hoy.';
      return;
    }
    next = types[accepted.length];
    // Compatibilidad temporal: la API actual siempre asigna cuatro tipos.
    compatible = next == apiSequence[accepted.length];
    if (!compatible) {
      message = 'La salida de jornadas sin refrigerio aún no está disponible. Contacta a tu supervisor.';
    }
  }

  static const apiSequence = ['ENTRADA', 'SALIDA_REFRIGERIO', 'REGRESO_REFRIGERIO', 'SALIDA'];
  List<String> types = [];
  String? next;
  String? message;
  bool compatible = false;

  static String label(String type) => switch (type) {
    'ENTRADA' => 'Entrada',
    'SALIDA_REFRIGERIO' => 'Inicio de refrigerio',
    'REGRESO_REFRIGERIO' => 'Fin de refrigerio',
    'SALIDA' => 'Salida',
    _ => type,
  };
}
