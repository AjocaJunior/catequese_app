import '../models/configuracao.dart';
import 'api_client.dart';

class ConfiguracaoService {
  final ApiClient _client;
  ConfiguracaoService(String? token) : _client = ApiClient(token);

  Future<Configuracao> obter() async {
    final data = await _client.get('/configuracao') as Map<String, dynamic>;
    return Configuracao.fromJson(data);
  }

  /// O que aconteceria a cada catequisando se o ano avançasse agora (não
  /// altera nada).
  Future<PreviaTransicao> previaTransicao(int novoAno) async {
    final data = await _client.get('/configuracao/ano-letivo/previa-transicao?novo_ano=$novoAno')
        as Map<String, dynamic>;
    return PreviaTransicao.fromJson(data);
  }

  Future<ResultadoAvancoAno> avancarAnoLetivo(int novoAno, {bool aplicarTransicao = false}) async {
    final data = await _client.put('/configuracao/ano-letivo', {
      'novo_ano': novoAno,
      'aplicar_transicao': aplicarTransicao,
    });
    return ResultadoAvancoAno.fromJson(data as Map<String, dynamic>);
  }
}
