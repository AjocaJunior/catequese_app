import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/foto.dart';
import 'api_client.dart';

class FotoService {
  final ApiClient _client;
  final String? _token;
  FotoService(String? token)
      : _client = ApiClient(token),
        _token = token;

  Future<List<Foto>> listar() async {
    final data = await _client.get('/fotos') as List;
    return data.map((e) => Foto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Foto> enviar({required Uint8List bytes, required String nomeFicheiro, String? titulo}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/fotos');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    if (titulo != null && titulo.isNotEmpty) {
      request.fields['titulo'] = titulo;
    }
    request.files.add(http.MultipartFile.fromBytes('imagem', bytes, filename: nomeFicheiro));

    final streamed = await request.send();
    final resposta = await http.Response.fromStream(streamed);

    if (resposta.statusCode == 201) {
      return Foto.fromJson(jsonDecode(resposta.body) as Map<String, dynamic>);
    }

    String mensagem = 'Erro ${resposta.statusCode} ao enviar foto';
    try {
      final corpo = jsonDecode(resposta.body);
      if (corpo is Map && corpo['detail'] != null) mensagem = corpo['detail'].toString();
    } catch (_) {}
    throw ApiException(mensagem, resposta.statusCode);
  }

  Future<void> apagar(String id) => _client.delete('/fotos/$id');
}
