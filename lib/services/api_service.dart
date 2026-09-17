import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService(this.token); final String token;
  Map<String, String> get _headers => {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  Future<dynamic> get(String path) async => _request(http.get(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: _headers));
  Future<dynamic> post(String path, Map<String, dynamic> body) async => _request(http.post(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: _headers, body: jsonEncode(body)));
  Future<dynamic> put(String path, Map<String, dynamic> body) async => _request(http.put(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: _headers, body: jsonEncode(body)));
  Future<dynamic> delete(String path) async => _request(http.delete(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: _headers));
  Future<dynamic> _request(Future<http.Response> future) async {
    final response = await future;
    dynamic data;
    try { data = response.body.isEmpty ? null : jsonDecode(response.body); } catch (_) { data = null; }
    if (response.statusCode < 200 || response.statusCode > 299) throw ApiException(data is Map ? (data['error'] ?? 'Error de servidor').toString() : 'Error de servidor');
    return data;
  }
}
