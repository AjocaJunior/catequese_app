class FaseResumo {
  final String id;
  final String nome;

  FaseResumo({required this.id, required this.nome});

  factory FaseResumo.fromJson(Map<String, dynamic> json) => FaseResumo(
        id: json['id'] as String,
        nome: json['nome'] as String,
      );
}

class SectorResumoRetiro {
  final String id;
  final String nome;

  SectorResumoRetiro({required this.id, required this.nome});

  factory SectorResumoRetiro.fromJson(Map<String, dynamic> json) => SectorResumoRetiro(
        id: json['id'] as String,
        nome: json['nome'] as String,
      );
}

class ProgramaItem {
  String hora;
  String atividade;
  String responsavel;

  ProgramaItem({required this.hora, required this.atividade, required this.responsavel});

  factory ProgramaItem.fromJson(Map<String, dynamic> json) => ProgramaItem(
        hora: json['hora'] as String,
        atividade: json['atividade'] as String,
        responsavel: json['responsavel'] as String,
      );

  Map<String, dynamic> toJson() => {
        'hora': hora,
        'atividade': atividade,
        'responsavel': responsavel,
      };
}

class Retiro {
  final String id;
  final String titulo;
  final List<FaseResumo> fases;
  final List<SectorResumoRetiro> sectores;
  final DateTime data;
  final String local;
  final List<String> oradores;
  final String tema;
  final List<ProgramaItem> programa;

  Retiro({
    required this.id,
    required this.titulo,
    required this.fases,
    required this.sectores,
    required this.data,
    required this.local,
    required this.oradores,
    required this.tema,
    required this.programa,
  });

  factory Retiro.fromJson(Map<String, dynamic> json) => Retiro(
        id: json['id'] as String,
        titulo: json['titulo'] as String,
        fases: (json['fases'] as List? ?? [])
            .map((e) => FaseResumo.fromJson(e as Map<String, dynamic>))
            .toList(),
        sectores: (json['sectores'] as List? ?? [])
            .map((e) => SectorResumoRetiro.fromJson(e as Map<String, dynamic>))
            .toList(),
        data: DateTime.parse(json['data'] as String),
        local: json['local'] as String,
        oradores: (json['oradores'] as List? ?? []).map((e) => e as String).toList(),
        tema: json['tema'] as String? ?? '',
        programa: (json['programa'] as List? ?? [])
            .map((e) => ProgramaItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
