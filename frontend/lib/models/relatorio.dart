class LinhaRelatorioFaseGenero {
  final String faseId;
  final String faseNome;
  final int ordem;
  final int masculino;
  final int feminino;
  final int naoInformado;
  final int total;

  LinhaRelatorioFaseGenero({
    required this.faseId,
    required this.faseNome,
    required this.ordem,
    required this.masculino,
    required this.feminino,
    required this.naoInformado,
    required this.total,
  });

  factory LinhaRelatorioFaseGenero.fromJson(Map<String, dynamic> json) => LinhaRelatorioFaseGenero(
        faseId: json['fase_id'] as String,
        faseNome: json['fase_nome'] as String,
        ordem: json['ordem'] as int,
        masculino: json['masculino'] as int,
        feminino: json['feminino'] as int,
        naoInformado: json['nao_informado'] as int,
        total: json['total'] as int,
      );
}

class RelatorioCatequisandosPorFaseGenero {
  final int anoLetivo;
  final List<LinhaRelatorioFaseGenero> linhas;
  final int totalMasculino;
  final int totalFeminino;
  final int totalNaoInformado;
  final int totalGeral;

  RelatorioCatequisandosPorFaseGenero({
    required this.anoLetivo,
    required this.linhas,
    required this.totalMasculino,
    required this.totalFeminino,
    required this.totalNaoInformado,
    required this.totalGeral,
  });

  factory RelatorioCatequisandosPorFaseGenero.fromJson(Map<String, dynamic> json) =>
      RelatorioCatequisandosPorFaseGenero(
        anoLetivo: json['ano_letivo'] as int,
        linhas: (json['linhas'] as List)
            .map((e) => LinhaRelatorioFaseGenero.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalMasculino: json['total_masculino'] as int,
        totalFeminino: json['total_feminino'] as int,
        totalNaoInformado: json['total_nao_informado'] as int,
        totalGeral: json['total_geral'] as int,
      );
}

class LinhaRelatorioSituacaoFinal {
  final String faseId;
  final String faseNome;
  final int ordem;
  final int permanece;
  final int progride;
  final int porDefinir;
  final int total;

  LinhaRelatorioSituacaoFinal({
    required this.faseId,
    required this.faseNome,
    required this.ordem,
    required this.permanece,
    required this.progride,
    required this.porDefinir,
    required this.total,
  });

  factory LinhaRelatorioSituacaoFinal.fromJson(Map<String, dynamic> json) => LinhaRelatorioSituacaoFinal(
        faseId: json['fase_id'] as String,
        faseNome: json['fase_nome'] as String,
        ordem: json['ordem'] as int,
        permanece: json['permanece'] as int,
        progride: json['progride'] as int,
        porDefinir: json['por_definir'] as int,
        total: json['total'] as int,
      );
}

class RelatorioSituacaoFinal {
  final int anoLetivo;
  final List<LinhaRelatorioSituacaoFinal> linhas;
  final int totalPermanece;
  final int totalProgride;
  final int totalPorDefinir;
  final int totalGeral;

  RelatorioSituacaoFinal({
    required this.anoLetivo,
    required this.linhas,
    required this.totalPermanece,
    required this.totalProgride,
    required this.totalPorDefinir,
    required this.totalGeral,
  });

  factory RelatorioSituacaoFinal.fromJson(Map<String, dynamic> json) => RelatorioSituacaoFinal(
        anoLetivo: json['ano_letivo'] as int,
        linhas: (json['linhas'] as List)
            .map((e) => LinhaRelatorioSituacaoFinal.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalPermanece: json['total_permanece'] as int,
        totalProgride: json['total_progride'] as int,
        totalPorDefinir: json['total_por_definir'] as int,
        totalGeral: json['total_geral'] as int,
      );
}

class LinhaRelatorioAssiduidade {
  final String faseId;
  final String faseNome;
  final int ordem;
  final int totalCatequisandos;
  final int totalPresencas;
  final int totalFaltas;
  final int totalFaltasJustificadas;
  final double taxaAssiduidade;

  LinhaRelatorioAssiduidade({
    required this.faseId,
    required this.faseNome,
    required this.ordem,
    required this.totalCatequisandos,
    required this.totalPresencas,
    required this.totalFaltas,
    required this.totalFaltasJustificadas,
    required this.taxaAssiduidade,
  });

  factory LinhaRelatorioAssiduidade.fromJson(Map<String, dynamic> json) => LinhaRelatorioAssiduidade(
        faseId: json['fase_id'] as String,
        faseNome: json['fase_nome'] as String,
        ordem: json['ordem'] as int,
        totalCatequisandos: json['total_catequisandos'] as int,
        totalPresencas: json['total_presencas'] as int,
        totalFaltas: json['total_faltas'] as int,
        totalFaltasJustificadas: json['total_faltas_justificadas'] as int,
        taxaAssiduidade: (json['taxa_assiduidade'] as num).toDouble(),
      );
}

class RelatorioAssiduidade {
  final int anoLetivo;
  final List<LinhaRelatorioAssiduidade> linhas;
  final double taxaGeral;

  RelatorioAssiduidade({required this.anoLetivo, required this.linhas, required this.taxaGeral});

  factory RelatorioAssiduidade.fromJson(Map<String, dynamic> json) => RelatorioAssiduidade(
        anoLetivo: json['ano_letivo'] as int,
        linhas: (json['linhas'] as List)
            .map((e) => LinhaRelatorioAssiduidade.fromJson(e as Map<String, dynamic>))
            .toList(),
        taxaGeral: (json['taxa_geral'] as num).toDouble(),
      );
}
