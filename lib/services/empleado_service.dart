import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'usuario_service.dart';

class EmpleadoService {
  final http.Client _client;
  EmpleadoService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> crearEmpleado({
    required String token,
    required int usuarioId,
    required String codigo,
    required String cargo,
    required String modalidad, // FULL_TIME | PART_TIME
    required String tipoHorario, // FIJO | FLEXIBLE | ROTATIVO | PERSONALIZADO
    required String fechaIngreso, // YYYY-MM-DD
    int? sedeId,
    int? horarioId,
    String? fechaCese,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/empleados');
    final res = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'usuario_id': usuarioId,
        'codigo_empleado': codigo,
        'cargo': cargo,
        'modalidad_laboral': modalidad,
        'tipo_horario': tipoHorario,
        'fecha_ingreso': fechaIngreso,
        if (sedeId != null) 'sede_id': sedeId,
        if (horarioId != null) 'horario_id': horarioId,
        if (fechaCese != null) 'fecha_cese': fechaCese,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw ApiException(_msg(res), res.statusCode);
  }

  Future<Map<String, dynamic>> actualizarEmpleado({
    required String token,
    required int empleadoId,
    required Map<String, dynamic> cambios,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/empleados/$empleadoId');
    final res = await _client.put(uri, headers: _headers(token), body: jsonEncode(cambios));
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw ApiException(_msg(res), res.statusCode);
  }

  Future<Map<String, dynamic>> horarioHoy({required String token, required int empleadoId}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/empleados/$empleadoId/horario-hoy');
    final res = await _client.get(uri, headers: _headers(token));
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw ApiException(_msg(res), res.statusCode);
  }

  String _msg(http.Response r) {
    try {
      final d = jsonDecode(r.body) as Map<String, dynamic>;
      return d['error'] as String? ?? 'Error ${r.statusCode}';
    } catch (_) {
      return 'Error ${r.statusCode}';
    }
  }
}
