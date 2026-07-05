class Catequista {
  final String id;
  final String nome;
  final String email;
  final bool isAdmin;

  Catequista({
    required this.id,
    required this.nome,
    required this.email,
    required this.isAdmin,
  });

  factory Catequista.fromJson(Map<String, dynamic> json) {
    return Catequista(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }
}
