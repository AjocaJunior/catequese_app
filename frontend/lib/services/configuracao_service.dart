import '../models/configuracao.dart';
import 'api_client.dart';

class ConfiguracaoService {
  final ApiClient _client;
  ConfiguracaoService(String? token) : _client = ApiClient(token);

  Future<Configuracao> obter() async {
    final data = await _client.get('/configuracao') as Map<String, dynamic>;
    return Configuracao.fromJson(data);
  }

  Future<Configuracao> avancarAnoLetivo(int novoAno) async {
    final data = await _client.put('/configuracao/ano-letivo', {'novo_ano': novoAno});
    return Configuracao.fromJson(data as Map<String, dynamic>);
  }
}
