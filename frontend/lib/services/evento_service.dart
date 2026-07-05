import '../models/evento.dart';
import 'api_client.dart';

class EventoService {
  final ApiClient _client;
  EventoService(String? token) : _client = ApiClient(token);

  Future<List<Evento>> listar() async {
    final data = await _client.get('/eventos') as List;
    return data.map((e) => Evento.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Evento> criar({
    required String titulo,
    required DateTime data,
    String? local,
    String? descricao,
  }) async {
    final resposta = await _client.post('/eventos', {
      'titulo': titulo,
      'data': _formatarData(data),
      if (local != null) 'local': local,
      if (descricao != null) 'descricao': descricao,
    });
    return Evento.fromJson(resposta as Map<String, dynamic>);
  }

  Future<Evento> atualizar(
    String id, {
    String? titulo,
    DateTime? data,
    String? local,
    String? descricao,
  }) async {
    final body = <String, dynamic>{
      if (titulo != null) 'titulo': titulo,
      if (data != null) 'data': _formatarData(data),
      if (local != null) 'local': local,
      if (descricao != null) 'descricao': descricao,
    };
    final resposta = await _client.put('/eventos/$id', body);
    return Evento.fromJson(resposta as Map<String, dynamic>);
  }

  Future<void> apagar(String id) => _client.delete('/eventos/$id');

  String _formatarData(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
