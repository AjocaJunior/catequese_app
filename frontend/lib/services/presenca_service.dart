import 'dart:typed_data';

import '../models/presenca.dart';
import 'api_client.dart';

class PresencaService {
  final ApiClient _client;
  PresencaService(String? token) : _client = ApiClient(token);

  Future<List<PresencaItem>> listar({required String faseId, required DateTime data}) async {
    final dataStr = _formatarData(data);
    final resposta = await _client.get('/presencas', query: {
      'fase_id': faseId,
      'data': dataStr,
    }) as Map<String, dynamic>;

    final presencas = resposta['presencas'] as List;
    return presencas.map((e) => PresencaItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PresencaItem>> marcar({
    required String faseId,
    required DateTime data,
    required List<PresencaItem> presencas,
  }) async {
    final resposta = await _client.put('/presencas', {
      'fase_id': faseId,
      'data': _formatarData(data),
      'presencas': presencas.map((p) => p.toRequestJson()).toList(),
    }) as Map<String, dynamic>;

    final lista = resposta['presencas'] as List;
    return lista.map((e) => PresencaItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<HistoricoPresencas> historico(String catequisandoId) async {
    final data = await _client.get('/presencas/catequisando/$catequisandoId') as Map<String, dynamic>;
    return HistoricoPresencas.fromJson(data);
  }

  /// Descarrega o relatório (PDF) com totais de presenças/faltas/faltas
  /// justificadas de todos os catequisandos de uma fase.
  Future<Uint8List> baixarRelatorioPdf(String faseId) =>
      _client.getBytes('/presencas/relatorio?fase_id=$faseId');

  String _formatarData(DateTime data) =>
      '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
}
