class Aniversariante {
  final String nome;
  final int idade;

  Aniversariante({required this.nome, required this.idade});

  factory Aniversariante.fromJson(Map<String, dynamic> json) => Aniversariante(
        nome: json['nome'] as String,
        idade: json['idade'] as int,
      );
}
