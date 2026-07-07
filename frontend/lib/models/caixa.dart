enum TipoTransacao {
  receita,
  despesa;

  String get valor => this == TipoTransacao.receita ? 'receita' : 'despesa';
  String get rotulo => this == TipoTransacao.receita ? 'Receita' : 'Despesa';

  static TipoTransacao fromValor(String v) => v == 'receita' ? TipoTransacao.receita : TipoTransacao.despesa;
}

enum MetodoPagamento {
  numerario,
  mpesa,
  emola;

  String get valor {
    switch (this) {
      case MetodoPagamento.numerario:
        return 'numerario';
      case MetodoPagamento.mpesa:
        return 'mpesa';
      case MetodoPagamento.emola:
        return 'emola';
    }
  }

  String get rotulo {
    switch (this) {
      case MetodoPagamento.numerario:
        return 'Numerário';
      case MetodoPagamento.mpesa:
        return 'M-Pesa';
      case MetodoPagamento.emola:
        return 'E-Mola';
    }
  }

  static MetodoPagamento? fromValor(String? v) {
    if (v == null) return null;
    return MetodoPagamento.values.firstWhere((m) => m.valor == v, orElse: () => MetodoPagamento.numerario);
  }
}

/// Categorias padrão usadas pelo ecrã de Inscrições e Renovações — os
/// valores exatos que o backend guarda e mostra.
class CategoriaCaixa {
  static const inscricao = 'Inscrição';
  static const renovacao = 'Renovação';
  static const fichaCatecumeno = 'Ficha do Catecúmeno';
}

class CaixaTransacao {
  final String id;
  final TipoTransacao tipo;
  final String categoria;
  final double valor;
  final MetodoPagamento? metodoPagamento;
  final String? catequisandoId;
  final String? catequisandoNome;
  final String? faseId;
  final String? faseNome;
  final int? anoLetivo;
  final String? descricao;
  final DateTime data;
  final String registadoPorNome;

  CaixaTransacao({
    required this.id,
    required this.tipo,
    required this.categoria,
    required this.valor,
    this.metodoPagamento,
    this.catequisandoId,
    this.catequisandoNome,
    this.faseId,
    this.faseNome,
    this.anoLetivo,
    this.descricao,
    required this.data,
    required this.registadoPorNome,
  });

  factory CaixaTransacao.fromJson(Map<String, dynamic> json) => CaixaTransacao(
        id: json['id'] as String,
        tipo: TipoTransacao.fromValor(json['tipo'] as String),
        categoria: json['categoria'] as String,
        valor: (json['valor'] as num).toDouble(),
        metodoPagamento: MetodoPagamento.fromValor(json['metodo_pagamento'] as String?),
        catequisandoId: json['catequisando_id'] as String?,
        catequisandoNome: json['catequisando_nome'] as String?,
        faseId: json['fase_id'] as String?,
        faseNome: json['fase_nome'] as String?,
        anoLetivo: json['ano_letivo'] as int?,
        descricao: json['descricao'] as String?,
        data: DateTime.parse(json['data'] as String),
        registadoPorNome: json['registado_por_nome'] as String,
      );
}

class ResumoCaixa {
  final double totalReceitas;
  final double totalDespesas;
  final double saldo;

  ResumoCaixa({required this.totalReceitas, required this.totalDespesas, required this.saldo});

  factory ResumoCaixa.fromJson(Map<String, dynamic> json) => ResumoCaixa(
        totalReceitas: (json['total_receitas'] as num).toDouble(),
        totalDespesas: (json['total_despesas'] as num).toDouble(),
        saldo: (json['saldo'] as num).toDouble(),
      );
}
