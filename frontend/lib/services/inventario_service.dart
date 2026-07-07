import '../models/inventario.dart';
import 'api_client.dart';

class InventarioService {
  final ApiClient _client;
  InventarioService(String? token) : _client = ApiClient(token);

  Future<List<ItemInventario>> listar() async {
    final data = await _client.get('/inventario') as List;
    return data.map((e) => ItemInventario.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ItemInventario> criar({required String nome, required int quantidade, String? descricao}) async {
    final resposta = await _client.post('/inventario', {
      'nome': nome,
      'quantidade': quantidade,
      if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
    });
    return ItemInventario.fromJson(resposta as Map<String, dynamic>);
  }

  Future<ItemInventario> atualizar(String id, {String? nome, int? quantidade, String? descricao}) async {
    final body = <String, dynamic>{
      if (nome != null) 'nome': nome,
      if (quantidade != null) 'quantidade': quantidade,
      if (descricao != null) 'descricao': descricao,
    };
    final resposta = await _client.put('/inventario/$id', body);
    return ItemInventario.fromJson(resposta as Map<String, dynamic>);
  }

  Future<void> apagar(String id) => _client.delete('/inventario/$id');
}
