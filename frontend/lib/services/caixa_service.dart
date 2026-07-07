import '../models/caixa.dart';
import 'api_client.dart';

class CaixaService {
  final ApiClient _client;
  CaixaService(String? token) : _client = ApiClient(token);

  Future<List<CaixaTransacao>> listar({TipoTransacao? tipo}) async {
    final query = tipo != null ? '?tipo=${tipo.valor}' : '';
    final data = await _client.get('/caixa$query') as List;
    return data.map((e) => CaixaTransacao.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ResumoCaixa> resumo() async {
    final data = await _client.get('/caixa/resumo') as Map<String, dynamic>;
    return ResumoCaixa.fromJson(data);
  }

  Future<CaixaTransacao> criar({
    required TipoTransacao tipo,
    required String categoria,
    required double valor,
    MetodoPagamento? metodoPagamento,
    String? catequisandoId,
    String? faseId,
    int? anoLetivo,
    String? descricao,
    required DateTime data,
  }) async {
    final resposta = await _client.post('/caixa', {
      'tipo': tipo.valor,
      'categoria': categoria,
      'valor': valor,
      if (metodoPagamento != null) 'metodo_pagamento': metodoPagamento.valor,
      if (catequisandoId != null) 'catequisando_id': catequisandoId,
      if (faseId != null) 'fase_id': faseId,
      if (anoLetivo != null) 'ano_letivo': anoLetivo,
      if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
      'data': _formatarData(data),
    });
    return CaixaTransacao.fromJson(resposta as Map<String, dynamic>);
  }

  Future<CaixaTransacao> atualizar(
    String id, {
    TipoTransacao? tipo,
    String? categoria,
    double? valor,
    MetodoPagamento? metodoPagamento,
    String? catequisandoId,
    String? faseId,
    int? anoLetivo,
    String? descricao,
    DateTime? data,
  }) async {
    final body = <String, dynamic>{
      if (tipo != null) 'tipo': tipo.valor,
      if (categoria != null) 'categoria': categoria,
      if (valor != null) 'valor': valor,
      if (metodoPagamento != null) 'metodo_pagamento': metodoPagamento.valor,
      if (catequisandoId != null) 'catequisando_id': catequisandoId,
      if (faseId != null) 'fase_id': faseId,
      if (anoLetivo != null) 'ano_letivo': anoLetivo,
      if (descricao != null) 'descricao': descricao,
      if (data != null) 'data': _formatarData(data),
    };
    final resposta = await _client.put('/caixa/$id', body);
    return CaixaTransacao.fromJson(resposta as Map<String, dynamic>);
  }

  Future<void> apagar(String id) => _client.delete('/caixa/$id');

  String _formatarData(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
