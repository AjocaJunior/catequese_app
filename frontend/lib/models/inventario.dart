enum EstadoItem {
  bom,
  emUso,
  novo,
  descartado,
  danificado,
  antigo,
  naoAplicavel;

  String get valor {
    switch (this) {
      case EstadoItem.bom:
        return 'bom';
      case EstadoItem.emUso:
        return 'em_uso';
      case EstadoItem.novo:
        return 'novo';
      case EstadoItem.descartado:
        return 'descartado';
      case EstadoItem.danificado:
        return 'danificado';
      case EstadoItem.antigo:
        return 'antigo';
      case EstadoItem.naoAplicavel:
        return 'nao_aplicavel';
    }
  }

  String get rotulo {
    switch (this) {
      case EstadoItem.bom:
        return 'Bom';
      case EstadoItem.emUso:
        return 'Em Uso';
      case EstadoItem.novo:
        return 'Novo';
      case EstadoItem.descartado:
        return 'Descartado';
      case EstadoItem.danificado:
        return 'Danificado';
      case EstadoItem.antigo:
        return 'Antigo';
      case EstadoItem.naoAplicavel:
        return 'N/A';
    }
  }

  static EstadoItem? fromValor(String? v) {
    if (v == null) return null;
    return EstadoItem.values.firstWhere((e) => e.valor == v, orElse: () => EstadoItem.naoAplicavel);
  }
}

class ItemInventario {
  final String id;
  final String nome;
  final String? sectorId;
  final String? sectorNome;
  final String? categoria;
  final int quantidade;
  final String? descricao;
  final String? localizacao;
  final String? imagemUrl;
  final EstadoItem? estado;
  final String? criadoPorNome;
  final DateTime? atualizadoEm;
  final String? atualizadoPorNome;

  ItemInventario({
    required this.id,
    required this.nome,
    this.sectorId,
    this.sectorNome,
    this.categoria,
    required this.quantidade,
    this.descricao,
    this.localizacao,
    this.imagemUrl,
    this.estado,
    this.criadoPorNome,
    this.atualizadoEm,
    this.atualizadoPorNome,
  });

  factory ItemInventario.fromJson(Map<String, dynamic> json) => ItemInventario(
        id: json['id'] as String,
        nome: json['nome'] as String,
        sectorId: json['sector_id'] as String?,
        sectorNome: json['sector_nome'] as String?,
        categoria: json['categoria'] as String?,
        quantidade: json['quantidade'] as int,
        descricao: json['descricao'] as String?,
        localizacao: json['localizacao'] as String?,
        imagemUrl: json['imagem_url'] as String?,
        estado: EstadoItem.fromValor(json['estado'] as String?),
        criadoPorNome: json['criado_por_nome'] as String?,
        atualizadoEm: json['atualizado_em'] != null ? DateTime.parse(json['atualizado_em'] as String) : null,
        atualizadoPorNome: json['atualizado_por_nome'] as String?,
      );
}
