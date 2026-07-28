import 'pessoa.dart';

enum Genero {
  masculino,
  feminino;

  String get valor => this == Genero.masculino ? 'masculino' : 'feminino';
  String get rotulo => this == Genero.masculino ? 'Masculino' : 'Feminino';

  static Genero? fromValor(String? v) {
    if (v == null) return null;
    return v == 'masculino' ? Genero.masculino : Genero.feminino;
  }
}

enum SituacaoCatequisando {
  ativo,
  crismado,
  transferido;

  String get valor {
    switch (this) {
      case SituacaoCatequisando.ativo:
        return 'ativo';
      case SituacaoCatequisando.crismado:
        return 'crismado';
      case SituacaoCatequisando.transferido:
        return 'transferido';
    }
  }

  String get rotulo {
    switch (this) {
      case SituacaoCatequisando.ativo:
        return 'Ativo';
      case SituacaoCatequisando.crismado:
        return 'Crismado';
      case SituacaoCatequisando.transferido:
        return 'Transferido';
    }
  }

  static SituacaoCatequisando fromValor(String? v) {
    switch (v) {
      case 'crismado':
        return SituacaoCatequisando.crismado;
      case 'transferido':
        return SituacaoCatequisando.transferido;
      default:
        return SituacaoCatequisando.ativo;
    }
  }
}

class Catequisando {
  final String id;
  final String nome;
  final Genero? genero;
  final DateTime? dataNascimento;
  final String? naturalDe;
  final String? estadoCivil;
  final String? profissao;
  final String? residencia;
  final String faseId;
  final String faseNome;
  final String? sectorId;
  final String? sectorNome;
  final SituacaoCatequisando situacao;
  final DateTime? dataSituacao;
  final String? encarregadoNome;
  final String? encarregadoContacto;
  final String? encarregadoParentesco;
  final String? observacoes;

  // Ficha do Catecúmeno — Ano/Número de registo
  final int? fichaAno;
  final String? fichaNumero;

  // Filiação — por referência a Pessoa (reutilizável entre irmãos)
  final String? paiId;
  final Pessoa? pai;
  final String? maeId;
  final Pessoa? mae;
  final String? avoPaternoNome;
  final String? avoPaternaNome;
  final String? avoMaternoNome;
  final String? avoMaternaNome;

  // Padrinhos — idem, por referência (reutilizável entre afilhados)
  final String? padrinhoId;
  final Pessoa? padrinho;
  final String? madrinhaId;
  final Pessoa? madrinha;

  // Eleição e Escrutínios (RCIA) — opcional
  final DateTime? eleicaoData;
  final DateTime? escrutinio1Data;
  final DateTime? escrutinio2Data;
  final DateTime? escrutinio3Data;

  // Baptismo
  final String? baptismoLocal;
  final DateTime? baptismoData;
  final String? baptismoCertidaoUrl;

  // Núcleo (como um Sector, mas do Ministério da Animação dos Núcleos)
  final String? nucleoId;
  final String? nucleoNome;
  final String? nucleoComunidade;

  // Ficha de Baptismo — campos adicionais
  final String? baptismoArquidiocese;
  final String? baptismoLivro;
  final String? baptismoNumeroRegisto;
  final String? baptismoPagina;

  // Ficha de 1ª Comunhão
  final DateTime? primeiraComunhaoData;
  final String? primeiraComunhaoHora;
  final String? primeiraComunhaoLivro;
  final String? primeiraComunhaoNumeroRegisto;
  final String? primeiraComunhaoPagina;

  // Ficha de Crisma
  final DateTime? crismaData;
  final String? crismaHora;
  final String? crismaLivro;
  final String? crismaNumeroRegisto;
  final String? crismaPagina;

  // Transferência para outra paróquia/comunidade
  final String? transferenciaNumero;
  final int? transferenciaAnoGuia;
  final int? transferenciaAnoFrequentado;
  final String? transferenciaDestinoComunidade;
  final String? transferenciaDestinoArquidiocese;
  final String? transferenciaObservacao;
  final DateTime? transferenciaData;

  Catequisando({
    required this.id,
    required this.nome,
    this.genero,
    this.dataNascimento,
    this.naturalDe,
    this.estadoCivil,
    this.profissao,
    this.residencia,
    required this.faseId,
    required this.faseNome,
    this.sectorId,
    this.sectorNome,
    this.situacao = SituacaoCatequisando.ativo,
    this.dataSituacao,
    this.encarregadoNome,
    this.encarregadoContacto,
    this.encarregadoParentesco,
    this.observacoes,
    this.fichaAno,
    this.fichaNumero,
    this.paiId,
    this.pai,
    this.maeId,
    this.mae,
    this.avoPaternoNome,
    this.avoPaternaNome,
    this.avoMaternoNome,
    this.avoMaternaNome,
    this.padrinhoId,
    this.padrinho,
    this.madrinhaId,
    this.madrinha,
    this.eleicaoData,
    this.escrutinio1Data,
    this.escrutinio2Data,
    this.escrutinio3Data,
    this.baptismoLocal,
    this.baptismoData,
    this.baptismoCertidaoUrl,
    this.nucleoId,
    this.nucleoNome,
    this.nucleoComunidade,
    this.baptismoArquidiocese,
    this.baptismoLivro,
    this.baptismoNumeroRegisto,
    this.baptismoPagina,
    this.primeiraComunhaoData,
    this.primeiraComunhaoHora,
    this.primeiraComunhaoLivro,
    this.primeiraComunhaoNumeroRegisto,
    this.primeiraComunhaoPagina,
    this.crismaData,
    this.crismaHora,
    this.crismaLivro,
    this.crismaNumeroRegisto,
    this.crismaPagina,
    this.transferenciaNumero,
    this.transferenciaAnoGuia,
    this.transferenciaAnoFrequentado,
    this.transferenciaDestinoComunidade,
    this.transferenciaDestinoArquidiocese,
    this.transferenciaObservacao,
    this.transferenciaData,
  });

  static DateTime? _data(dynamic v) => v != null ? DateTime.parse(v as String) : null;

  factory Catequisando.fromJson(Map<String, dynamic> json) => Catequisando(
        id: json['id'] as String,
        nome: json['nome'] as String,
        genero: Genero.fromValor(json['genero'] as String?),
        dataNascimento: _data(json['data_nascimento']),
        naturalDe: json['natural_de'] as String?,
        estadoCivil: json['estado_civil'] as String?,
        profissao: json['profissao'] as String?,
        residencia: json['residencia'] as String?,
        faseId: json['fase_id'] as String,
        faseNome: json['fase_nome'] as String,
        sectorId: json['sector_id'] as String?,
        sectorNome: json['sector_nome'] as String?,
        situacao: SituacaoCatequisando.fromValor(json['situacao'] as String?),
        dataSituacao: _data(json['data_situacao']),
        encarregadoNome: json['encarregado_nome'] as String?,
        encarregadoContacto: json['encarregado_contacto'] as String?,
        encarregadoParentesco: json['encarregado_parentesco'] as String?,
        observacoes: json['observacoes'] as String?,
        fichaAno: json['ficha_ano'] as int?,
        fichaNumero: json['ficha_numero'] as String?,
        paiId: json['pai_id'] as String?,
        pai: json['pai'] != null ? Pessoa.fromJson(json['pai'] as Map<String, dynamic>) : null,
        maeId: json['mae_id'] as String?,
        mae: json['mae'] != null ? Pessoa.fromJson(json['mae'] as Map<String, dynamic>) : null,
        avoPaternoNome: json['avo_paterno_nome'] as String?,
        avoPaternaNome: json['avo_paterna_nome'] as String?,
        avoMaternoNome: json['avo_materno_nome'] as String?,
        avoMaternaNome: json['avo_materna_nome'] as String?,
        padrinhoId: json['padrinho_id'] as String?,
        padrinho: json['padrinho'] != null ? Pessoa.fromJson(json['padrinho'] as Map<String, dynamic>) : null,
        madrinhaId: json['madrinha_id'] as String?,
        madrinha: json['madrinha'] != null ? Pessoa.fromJson(json['madrinha'] as Map<String, dynamic>) : null,
        eleicaoData: _data(json['eleicao_data']),
        escrutinio1Data: _data(json['escrutinio_1_data']),
        escrutinio2Data: _data(json['escrutinio_2_data']),
        escrutinio3Data: _data(json['escrutinio_3_data']),
        baptismoLocal: json['baptismo_local'] as String?,
        baptismoData: _data(json['baptismo_data']),
        baptismoCertidaoUrl: json['baptismo_certidao_url'] as String?,
        nucleoId: json['nucleo_id'] as String?,
        nucleoNome: json['nucleo_nome'] as String?,
        nucleoComunidade: json['nucleo_comunidade'] as String?,
        baptismoArquidiocese: json['baptismo_arquidiocese'] as String?,
        baptismoLivro: json['baptismo_livro'] as String?,
        baptismoNumeroRegisto: json['baptismo_numero_registo'] as String?,
        baptismoPagina: json['baptismo_pagina'] as String?,
        primeiraComunhaoData: _data(json['primeira_comunhao_data']),
        primeiraComunhaoHora: json['primeira_comunhao_hora'] as String?,
        primeiraComunhaoLivro: json['primeira_comunhao_livro'] as String?,
        primeiraComunhaoNumeroRegisto: json['primeira_comunhao_numero_registo'] as String?,
        primeiraComunhaoPagina: json['primeira_comunhao_pagina'] as String?,
        crismaData: _data(json['crisma_data']),
        crismaHora: json['crisma_hora'] as String?,
        crismaLivro: json['crisma_livro'] as String?,
        crismaNumeroRegisto: json['crisma_numero_registo'] as String?,
        crismaPagina: json['crisma_pagina'] as String?,
        transferenciaNumero: json['transferencia_numero'] as String?,
        transferenciaAnoGuia: json['transferencia_ano_guia'] as int?,
        transferenciaAnoFrequentado: json['transferencia_ano_frequentado'] as int?,
        transferenciaDestinoComunidade: json['transferencia_destino_comunidade'] as String?,
        transferenciaDestinoArquidiocese: json['transferencia_destino_arquidiocese'] as String?,
        transferenciaObservacao: json['transferencia_observacao'] as String?,
        transferenciaData: _data(json['transferencia_data']),
      );
}

class ErroImportacao {
  final int linha;
  final String motivo;

  ErroImportacao({required this.linha, required this.motivo});

  factory ErroImportacao.fromJson(Map<String, dynamic> json) =>
      ErroImportacao(linha: json['linha'] as int, motivo: json['motivo'] as String);
}

class ImportacaoResultado {
  final int totalLinhas;
  final int criados;
  final List<ErroImportacao> erros;

  ImportacaoResultado({required this.totalLinhas, required this.criados, required this.erros});

  factory ImportacaoResultado.fromJson(Map<String, dynamic> json) => ImportacaoResultado(
        totalLinhas: json['total_linhas'] as int,
        criados: json['criados'] as int,
        erros: (json['erros'] as List).map((e) => ErroImportacao.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
