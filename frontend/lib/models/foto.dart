import '../config/api_config.dart';

class Foto {
  final String id;
  final String? titulo;
  final DateTime criadoEm;

  Foto({required this.id, this.titulo, required this.criadoEm});

  factory Foto.fromJson(Map<String, dynamic> json) => Foto(
        id: json['id'] as String,
        titulo: json['titulo'] as String?,
        criadoEm: DateTime.parse(json['criado_em'] as String),
      );

  /// URL pública da imagem (sem necessidade de token).
  String get urlImagem => '${ApiConfig.baseUrl}/publico/fotos/$id/imagem';
}
