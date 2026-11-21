class Configuracao {
  final int anoLetivoAtual;

  Configuracao({required this.anoLetivoAtual});

  factory Configuracao.fromJson(Map<String, dynamic> json) => Configuracao(
        anoLetivoAtual: json['ano_letivo_atual'] as int,
      );
}

/// Resposta de "avançar ano letivo": o novo ano e, se a transição de fases
/// foi aplicada, quantos catequisandos mudaram de fase.
class ResultadoAvancoAno {
  final int anoLetivoAtual;
  final bool transicaoAplicada;
  final int movidos;
  final int permaneceram;
  final int porDefinir;
  final int semFaseSeguinte;

  ResultadoAvancoAno({
    required this.anoLetivoAtual,
    required this.transicaoAplicada,
    required this.movidos,
    required this.permaneceram,
    required this.porDefinir,
    required this.semFaseSeguinte,
  });

  factory ResultadoAvancoAno.fromJson(Map<String, dynamic> json) => ResultadoAvancoAno(
        anoLetivoAtual: json['ano_letivo_atual'] as int,
        transicaoAplicada: json['transicao_aplicada'] as bool? ?? false,
        movidos: json['movidos'] as int? ?? 0,
        permaneceram: json['permaneceram'] as int? ?? 0,
        porDefinir: json['por_definir'] as int? ?? 0,
        semFaseSeguinte: json['sem_fase_seguinte'] as int? ?? 0,
      );
}

class CatequisandoTransicao {
  final String catequisandoId;
  final String nome;

  CatequisandoTransicao({required this.catequisandoId, required this.nome});

  factory CatequisandoTransicao.fromJson(Map<String, dynamic> json) => CatequisandoTransicao(
        catequisandoId: json['catequisando_id'] as String,
        nome: json['nome'] as String,
      );
}

class LinhaTransicaoFase {
  final String faseId;
  final String faseNome;
  final int ordem;
  final bool transitoria;
  final String? faseSeguinteNome;
  final int total;
  final int aMover;
  final int permanecem;
  final int porDefinir;
  final int semFaseSeguinte;
  final List<CatequisandoTransicao> listaPorDefinir;
  final List<CatequisandoTransicao> listaSemFaseSeguinte;

  LinhaTransicaoFase({
    required this.faseId,
    required this.faseNome,
    required this.ordem,
    required this.transitoria,
    this.faseSeguinteNome,
    required this.total,
    required this.aMover,
    required this.permanecem,
    required this.porDefinir,
    required this.semFaseSeguinte,
    this.listaPorDefinir = const [],
    this.listaSemFaseSeguinte = const [],
  });

  factory LinhaTransicaoFase.fromJson(Map<String, dynamic> json) => LinhaTransicaoFase(
        faseId: json['fase_id'] as String,
        faseNome: json['fase_nome'] as String,
        ordem: json['ordem'] as int,
        transitoria: json['transitoria'] as bool? ?? false,
        faseSeguinteNome: json['fase_seguinte_nome'] as String?,
        total: json['total'] as int? ?? 0,
        aMover: json['a_mover'] as int? ?? 0,
        permanecem: json['permanecem'] as int? ?? 0,
        porDefinir: json['por_definir'] as int? ?? 0,
        semFaseSeguinte: json['sem_fase_seguinte'] as int? ?? 0,
        listaPorDefinir: (json['lista_por_definir'] as List? ?? [])
            .map((e) => CatequisandoTransicao.fromJson(e as Map<String, dynamic>))
            .toList(),
        listaSemFaseSeguinte: (json['lista_sem_fase_seguinte'] as List? ?? [])
            .map((e) => CatequisandoTransicao.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// O que aconteceria a cada catequisando se o ano avançasse agora.
class PreviaTransicao {
  final int anoAtual;
  final int novoAno;
  final List<LinhaTransicaoFase> linhas;
  final int totalAMover;
  final int totalPermanecem;
  final int totalPorDefinir;
  final int totalSemFaseSeguinte;
  final List<String> avisos;

  PreviaTransicao({
    required this.anoAtual,
    required this.novoAno,
    required this.linhas,
    required this.totalAMover,
    required this.totalPermanecem,
    required this.totalPorDefinir,
    required this.totalSemFaseSeguinte,
    required this.avisos,
  });

  factory PreviaTransicao.fromJson(Map<String, dynamic> json) => PreviaTransicao(
        anoAtual: json['ano_atual'] as int,
        novoAno: json['novo_ano'] as int,
        linhas: (json['linhas'] as List? ?? [])
            .map((e) => LinhaTransicaoFase.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalAMover: json['total_a_mover'] as int? ?? 0,
        totalPermanecem: json['total_permanecem'] as int? ?? 0,
        totalPorDefinir: json['total_por_definir'] as int? ?? 0,
        totalSemFaseSeguinte: json['total_sem_fase_seguinte'] as int? ?? 0,
        avisos: (json['avisos'] as List? ?? []).map((e) => e as String).toList(),
      );
}
