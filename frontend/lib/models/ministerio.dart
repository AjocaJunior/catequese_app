class Ministerio {
  final String id;
  final String nome;
  final String? coordenadorNome;

  Ministerio({required this.id, required this.nome, this.coordenadorNome});

  factory Ministerio.fromJson(Map<String, dynamic> json) => Ministerio(
        id: json['id'] as String,
        nome: json['nome'] as String,
        coordenadorNome: json['coordenador_nome'] as String?,
      );
}
