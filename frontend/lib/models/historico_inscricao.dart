class HistoricoInscricao {
  final int? anoLetivo;
  final String? faseId;
  final String faseNome;
  final String categoria;
  final DateTime data;

  HistoricoInscricao({
    this.anoLetivo,
    this.faseId,
    required this.faseNome,
    required this.categoria,
    required this.data,
  });

  factory HistoricoInscricao.fromJson(Map<String, dynamic> json) => HistoricoInscricao(
        anoLetivo: json['ano_letivo'] as int?,
        faseId: json['fase_id'] as String?,
        faseNome: json['fase_nome'] as String,
        categoria: json['categoria'] as String,
        data: DateTime.parse(json['data'] as String),
      );
}
