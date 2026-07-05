import '../models/evento.dart';
import '../models/organograma.dart';
import '../models/retiro_publico.dart';
import '../models/sector.dart';
import 'api_client.dart';

/// Este serviço nunca envia token de autenticação — usa os endpoints
/// /publico/* que não exigem sessão iniciada.
class PublicoService {
  final ApiClient _client = ApiClient(null);

  Future<List<RetiroPublico>> listarRetiros() async {
    final data = await _client.get('/publico/retiros') as List;
    return data.map((e) => RetiroPublico.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Evento>> listarEventos() async {
    final data = await _client.get('/publico/eventos') as List;
    return data.map((e) => Evento.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Sector>> listarSectores() async {
    final data = await _client.get('/publico/sectores') as List;
    return data.map((e) => Sector.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Organograma> organograma() async {
    final data = await _client.get('/publico/organograma') as Map<String, dynamic>;
    return Organograma.fromJson(data);
  }
}
