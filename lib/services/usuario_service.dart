import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
}

class UsuarioService {
  final http.Client _client;
  UsuarioService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> crearUsuario({
    required String token,
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String rol,
    String? fotoUrl,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/usuarios');
    final res = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'password': password,
        'rol': rol,
        if (fotoUrl != null) 'foto_url': fotoUrl,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw ApiException(_msg(res), res.statusCode);
  }

  Future<List<dynamic>> listarUsuarios(String token) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/usuarios');
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
