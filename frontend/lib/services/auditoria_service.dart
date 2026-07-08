import '../models/auditoria.dart';
import 'api_client.dart';

class AuditoriaService {
  final ApiClient _client;
  AuditoriaService(String? token) : _client = ApiClient(token);

  Future<List<RegistoAuditoria>> listar({String? entidade, String? catequistaId}) async {
    final params = <String>[];
    if (entidade != null) params.add('entidade=${Uri.encodeQueryComponent(entidade)}');
    if (catequistaId != null) params.add('catequista_id=$catequistaId');
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    final data = await _client.get('/auditoria$query') as List;
    return data.map((e) => RegistoAuditoria.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<String>> listarEntidades() async {
    final data = await _client.get('/auditoria/entidades') as List;
    return data.map((e) => e as String).toList();
  }
}
