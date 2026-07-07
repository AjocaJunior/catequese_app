class Configuracao {
  final int anoLetivoAtual;

  Configuracao({required this.anoLetivoAtual});

  factory Configuracao.fromJson(Map<String, dynamic> json) => Configuracao(
        anoLetivoAtual: json['ano_letivo_atual'] as int,
      );
}
