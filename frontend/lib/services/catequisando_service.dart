import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/catequisando.dart';
import '../models/historico_inscricao.dart';
import 'api_client.dart';

class CatequisandoService {
  final ApiClient _client;
  final String? _token;
  CatequisandoService(String? token)
      : _client = ApiClient(token),
        _token = token;

  Future<List<Catequisando>> listar({String? faseId, SituacaoCatequisando? situacao}) async {
    final query = <String, String>{};
    if (faseId != null) query['fase_id'] = faseId;
    if (situacao != null) query['situacao'] = situacao.valor;
    final data = await _client.get('/catequisandos', query: query.isEmpty ? null : query) as List;
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

  /// Marca o catequisando como Crismado — mantém o registo e o histórico,
  /// mas deixa de aparecer nas presenças/pautas ativas da fase.
  Future<Catequisando> crismar(String id) async {
    final data = await _client.post('/catequisandos/$id/crismar', {});
    return Catequisando.fromJson(data as Map<String, dynamic>);
  }

  /// Reverte um catequisando Crismado de volta a Ativo (ex: engano).
  Future<Catequisando> reativar(String id) async {
    final data = await _client.post('/catequisandos/$id/reativar', {});
    return Catequisando.fromJson(data as Map<String, dynamic>);
  }

  /// Descarrega o PDF da lista de catequisandos de uma fase, pronto a imprimir.
  Future<Uint8List> baixarListaPdf(String faseId) =>
      _client.getBytes('/catequisandos/pdf?fase_id=$faseId');

  /// Descarrega o PDF do processo individual (dados + histórico de presenças).
  Future<Uint8List> baixarProcessoPdf(String catequisandoId) =>
      _client.getBytes('/catequisandos/$catequisandoId/pdf');

  /// Histórico de fase por ano letivo, derivado das inscrições/renovações
  /// já registadas na Caixa para este catequisando.
  Future<List<HistoricoInscricao>> historico(String catequisandoId) async {
    final data = await _client.get('/catequisandos/$catequisandoId/historico') as List;
    return data.map((e) => HistoricoInscricao.fromJson(e as Map<String, dynamic>)).toList();
  }

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
