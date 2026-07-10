class ErroImportacao {
  final int linha;
  final String motivo;

  ErroImportacao({required this.linha, required this.motivo});

  factory ErroImportacao.fromJson(Map<String, dynamic> json) => ErroImportacao(
        linha: json['linha'] as int,
        motivo: json['motivo'] as String,
      );
}

class ImportacaoResultado {
  final int totalLinhas;
  final int criados;
  final List<ErroImportacao> erros;

  ImportacaoResultado({required this.totalLinhas, required this.criados, required this.erros});

  factory ImportacaoResultado.fromJson(Map<String, dynamic> json) => ImportacaoResultado(
        totalLinhas: json['total_linhas'] as int,
        criados: json['criados'] as int,
        erros: (json['erros'] as List? ?? [])
            .map((e) => ErroImportacao.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

enum Genero {
  masculino,
  feminino;

  String get valor => this == Genero.masculino ? 'masculino' : 'feminino';
  String get rotulo => this == Genero.masculino ? 'Masculino' : 'Feminino';

  static Genero? fromValor(String? v) {
    if (v == null) return null;
    return v == 'masculino' ? Genero.masculino : Genero.feminino;
  }
}

enum SituacaoCatequisando {
  ativo,
  crismado;

  String get valor => this == SituacaoCatequisando.ativo ? 'ativo' : 'crismado';
  String get rotulo => this == SituacaoCatequisando.ativo ? 'Ativo' : 'Crismado';

  static SituacaoCatequisando fromValor(String? v) {
    return v == 'crismado' ? SituacaoCatequisando.crismado : SituacaoCatequisando.ativo;
  }
}

class Catequisando {
  final String id;
  final String nome;
  final Genero? genero;
  final DateTime? dataNascimento;
  final String faseId;
  final String faseNome;
  final String? sectorId;
  final String? sectorNome;
  final SituacaoCatequisando situacao;
  final DateTime? dataSituacao;
  final String? encarregadoNome;
  final String? encarregadoContacto;
  final String? encarregadoParentesco;
  final String? observacoes;

  Catequisando({
    required this.id,
    required this.nome,
    this.genero,
    this.dataNascimento,
    required this.faseId,
    required this.faseNome,
    this.sectorId,
    this.sectorNome,
    this.situacao = SituacaoCatequisando.ativo,
    this.dataSituacao,
    this.encarregadoNome,
    this.encarregadoContacto,
    this.encarregadoParentesco,
    this.observacoes,
  });

  factory Catequisando.fromJson(Map<String, dynamic> json) => Catequisando(
        id: json['id'] as String,
        nome: json['nome'] as String,
        genero: Genero.fromValor(json['genero'] as String?),
        dataNascimento: json['data_nascimento'] != null
            ? DateTime.parse(json['data_nascimento'] as String)
            : null,
        faseId: json['fase_id'] as String,
        faseNome: json['fase_nome'] as String,
        sectorId: json['sector_id'] as String?,
        sectorNome: json['sector_nome'] as String?,
        situacao: SituacaoCatequisando.fromValor(json['situacao'] as String?),
        dataSituacao: json['data_situacao'] != null ? DateTime.parse(json['data_situacao'] as String) : null,
        encarregadoNome: json['encarregado_nome'] as String?,
        encarregadoContacto: json['encarregado_contacto'] as String?,
        encarregadoParentesco: json['encarregado_parentesco'] as String?,
        observacoes: json['observacoes'] as String?,
      );
}
