import '../models/fase.dart';
import 'api_client.dart';

class FaseService {
  final ApiClient _client;
  FaseService(String? token) : _client = ApiClient(token);

  Future<List<Fase>> listar() async {
    final data = await _client.get('/fases') as List;
    return data.map((e) => Fase.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Fase> criar(
    String nome, {
    int? ordem,
    String? nomeCatecismo,
    String? local,
    String? programaPdfUrl,
  }) async {
    final data = await _client.post('/fases', {
      'nome': nome,
      if (ordem != null) 'ordem': ordem,
      if (nomeCatecismo != null) 'nome_catecismo': nomeCatecismo,
      if (local != null) 'local': local,
      if (programaPdfUrl != null) 'programa_pdf_url': programaPdfUrl,
    });
    return Fase.fromJson(data as Map<String, dynamic>);
  }

  Future<Fase> atualizar(
    String id, {
    String? nome,
    int? ordem,
    String? nomeCatecismo,
    String? local,
    String? programaPdfUrl,
  }) async {
    final body = <String, dynamic>{};
    if (nome != null) body['nome'] = nome;
    if (ordem != null) body['ordem'] = ordem;
    if (nomeCatecismo != null) body['nome_catecismo'] = nomeCatecismo;
    if (local != null) body['local'] = local;
    if (programaPdfUrl != null) body['programa_pdf_url'] = programaPdfUrl;
    final data = await _client.put('/fases/$id', body);
    return Fase.fromJson(data as Map<String, dynamic>);
  }

  Future<void> apagar(String id) => _client.delete('/fases/$id');

  /// Substitui a lista completa de catequistas atribuídos a esta fase.
  Future<Fase> definirCatequistas(String faseId, List<String> catequistaIds) async {
    final data = await _client.put('/fases/$faseId/catequistas', {
      'catequista_ids': catequistaIds,
    });
    return Fase.fromJson(data as Map<String, dynamic>);
  }
}
