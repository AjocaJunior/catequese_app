enum Situacao {
  permanece,
  progride;

  String get valor => this == Situacao.permanece ? 'permanece' : 'progride';
  String get rotulo => this == Situacao.permanece ? 'Permanece' : 'Progride';

  static Situacao? fromValor(String? v) {
    if (v == null) return null;
    return v == 'permanece' ? Situacao.permanece : Situacao.progride;
  }
}

class ItemPauta {
  final String catequisandoId;
  final String catequisandoNome;
  final int totalPresencas;
  final int totalFaltas;
  final int totalFaltasJustificadas;
  Situacao? situacao;

  ItemPauta({
    required this.catequisandoId,
    required this.catequisandoNome,
    required this.totalPresencas,
    required this.totalFaltas,
    required this.totalFaltasJustificadas,
    this.situacao,
  });

  factory ItemPauta.fromJson(Map<String, dynamic> json) => ItemPauta(
        catequisandoId: json['catequisando_id'] as String,
        catequisandoNome: json['catequisando_nome'] as String,
        totalPresencas: json['total_presencas'] as int,
        totalFaltas: json['total_faltas'] as int,
        totalFaltasJustificadas: json['total_faltas_justificadas'] as int,
        situacao: Situacao.fromValor(json['situacao'] as String?),
      );
}

class Pauta {
  final String faseId;
  final String faseNome;
  final int anoLetivo;
  final List<ItemPauta> itens;
  final DateTime? atualizadoEm;
  final String? atualizadoPorNome;

  Pauta({
    required this.faseId,
    required this.faseNome,
    required this.anoLetivo,
    required this.itens,
    this.atualizadoEm,
    this.atualizadoPorNome,
  });

  factory Pauta.fromJson(Map<String, dynamic> json) => Pauta(
        faseId: json['fase_id'] as String,
        faseNome: json['fase_nome'] as String,
        anoLetivo: json['ano_letivo'] as int,
        itens: (json['itens'] as List? ?? [])
            .map((e) => ItemPauta.fromJson(e as Map<String, dynamic>))
            .toList(),
        atualizadoEm: json['atualizado_em'] != null ? DateTime.parse(json['atualizado_em'] as String) : null,
        atualizadoPorNome: json['atualizado_por_nome'] as String?,
      );
}
