import '../models/sector.dart';
import 'api_client.dart';

class SectorService {
  final ApiClient _client;
  SectorService(String? token) : _client = ApiClient(token);

  Future<List<Sector>> listar() async {
    final data = await _client.get('/sectores') as List;
    return data.map((e) => Sector.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Sector> criar({
    required String nome,
    DiaSemana? diaSemana,
    String? hora,
    String? local,
    String? ministerioId,
    String? responsavelNome,
    String? responsavelCatequistaId,
  }) async {
    final resposta = await _client.post('/sectores', {
      'nome': nome,
      if (diaSemana != null) 'dia_semana': diaSemana.valor,
      if (hora != null) 'hora': hora,
      if (local != null) 'local': local,
      if (ministerioId != null) 'ministerio_id': ministerioId,
      if (responsavelNome != null) 'responsavel_nome': responsavelNome,
      if (responsavelCatequistaId != null) 'responsavel_catequista_id': responsavelCatequistaId,
    });
    return Sector.fromJson(resposta as Map<String, dynamic>);
  }

  Future<Sector> atualizar(
    String id, {
    String? nome,
    DiaSemana? diaSemana,
    String? hora,
    String? local,
    String? ministerioId,
    String? responsavelNome,
    String? responsavelCatequistaId,
  }) async {
    final body = <String, dynamic>{
      if (nome != null) 'nome': nome,
      if (diaSemana != null) 'dia_semana': diaSemana.valor,
      if (hora != null) 'hora': hora,
      if (local != null) 'local': local,
      if (ministerioId != null) 'ministerio_id': ministerioId,
      if (responsavelNome != null) 'responsavel_nome': responsavelNome,
      if (responsavelCatequistaId != null) 'responsavel_catequista_id': responsavelCatequistaId,
    };
    final resposta = await _client.put('/sectores/$id', body);
    return Sector.fromJson(resposta as Map<String, dynamic>);
  }

  Future<void> apagar(String id) => _client.delete('/sectores/$id');
}
