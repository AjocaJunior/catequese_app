class Evento {
  final String id;
  final String titulo;
  final DateTime data;
  final String? local;
  final String? descricao;

  Evento({
    required this.id,
    required this.titulo,
    required this.data,
    this.local,
    this.descricao,
  });

  factory Evento.fromJson(Map<String, dynamic> json) => Evento(
        id: json['id'] as String,
        titulo: json['titulo'] as String,
        data: DateTime.parse(json['data'] as String),
        local: json['local'] as String?,
        descricao: json['descricao'] as String?,
      );
}
