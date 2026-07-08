class SectorResumoCatequista {
  final String id;
  final String nome;

  SectorResumoCatequista({required this.id, required this.nome});

  factory SectorResumoCatequista.fromJson(Map<String, dynamic> json) => SectorResumoCatequista(
        id: json['id'] as String,
        nome: json['nome'] as String,
      );
}

class Catequista {
  final String id;
  final String nome;
  final String email;
  final String? contacto;
  final bool isAdmin;
  final bool temFaseAtribuida;
  final List<SectorResumoCatequista> sectoresResponsavel;

  Catequista({
    required this.id,
    required this.nome,
    required this.email,
    this.contacto,
    required this.isAdmin,
    this.temFaseAtribuida = false,
    this.sectoresResponsavel = const [],
  });

  /// Nível de acesso pleno: administrador, ou catequista atribuído a uma
  /// fase — vê todos os módulos de gestão da catequese.
  bool get temAcessoCompleto => isAdmin || temFaseAtribuida;

  /// É responsável por pelo menos um sector — vê o Inventário (limitado ao
  /// seu sector), mesmo sem acesso completo.
  bool get eResponsavelDeSector => sectoresResponsavel.isNotEmpty;

  factory Catequista.fromJson(Map<String, dynamic> json) {
    return Catequista(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      contacto: json['contacto'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      temFaseAtribuida: json['tem_fase_atribuida'] as bool? ?? false,
      sectoresResponsavel: (json['sectores_responsavel'] as List? ?? [])
          .map((e) => SectorResumoCatequista.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
