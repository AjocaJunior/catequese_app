/// Os 3 estados possíveis de presença numa catequese.
enum StatusPresenca {
  presente,
  falta,
  faltaJustificada;

  String get valor {
    switch (this) {
      case StatusPresenca.presente:
        return 'presente';
      case StatusPresenca.falta:
        return 'falta';
      case StatusPresenca.faltaJustificada:
        return 'falta_justificada';
    }
  }

  String get rotulo {
    switch (this) {
      case StatusPresenca.presente:
        return 'Presença';
      case StatusPresenca.falta:
        return 'Falta';
      case StatusPresenca.faltaJustificada:
        return 'Falta Justificada';
    }
  }

  String get rotuloCurto {
    switch (this) {
      case StatusPresenca.presente:
        return 'P';
      case StatusPresenca.falta:
        return 'F';
      case StatusPresenca.faltaJustificada:
        return 'FJ';
    }
  }

  static StatusPresenca fromValor(String valor) {
    switch (valor) {
      case 'presente':
        return StatusPresenca.presente;
      case 'falta_justificada':
        return StatusPresenca.faltaJustificada;
      case 'falta':
      default:
        return StatusPresenca.falta;
    }
  }
}

class RegistoPresenca {
  final DateTime data;
  final StatusPresenca status;

  RegistoPresenca({required this.data, required this.status});

  factory RegistoPresenca.fromJson(Map<String, dynamic> json) => RegistoPresenca(
        data: DateTime.parse(json['data'] as String),
        status: StatusPresenca.fromValor(json['status'] as String),
      );
}

class HistoricoPresencas {
  final int totalRegistos;
  final int totalPresencas;
  final int totalFaltas;
  final int totalFaltasJustificadas;
  final List<RegistoPresenca> registos;

  HistoricoPresencas({
    required this.totalRegistos,
    required this.totalPresencas,
    required this.totalFaltas,
    required this.totalFaltasJustificadas,
    required this.registos,
  });

  factory HistoricoPresencas.fromJson(Map<String, dynamic> json) => HistoricoPresencas(
        totalRegistos: json['total_registos'] as int,
        totalPresencas: json['total_presencas'] as int,
        totalFaltas: json['total_faltas'] as int,
        totalFaltasJustificadas: json['total_faltas_justificadas'] as int,
        registos: (json['registos'] as List? ?? [])
            .map((e) => RegistoPresenca.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PresencaItem {
  final String catequisandoId;
  final String catequisandoNome;
  StatusPresenca status;

  PresencaItem({
    required this.catequisandoId,
    required this.catequisandoNome,
    required this.status,
  });

  factory PresencaItem.fromJson(Map<String, dynamic> json) => PresencaItem(
        catequisandoId: json['catequisando_id'] as String,
        catequisandoNome: json['catequisando_nome'] as String,
        status: StatusPresenca.fromValor(json['status'] as String),
      );

  Map<String, dynamic> toRequestJson() => {
        'catequisando_id': catequisandoId,
        'status': status.valor,
      };
}
