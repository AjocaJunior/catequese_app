import 'dart:typed_data';

import '../models/relatorio.dart';
import 'api_client.dart';

class RelatorioService {
  final ApiClient _client;
  RelatorioService(String? token) : _client = ApiClient(token);

  Future<RelatorioCatequisandosPorFaseGenero> catequisandosPorFaseGenero({int? anoLetivo}) async {
    final query = anoLetivo != null ? '?ano_letivo=$anoLetivo' : '';
    final data = await _client.get('/relatorios/catequisandos-por-fase-genero$query') as Map<String, dynamic>;
    return RelatorioCatequisandosPorFaseGenero.fromJson(data);
  }

  Future<Uint8List> catequisandosPorFaseGeneroPdf({int? anoLetivo}) {
    final query = anoLetivo != null ? '?ano_letivo=$anoLetivo' : '';
    return _client.getBytes('/relatorios/catequisandos-por-fase-genero/pdf$query');
  }

  Future<List<int>> anosDisponiveis() async {
    final data = await _client.get('/relatorios/anos-disponiveis') as List;
    return data.map((e) => e as int).toList();
  }

  Future<RelatorioSituacaoFinal> situacaoFinal({int? anoLetivo}) async {
    final query = anoLetivo != null ? '?ano_letivo=$anoLetivo' : '';
    final data = await _client.get('/relatorios/situacao-final$query') as Map<String, dynamic>;
    return RelatorioSituacaoFinal.fromJson(data);
  }

  Future<Uint8List> situacaoFinalPdf({int? anoLetivo}) {
    final query = anoLetivo != null ? '?ano_letivo=$anoLetivo' : '';
    return _client.getBytes('/relatorios/situacao-final/pdf$query');
  }

  Future<RelatorioAssiduidade> assiduidade({int? anoLetivo}) async {
    final query = anoLetivo != null ? '?ano_letivo=$anoLetivo' : '';
    final data = await _client.get('/relatorios/assiduidade$query') as Map<String, dynamic>;
    return RelatorioAssiduidade.fromJson(data);
  }

  Future<Uint8List> assiduidadePdf({int? anoLetivo}) {
    final query = anoLetivo != null ? '?ano_letivo=$anoLetivo' : '';
    return _client.getBytes('/relatorios/assiduidade/pdf$query');
  }
}
