import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'usuario_service.dart';

class SedeService {
  final http.Client _client;
  SedeService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> crearSede({
    required String token,
    required String nombre,
    required String direccion,
    required double latitud,
    required double longitud,
    required double radio,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/sedes');
    final res = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'nombre': nombre,
        'direccion': direccion,
        'latitud': latitud,
        'longitud': longitud,
        'radio_permitido_metros': radio,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw ApiException(_msg(res), res.statusCode);
  }

  Future<List<dynamic>> listarSedes(String token) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/sedes');
    final res = await _client.get(uri, headers: _headers(token));
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
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
