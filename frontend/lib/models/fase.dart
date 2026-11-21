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
  final String? faseSeguinteId;
  final String? faseSeguinteNome;

  /// Fase de passagem (ex: Sacramento do Baptismo): sai-se dela ao registar
  /// a data de baptismo.
  final bool transitoria;
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
    this.faseSeguinteId,
    this.faseSeguinteNome,
    this.transitoria = false,
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
        faseSeguinteId: json['fase_seguinte_id'] as String?,
        faseSeguinteNome: json['fase_seguinte_nome'] as String?,
        transitoria: json['transitoria'] as bool? ?? false,
        catequistas: (json['catequistas'] as List? ?? [])
            .map((e) => CatequistaResumo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
