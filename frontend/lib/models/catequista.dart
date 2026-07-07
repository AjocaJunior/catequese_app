class Catequista {
  final String id;
  final String nome;
  final String email;
  final String? contacto;
  final bool isAdmin;

  Catequista({
    required this.id,
    required this.nome,
    required this.email,
    this.contacto,
    required this.isAdmin,
  });

  factory Catequista.fromJson(Map<String, dynamic> json) {
    return Catequista(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      contacto: json['contacto'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }
}
