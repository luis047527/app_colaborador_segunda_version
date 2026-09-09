import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'usuario_service.dart';

class HorarioService {
  final http.Client _client;
  HorarioService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> crearHorario({
    required String token,
    required String nombre,
    String? descripcion,
    int toleranciaMinutos = 10,
    required String vigenciaDesde, // YYYY-MM-DD
    String? vigenciaHasta,
    required List<Map<String, dynamic>> dias, // 7 filas dia_semana 1-7
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/horarios');
    final res = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'tolerancia_minutos': toleranciaMinutos,
        'vigencia_desde': vigenciaDesde,
        'vigencia_hasta': vigenciaHasta,
        'dias': dias,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw ApiException(_msg(res), res.statusCode);
  }

  Future<Map<String, dynamic>> obtenerHorario({required String token, required int id}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/horarios/$id');
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
