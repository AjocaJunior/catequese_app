import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Cliente HTTP fino, usado por todos os *_service.dart.
/// Centraliza o cabeçalho de autenticação e a extração de erros do FastAPI
/// (que devolve {"detail": "mensagem"} nos erros).
class ApiClient {
  final String? token;
  ApiClient(this.token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: _headers);
    return _handle(res);
  }

  /// Para descarregar ficheiros binários (ex: PDF), em vez de JSON.
  /// Devolve Uint8List (não só List<int>) porque pacotes como o `printing`
  /// exigem esse tipo concreto, não a interface mais genérica.
  Future<Uint8List> getBytes(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.bodyBytes;
    }
    throw ApiException(_extractError(utf8.decode(res.bodyBytes)) ?? 'Erro ${res.statusCode}', res.statusCode);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final res = await http.post(uri, headers: _headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final res = await http.put(uri, headers: _headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final res = await http.patch(uri, headers: _headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<void> delete(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final res = await http.delete(uri, headers: _headers);
    if (res.statusCode >= 400) {
      throw ApiException(_extractError(res.body) ?? 'Erro ao apagar (${res.statusCode})', res.statusCode);
    }
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    throw ApiException(_extractError(res.body) ?? 'Erro ${res.statusCode}', res.statusCode);
  }

  String? _extractError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['detail'] != null) return data['detail'].toString();
    } catch (_) {
      // corpo não é JSON, ignora
    }
    return null;
  }
}
