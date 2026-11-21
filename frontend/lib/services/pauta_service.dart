import 'dart:typed_data';

import '../models/pauta.dart';
import 'api_client.dart';

class PautaService {
  final ApiClient _client;
  PautaService(String? token) : _client = ApiClient(token);

  Future<Pauta> obter({required String faseId, int? anoLetivo}) async {
    final query = anoLetivo != null ? '&ano_letivo=$anoLetivo' : '';
    final data = await _client.get('/pautas?fase_id=$faseId$query') as Map<String, dynamic>;
    return Pauta.fromJson(data);
  }

  Future<Pauta> definir({
    required String faseId,
    int? anoLetivo,
    required List<ItemPauta> itens,
  }) async {
    final query = anoLetivo != null ? '&ano_letivo=$anoLetivo' : '';
    final data = await _client.put('/pautas?fase_id=$faseId$query', {
      'situacoes': itens
          .where((i) =>
              i.situacao != null || i.comportamento != null || (i.observacao != null && i.observacao!.trim().isNotEmpty))
          .map((i) => {
                'catequisando_id': i.catequisandoId,
                if (i.situacao != null) 'situacao': i.situacao!.valor,
                if (i.comportamento != null) 'comportamento': i.comportamento!.valor,
                if (i.observacao != null && i.observacao!.trim().isNotEmpty) 'observacao': i.observacao!.trim(),
              })
          .toList(),
    });
    return Pauta.fromJson(data as Map<String, dynamic>);
  }

  Future<Uint8List> baixarPdf({required String faseId, int? anoLetivo}) {
    final query = anoLetivo != null ? '&ano_letivo=$anoLetivo' : '';
    return _client.getBytes('/pautas/pdf?fase_id=$faseId$query');
  }
}
