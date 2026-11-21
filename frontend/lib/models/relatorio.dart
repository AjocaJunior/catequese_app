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

class LinhaRelatorioInscricoes {
  final String faseId;
  final String faseNome;
  final int ordem;
  final int totalCatequisandos;
  final int inscricoes;
  final int renovacoes;
  final int totalRegistado;
  final int pendentes;
  final double valorTotal;

  LinhaRelatorioInscricoes({
    required this.faseId,
    required this.faseNome,
    required this.ordem,
    required this.totalCatequisandos,
    required this.inscricoes,
    required this.renovacoes,
    required this.totalRegistado,
    required this.pendentes,
    required this.valorTotal,
  });

  factory LinhaRelatorioInscricoes.fromJson(Map<String, dynamic> json) => LinhaRelatorioInscricoes(
        faseId: json['fase_id'] as String,
        faseNome: json['fase_nome'] as String,
        ordem: json['ordem'] as int,
        totalCatequisandos: json['total_catequisandos'] as int,
        inscricoes: json['inscricoes'] as int,
        renovacoes: json['renovacoes'] as int,
        totalRegistado: json['total_registado'] as int,
        pendentes: json['pendentes'] as int,
        valorTotal: (json['valor_total'] as num).toDouble(),
      );
}

class RelatorioInscricoes {
  final int anoLetivo;
  final List<LinhaRelatorioInscricoes> linhas;
  final int totalCatequisandos;
  final int totalInscricoes;
  final int totalRenovacoes;
  final int totalRegistado;
  final int totalPendentes;
  final double valorTotal;

  RelatorioInscricoes({
    required this.anoLetivo,
    required this.linhas,
    required this.totalCatequisandos,
    required this.totalInscricoes,
    required this.totalRenovacoes,
    required this.totalRegistado,
    required this.totalPendentes,
    required this.valorTotal,
  });

  factory RelatorioInscricoes.fromJson(Map<String, dynamic> json) => RelatorioInscricoes(
        anoLetivo: json['ano_letivo'] as int,
        linhas: (json['linhas'] as List)
            .map((e) => LinhaRelatorioInscricoes.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalCatequisandos: json['total_catequisandos'] as int,
        totalInscricoes: json['total_inscricoes'] as int,
        totalRenovacoes: json['total_renovacoes'] as int,
        totalRegistado: json['total_registado'] as int,
        totalPendentes: json['total_pendentes'] as int,
        valorTotal: (json['valor_total'] as num).toDouble(),
      );
}

class LinhaObservacao {
  final int numero;
  final String catequisandoId;
  final String nome;
  final String observacoes;

  LinhaObservacao({
    required this.numero,
    required this.catequisandoId,
    required this.nome,
    required this.observacoes,
  });

  factory LinhaObservacao.fromJson(Map<String, dynamic> json) => LinhaObservacao(
        numero: json['numero'] as int,
        catequisandoId: json['catequisando_id'] as String,
        nome: json['nome'] as String,
        observacoes: json['observacoes'] as String,
      );
}

class GrupoFaseObservacoes {
  final String faseId;
  final String faseNome;
  final int ordem;
  final List<LinhaObservacao> linhas;

  GrupoFaseObservacoes({required this.faseId, required this.faseNome, required this.ordem, required this.linhas});

  factory GrupoFaseObservacoes.fromJson(Map<String, dynamic> json) => GrupoFaseObservacoes(
        faseId: json['fase_id'] as String,
        faseNome: json['fase_nome'] as String,
        ordem: json['ordem'] as int,
        linhas: (json['linhas'] as List).map((e) => LinhaObservacao.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class RelatorioObservacoes {
  final List<GrupoFaseObservacoes> grupos;
  final int total;

  RelatorioObservacoes({required this.grupos, required this.total});

  factory RelatorioObservacoes.fromJson(Map<String, dynamic> json) => RelatorioObservacoes(
        grupos: (json['grupos'] as List).map((e) => GrupoFaseObservacoes.fromJson(e as Map<String, dynamic>)).toList(),
        total: json['total'] as int,
      );
}

/// Catequisando ativo que ainda não tem Inscrição/Renovação lançada no ano.
class MatriculaPendente {
  final String catequisandoId;
  final String nome;
  final String faseId;
  final String faseNome;

  MatriculaPendente({
    required this.catequisandoId,
    required this.nome,
    required this.faseId,
    required this.faseNome,
  });

  factory MatriculaPendente.fromJson(Map<String, dynamic> json) => MatriculaPendente(
        catequisandoId: json['catequisando_id'] as String,
        nome: json['nome'] as String,
        faseId: json['fase_id'] as String,
        faseNome: json['fase_nome'] as String,
      );
}
