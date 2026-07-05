import 'dart:typed_data';

import '../models/retiro.dart';
import 'api_client.dart';

class RetiroService {
  final ApiClient _client;
  RetiroService(String? token) : _client = ApiClient(token);

  Future<List<Retiro>> listar() async {
    final data = await _client.get('/retiros') as List;
    return data.map((e) => Retiro.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Retiro> criar({
    required String titulo,
    required List<String> faseIds,
    List<String> sectorIds = const [],
    required DateTime data,
    required String local,
    required List<String> oradores,
    required String tema,
    required List<ProgramaItem> programa,
  }) async {
    final resposta = await _client.post('/retiros', {
      'titulo': titulo,
      'fase_ids': faseIds,
      'sector_ids': sectorIds,
      'data': _formatarData(data),
      'local': local,
      'oradores': oradores,
      'tema': tema,
      'programa': programa.map((p) => p.toJson()).toList(),
    });
    return Retiro.fromJson(resposta as Map<String, dynamic>);
  }

  Future<Retiro> atualizar(
    String id, {
    String? titulo,
    List<String>? faseIds,
    List<String>? sectorIds,
    DateTime? data,
    String? local,
    List<String>? oradores,
    String? tema,
    List<ProgramaItem>? programa,
  }) async {
    final body = <String, dynamic>{
      if (titulo != null) 'titulo': titulo,
      if (faseIds != null) 'fase_ids': faseIds,
      if (sectorIds != null) 'sector_ids': sectorIds,
      if (data != null) 'data': _formatarData(data),
      if (local != null) 'local': local,
      if (oradores != null) 'oradores': oradores,
      if (tema != null) 'tema': tema,
      if (programa != null) 'programa': programa.map((p) => p.toJson()).toList(),
    };
    final resposta = await _client.put('/retiros/$id', body);
    return Retiro.fromJson(resposta as Map<String, dynamic>);
  }

  Future<void> apagar(String id) => _client.delete('/retiros/$id');

  Future<Uint8List> baixarPdf(String id) => _client.getBytes('/retiros/$id/pdf');

  String _formatarData(DateTime data) =>
      '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
}
