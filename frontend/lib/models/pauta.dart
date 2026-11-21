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

enum Comportamento {
  razoavel,
  bom,
  excelente;

  String get valor {
    switch (this) {
      case Comportamento.razoavel:
        return 'razoavel';
      case Comportamento.bom:
        return 'bom';
      case Comportamento.excelente:
        return 'excelente';
    }
  }

  String get rotulo {
    switch (this) {
      case Comportamento.razoavel:
        return 'Razoável';
      case Comportamento.bom:
        return 'Bom';
      case Comportamento.excelente:
        return 'Excelente';
    }
  }

  static Comportamento? fromValor(String? v) {
    switch (v) {
      case 'razoavel':
        return Comportamento.razoavel;
      case 'bom':
        return Comportamento.bom;
      case 'excelente':
        return Comportamento.excelente;
      default:
        return null;
    }
  }
}

class ItemPauta {
  final String catequisandoId;
  final String catequisandoNome;
  final String? genero;
  final int totalPresencas;
  final int totalFaltas;
  final int totalFaltasJustificadas;
  Situacao? situacao;
  Comportamento? comportamento;
  String? observacao;

  ItemPauta({
    required this.catequisandoId,
    required this.catequisandoNome,
    this.genero,
    required this.totalPresencas,
    required this.totalFaltas,
    required this.totalFaltasJustificadas,
    this.situacao,
    this.comportamento,
    this.observacao,
  });

  factory ItemPauta.fromJson(Map<String, dynamic> json) => ItemPauta(
        catequisandoId: json['catequisando_id'] as String,
        catequisandoNome: json['catequisando_nome'] as String,
        genero: json['genero'] as String?,
        totalPresencas: json['total_presencas'] as int,
        totalFaltas: json['total_faltas'] as int,
        totalFaltasJustificadas: json['total_faltas_justificadas'] as int,
        situacao: Situacao.fromValor(json['situacao'] as String?),
        comportamento: Comportamento.fromValor(json['comportamento'] as String?),
        observacao: json['observacao'] as String?,
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
