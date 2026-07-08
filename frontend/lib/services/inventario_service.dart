import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/catequisando.dart';
import '../models/inventario.dart';
import 'api_client.dart';

class InventarioService {
  final ApiClient _client;
  final String? _token;
  InventarioService(String? token)
      : _client = ApiClient(token),
        _token = token;

  Future<List<ItemInventario>> listar() async {
    final data = await _client.get('/inventario') as List;
    return data.map((e) => ItemInventario.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ItemInventario> criar({
    required String nome,
    String? sectorId,
    String? categoria,
    required int quantidade,
    String? descricao,
    String? localizacao,
    String? imagemUrl,
    EstadoItem? estado,
  }) async {
    final resposta = await _client.post('/inventario', {
      'nome': nome,
      if (sectorId != null) 'sector_id': sectorId,
      if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
      'quantidade': quantidade,
      if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
      if (localizacao != null && localizacao.isNotEmpty) 'localizacao': localizacao,
      if (imagemUrl != null && imagemUrl.isNotEmpty) 'imagem_url': imagemUrl,
      if (estado != null) 'estado': estado.valor,
    });
    return ItemInventario.fromJson(resposta as Map<String, dynamic>);
  }

  Future<ItemInventario> atualizar(
    String id, {
    String? nome,
    String? sectorId,
    String? categoria,
    int? quantidade,
    String? descricao,
    String? localizacao,
    String? imagemUrl,
    EstadoItem? estado,
  }) async {
    final body = <String, dynamic>{
      if (nome != null) 'nome': nome,
      if (sectorId != null) 'sector_id': sectorId,
      if (categoria != null) 'categoria': categoria,
      if (quantidade != null) 'quantidade': quantidade,
      if (descricao != null) 'descricao': descricao,
      if (localizacao != null) 'localizacao': localizacao,
      if (imagemUrl != null) 'imagem_url': imagemUrl,
      if (estado != null) 'estado': estado.valor,
    };
    final resposta = await _client.put('/inventario/$id', body);
    return ItemInventario.fromJson(resposta as Map<String, dynamic>);
  }

  Future<void> apagar(String id) => _client.delete('/inventario/$id');

  /// Importa itens de inventário a partir de um ficheiro .xlsx.
  /// [sectorId] opcional — os itens ficam associados a esse sector.
  Future<ImportacaoResultado> importar({
    required Uint8List bytes,
    required String nomeFicheiro,
    String? sectorId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/inventario/importar');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    if (sectorId != null) {
      request.fields['sector_id'] = sectorId;
    }
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
