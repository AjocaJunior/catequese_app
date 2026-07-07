import 'sector.dart' show DiaSemana;

class CatequistaResumo {
  final String id;
  final String nome;

  CatequistaResumo({required this.id, required this.nome});

  factory CatequistaResumo.fromJson(Map<String, dynamic> json) => CatequistaResumo(
        id: json['id'] as String,
        nome: json['nome'] as String,
      );
}

class Fase {
  final String id;
  final String nome;
  final int ordem;
  final String? nomeCatecismo;
  final DiaSemana? diaSemana;
  final String? hora;
  final String? local;
  final String? programaPdfUrl;
  final List<CatequistaResumo> catequistas;

  Fase({
    required this.id,
    required this.nome,
    required this.ordem,
    this.nomeCatecismo,
    this.diaSemana,
    this.hora,
    this.local,
    this.programaPdfUrl,
    this.catequistas = const [],
  });

  factory Fase.fromJson(Map<String, dynamic> json) => Fase(
        id: json['id'] as String,
        nome: json['nome'] as String,
        ordem: json['ordem'] as int,
        nomeCatecismo: json['nome_catecismo'] as String?,
        diaSemana: DiaSemana.fromValor(json['dia_semana'] as String?),
        hora: json['hora'] as String?,
        local: json['local'] as String?,
        programaPdfUrl: json['programa_pdf_url'] as String?,
        catequistas: (json['catequistas'] as List? ?? [])
            .map((e) => CatequistaResumo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
