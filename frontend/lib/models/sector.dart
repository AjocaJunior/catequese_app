enum DiaSemana {
  segunda,
  terca,
  quarta,
  quinta,
  sexta,
  sabado,
  domingo;

  String get valor {
    switch (this) {
      case DiaSemana.segunda:
        return 'segunda';
      case DiaSemana.terca:
        return 'terca';
      case DiaSemana.quarta:
        return 'quarta';
      case DiaSemana.quinta:
        return 'quinta';
      case DiaSemana.sexta:
        return 'sexta';
      case DiaSemana.sabado:
        return 'sabado';
      case DiaSemana.domingo:
        return 'domingo';
    }
  }

  String get rotulo {
    switch (this) {
      case DiaSemana.segunda:
        return 'Segunda-feira';
      case DiaSemana.terca:
        return 'Terça-feira';
      case DiaSemana.quarta:
        return 'Quarta-feira';
      case DiaSemana.quinta:
        return 'Quinta-feira';
      case DiaSemana.sexta:
        return 'Sexta-feira';
      case DiaSemana.sabado:
        return 'Sábado';
      case DiaSemana.domingo:
        return 'Domingo';
    }
  }

  static DiaSemana? fromValor(String? v) {
    if (v == null) return null;
    return DiaSemana.values.firstWhere((d) => d.valor == v, orElse: () => DiaSemana.sabado);
  }
}

class Sector {
  final String id;
  final String nome;
  final DiaSemana? diaSemana;
  final String? hora;
  final String? local;
  final String? ministerioId;
  final String? ministerioNome;
  final String? responsavelNome;

  Sector({
    required this.id,
    required this.nome,
    this.diaSemana,
    this.hora,
    this.local,
    this.ministerioId,
    this.ministerioNome,
    this.responsavelNome,
  });

  factory Sector.fromJson(Map<String, dynamic> json) => Sector(
        id: json['id'] as String,
        nome: json['nome'] as String,
        diaSemana: DiaSemana.fromValor(json['dia_semana'] as String?),
        hora: json['hora'] as String?,
        local: json['local'] as String?,
        ministerioId: json['ministerio_id'] as String?,
        ministerioNome: json['ministerio_nome'] as String?,
        responsavelNome: json['responsavel_nome'] as String?,
      );
}
