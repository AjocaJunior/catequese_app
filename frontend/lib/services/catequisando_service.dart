import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/catequisando.dart';
import 'api_client.dart';

class CatequisandoService {
  final ApiClient _client;
  final String? _token;
  CatequisandoService(String? token)
      : _client = ApiClient(token),
        _token = token;

  Future<List<Catequisando>> listar({String? faseId}) async {
    final data = await _client.get(
      '/catequisandos',
      query: faseId != null ? {'fase_id': faseId} : null,
    ) as List;
    return data.map((e) => Catequisando.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Catequisando> criar(Map<String, dynamic> dados) async {
    final data = await _client.post('/catequisandos', dados);
    return Catequisando.fromJson(data as Map<String, dynamic>);
  }

  Future<Catequisando> atualizar(String id, Map<String, dynamic> dados) async {
    final data = await _client.put('/catequisandos/$id', dados);
    return Catequisando.fromJson(data as Map<String, dynamic>);
  }

  Future<void> apagar(String id) => _client.delete('/catequisandos/$id');

  /// Descarrega o PDF da lista de catequisandos de uma fase, pronto a imprimir.
  Future<Uint8List> baixarListaPdf(String faseId) =>
      _client.getBytes('/catequisandos/pdf?fase_id=$faseId');

  /// Descarrega o PDF do processo individual (dados + histórico de presenças).
  Future<Uint8List> baixarProcessoPdf(String catequisandoId) =>
      _client.getBytes('/catequisandos/$catequisandoId/pdf');

  /// Importa catequisandos a partir de um ficheiro .xlsx.
  /// [bytes] deve ser o conteúdo binário do ficheiro escolhido pelo utilizador.
  Future<ImportacaoResultado> importar({
    required String faseId,
    required Uint8List bytes,
    required String nomeFicheiro,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/catequisandos/importar');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.fields['fase_id'] = faseId;
    request.files.add(http.MultipartFile.fromBytes('arquivo', bytes, filename: nomeFicheiro));

    final streamed = await request.send();
    final resposta = await http.Response.fromStream(streamed);

    if (resposta.statusCode == 200) {
      return ImportacaoResultado.fromJson(jsonDecode(resposta.body) as Map<String, dynamic>);
    }

    String mensagem = 'Erro ${resposta.statusCode} ao importar';
    try {
      final corpo = jsonDecode(resposta.body);
      if (corpo is Map && corpo['detail'] != null) mensagem = corpo['detail'].toString();
    } catch (_) {}
    throw ApiException(mensagem, resposta.statusCode);
  }
}
