enum AcaoAuditoria {
  criar,
  atualizar,
  apagar;

  String get rotulo {
    switch (this) {
      case AcaoAuditoria.criar:
        return 'Criou';
      case AcaoAuditoria.atualizar:
        return 'Editou';
      case AcaoAuditoria.apagar:
        return 'Apagou';
    }
  }

  static AcaoAuditoria fromValor(String v) {
    switch (v) {
      case 'criar':
        return AcaoAuditoria.criar;
      case 'atualizar':
        return AcaoAuditoria.atualizar;
      case 'apagar':
        return AcaoAuditoria.apagar;
      default:
        return AcaoAuditoria.criar;
    }
  }
}

class RegistoAuditoria {
  final String id;
  final DateTime data;
  final String? catequistaId;
  final String catequistaNome;
  final AcaoAuditoria acao;
  final String entidade;
  final String? entidadeId;
  final String resumo;

  RegistoAuditoria({
    required this.id,
    required this.data,
    this.catequistaId,
    required this.catequistaNome,
    required this.acao,
    required this.entidade,
    this.entidadeId,
    required this.resumo,
  });

  factory RegistoAuditoria.fromJson(Map<String, dynamic> json) => RegistoAuditoria(
        id: json['id'] as String,
        data: DateTime.parse(json['data'] as String),
        catequistaId: json['catequista_id'] as String?,
        catequistaNome: json['catequista_nome'] as String,
        acao: AcaoAuditoria.fromValor(json['acao'] as String),
        entidade: json['entidade'] as String,
        entidadeId: json['entidade_id'] as String?,
        resumo: json['resumo'] as String,
      );
}
