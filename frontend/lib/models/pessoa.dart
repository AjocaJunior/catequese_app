class Pessoa {
  final String id;
  final String nome;
  final String? naturalDe;
  final String? provincia;
  final String? estadoCivil;
  final String? profissao;
  final String? residencia;
  final String? comunidade;
  final String? contacto;

  Pessoa({
    required this.id,
    required this.nome,
    this.naturalDe,
    this.provincia,
    this.estadoCivil,
    this.profissao,
    this.residencia,
    this.comunidade,
    this.contacto,
  });

  factory Pessoa.fromJson(Map<String, dynamic> json) => Pessoa(
        id: json['id'] as String,
        nome: json['nome'] as String,
        naturalDe: json['natural_de'] as String?,
        provincia: json['provincia'] as String?,
        estadoCivil: json['estado_civil'] as String?,
        profissao: json['profissao'] as String?,
        residencia: json['residencia'] as String?,
        comunidade: json['comunidade'] as String?,
        contacto: json['contacto'] as String?,
      );
}

/// Um catequisando que referencia uma Pessoa, e em que papel (ex: para
/// mostrar "afilhados" de um padrinho, ou "filhos" de um pai/mãe).
class VinculoPessoa {
  final String catequisandoId;
  final String catequisandoNome;
  final String papel;

  VinculoPessoa({required this.catequisandoId, required this.catequisandoNome, required this.papel});

  factory VinculoPessoa.fromJson(Map<String, dynamic> json) => VinculoPessoa(
        catequisandoId: json['catequisando_id'] as String,
        catequisandoNome: json['catequisando_nome'] as String,
        papel: json['papel'] as String,
      );

  String get papelRotulo {
    switch (papel) {
      case 'pai':
        return 'Filho(a)';
      case 'mae':
        return 'Filho(a)';
      case 'padrinho':
        return 'Afilhado(a)';
      case 'madrinha':
        return 'Afilhado(a)';
      default:
        return papel;
    }
  }
}
