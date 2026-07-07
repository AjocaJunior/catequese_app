class ItemInventario {
  final String id;
  final String nome;
  final int quantidade;
  final String? descricao;

  ItemInventario({
    required this.id,
    required this.nome,
    required this.quantidade,
    this.descricao,
  });

  factory ItemInventario.fromJson(Map<String, dynamic> json) => ItemInventario(
        id: json['id'] as String,
        nome: json['nome'] as String,
        quantidade: json['quantidade'] as int,
        descricao: json['descricao'] as String?,
      );
}
