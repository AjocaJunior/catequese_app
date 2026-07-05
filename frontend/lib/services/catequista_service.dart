import '../models/catequista.dart';
import 'api_client.dart';

class CatequistaService {
  final ApiClient _client;
  CatequistaService(String? token) : _client = ApiClient(token);

  Future<List<Catequista>> listar() async {
    final data = await _client.get('/catequistas') as List;
    return data.map((e) => Catequista.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Catequista> alterarAdmin(String id, bool isAdmin) async {
    final data = await _client.patch('/catequistas/$id/admin', {'is_admin': isAdmin});
    return Catequista.fromJson(data as Map<String, dynamic>);
  }
}
