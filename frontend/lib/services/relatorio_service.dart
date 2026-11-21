import 'dart:typed_data';

import '../models/relatorio.dart';
import 'api_client.dart';

class RelatorioService {
  final ApiClient _client;
  RelatorioService(String? token) : _client = ApiClient(token);

  /// Não depende do ano letivo — é sempre a fase actual de cada catequisando.
  Future<RelatorioCatequisandosPorFaseGenero> catequisandosPorFaseGenero() async {
    final data = await _client.get('/relatorios/catequisandos-por-fase-genero') as Map<String, dynamic>;
    return RelatorioCatequisandosPorFaseGenero.fromJson(data);
  }

  Future<Uint8List> catequisandosPorFaseGeneroPdf() {
    return _client.getBytes('/relatorios/catequisandos-por-fase-genero/pdf');
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

  Future<RelatorioInscricoes> inscricoes({int? anoLetivo}) async {
    final query = anoLetivo != null ? '?ano_letivo=$anoLetivo' : '';
    final data = await _client.get('/relatorios/inscricoes$query') as Map<String, dynamic>;
    return RelatorioInscricoes.fromJson(data);
  }

  Future<Uint8List> inscricoesPdf({int? anoLetivo}) {
    final query = anoLetivo != null ? '?ano_letivo=$anoLetivo' : '';
    return _client.getBytes('/relatorios/inscricoes/pdf$query');
  }

  /// Não depende do ano letivo — é sempre o estado atual das observações.
  Future<RelatorioObservacoes> observacoes() async {
    final data = await _client.get('/relatorios/observacoes') as Map<String, dynamic>;
    return RelatorioObservacoes.fromJson(data);
  }

  Future<Uint8List> observacoesPdf() => _client.getBytes('/relatorios/observacoes/pdf');

  /// Quem ainda não tem Inscrição/Renovação lançada no ano (por defeito, o corrente).
  Future<List<MatriculaPendente>> inscricoesPendentes({int? anoLetivo}) async {
    final query = anoLetivo != null ? '?ano_letivo=$anoLetivo' : '';
    final data = await _client.get('/relatorios/inscricoes/pendentes$query') as List;
    return data.map((e) => MatriculaPendente.fromJson(e as Map<String, dynamic>)).toList();
  }
}
