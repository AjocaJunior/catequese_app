import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../models/catequista.dart';

/// Gere o estado de autenticação da app.
/// O token é guardado com flutter_secure_storage para sobreviver a
/// reinícios da app (não se perde a sessão ao fechar o browser/app).
class AuthService extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  String? _token;
  Catequista? _catequista;
  bool _loading = true;
  String? _lastError;

  String? get token => _token;
  Catequista? get catequista => _catequista;
  bool get isAuthenticated => _token != null && _catequista != null;
  bool get loading => _loading;
  String? get lastError => _lastError;

  /// Chamado uma vez no arranque da app: tenta restaurar a sessão anterior.
  Future<void> tryAutoLogin() async {
    _loading = true;
    notifyListeners();

    final savedToken = await _storage.read(key: _tokenKey);
    if (savedToken != null) {
      _token = savedToken;
      final ok = await _fetchMe();
      if (!ok) {
        await logout();
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> _fetchMe() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/eu');
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $_token'});
      if (response.statusCode == 200) {
        _catequista = Catequista.fromJson(jsonDecode(response.body));
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _lastError = null;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');
      // O backend usa OAuth2PasswordRequestForm -> corpo form-urlencoded,
      // com os campos "username" (email) e "password".
      final response = await http.post(uri, body: {
        'username': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _token = data['access_token'] as String;
        _catequista = Catequista.fromJson(data['catequista'] as Map<String, dynamic>);
        await _storage.write(key: _tokenKey, value: _token);
        notifyListeners();
        return true;
      }

      _lastError = _extractError(response.body) ?? 'Não foi possível iniciar sessão';
      return false;
    } catch (e) {
      _lastError = 'Erro de ligação ao servidor: $e';
      return false;
    }
  }

  Future<bool> register(String nome, String email, String password) async {
    _lastError = null;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/registar');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nome': nome, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        // Após registar com sucesso, inicia sessão automaticamente.
        return await login(email, password);
      }

      _lastError = _extractError(response.body) ?? 'Não foi possível registar';
      return false;
    } catch (e) {
      _lastError = 'Erro de ligação ao servidor: $e';
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _catequista = null;
    await _storage.delete(key: _tokenKey);
    notifyListeners();
  }

  String? _extractError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
    } catch (_) {
      // corpo não é JSON válido, ignora
    }
    return null;
  }
}
