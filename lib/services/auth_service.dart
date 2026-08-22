import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/usuario.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthService extends ChangeNotifier {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  String? _token;
  Usuario? _usuario;

  String? get token => _token;
  Usuario? get usuario => _usuario;
  bool get isAuthenticated => _token != null;

  Future<void> login(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _token = data['token'] as String;
      _usuario = Usuario.fromJson(data['usuario'] as Map<String, dynamic>);
      notifyListeners();
      return;
    }

    String mensaje = 'Error al iniciar sesión';
    if (response.body.isNotEmpty) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        mensaje = data['error'] as String? ?? mensaje;
      } catch (_) {}
    }
    if (response.statusCode == 401) {
      mensaje = 'Credenciales inválidas';
    } else if (response.statusCode == 403) {
      mensaje = 'Usuario inactivo o bloqueado';
    }
    throw AuthException(mensaje);
  }

  void logout() {
    _token = null;
    _usuario = null;
    notifyListeners();
  }
}
