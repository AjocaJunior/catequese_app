import '../models/fase.dart';
import '../models/sector.dart';
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
    DiaSemana? diaSemana,
    String? hora,
    String? local,
    String? programaPdfUrl,
    String? faseSeguinteId,
    bool transitoria = false,
  }) async {
    final data = await _client.post('/fases', {
      'nome': nome,
      if (ordem != null) 'ordem': ordem,
      if (nomeCatecismo != null) 'nome_catecismo': nomeCatecismo,
      if (diaSemana != null) 'dia_semana': diaSemana.valor,
      if (hora != null) 'hora': hora,
      if (local != null) 'local': local,
      if (programaPdfUrl != null) 'programa_pdf_url': programaPdfUrl,
      if (faseSeguinteId != null) 'fase_seguinte_id': faseSeguinteId,
      'transitoria': transitoria,
    });
    return Fase.fromJson(data as Map<String, dynamic>);
  }

  Future<Fase> atualizar(
    String id, {
    String? nome,
    int? ordem,
    String? nomeCatecismo,
    DiaSemana? diaSemana,
    String? hora,
    String? local,
    String? programaPdfUrl,
    String? faseSeguinteId,

    /// Para poder LIMPAR a fase seguinte, enviar null só é entendido como
    /// "limpar" quando este flag está ligado.
    bool definirFaseSeguinte = false,
    bool? transitoria,
  }) async {
    final body = <String, dynamic>{};
    if (nome != null) body['nome'] = nome;
    if (ordem != null) body['ordem'] = ordem;
    if (nomeCatecismo != null) body['nome_catecismo'] = nomeCatecismo;
    if (diaSemana != null) body['dia_semana'] = diaSemana.valor;
    if (hora != null) body['hora'] = hora;
    if (local != null) body['local'] = local;
    if (programaPdfUrl != null) body['programa_pdf_url'] = programaPdfUrl;
    if (definirFaseSeguinte) body['fase_seguinte_id'] = faseSeguinteId;
    if (transitoria != null) body['transitoria'] = transitoria;
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
