import '../models/ministerio.dart';
import 'api_client.dart';

class MinisterioService {
  final ApiClient _client;
  MinisterioService(String? token) : _client = ApiClient(token);

  Future<List<Ministerio>> listar() async {
    final data = await _client.get('/ministerios') as List;
    return data.map((e) => Ministerio.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Ministerio> criar({required String nome, String? coordenadorNome}) async {
    final resposta = await _client.post('/ministerios', {
      'nome': nome,
      if (coordenadorNome != null) 'coordenador_nome': coordenadorNome,
    });
    return Ministerio.fromJson(resposta as Map<String, dynamic>);
  }

  Future<Ministerio> atualizar(String id, {String? nome, String? coordenadorNome}) async {
    final body = <String, dynamic>{
      if (nome != null) 'nome': nome,
      if (coordenadorNome != null) 'coordenador_nome': coordenadorNome,
    };
    final resposta = await _client.put('/ministerios/$id', body);
    return Ministerio.fromJson(resposta as Map<String, dynamic>);
  }

  Future<void> apagar(String id) => _client.delete('/ministerios/$id');
}
