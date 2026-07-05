class SectorOrganograma {
  final String id;
  final String nome;
  final String? responsavelNome;

  SectorOrganograma({required this.id, required this.nome, this.responsavelNome});

  factory SectorOrganograma.fromJson(Map<String, dynamic> json) => SectorOrganograma(
        id: json['id'] as String,
        nome: json['nome'] as String,
        responsavelNome: json['responsavel_nome'] as String?,
      );
}

class MinisterioOrganograma {
  final String id;
  final String nome;
  final String? coordenadorNome;
  final List<SectorOrganograma> sectores;

  MinisterioOrganograma({
    required this.id,
    required this.nome,
    this.coordenadorNome,
    required this.sectores,
  });

  factory MinisterioOrganograma.fromJson(Map<String, dynamic> json) => MinisterioOrganograma(
        id: json['id'] as String,
        nome: json['nome'] as String,
        coordenadorNome: json['coordenador_nome'] as String?,
        sectores: (json['sectores'] as List? ?? [])
            .map((e) => SectorOrganograma.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Organograma {
  final List<MinisterioOrganograma> ministerios;
  final List<SectorOrganograma> sectoresSemMinisterio;

  Organograma({required this.ministerios, required this.sectoresSemMinisterio});

  factory Organograma.fromJson(Map<String, dynamic> json) => Organograma(
        ministerios: (json['ministerios'] as List? ?? [])
            .map((e) => MinisterioOrganograma.fromJson(e as Map<String, dynamic>))
            .toList(),
        sectoresSemMinisterio: (json['sectores_sem_ministerio'] as List? ?? [])
            .map((e) => SectorOrganograma.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
