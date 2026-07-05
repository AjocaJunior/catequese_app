class RetiroPublico {
  final String id;
  final String titulo;
  final DateTime data;
  final String local;
  final List<String> fases;

  RetiroPublico({
    required this.id,
    required this.titulo,
    required this.data,
    required this.local,
    required this.fases,
  });

  factory RetiroPublico.fromJson(Map<String, dynamic> json) => RetiroPublico(
        id: json['id'] as String,
        titulo: json['titulo'] as String,
        data: DateTime.parse(json['data'] as String),
        local: json['local'] as String,
        fases: (json['fases'] as List? ?? []).map((e) => e as String).toList(),
      );
}
