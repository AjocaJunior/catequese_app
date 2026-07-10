class LeituraLiturgia {
  final String titulo;
  final String texto;

  LeituraLiturgia({required this.titulo, required this.texto});

  factory LeituraLiturgia.fromJson(Map<String, dynamic> json) => LeituraLiturgia(
        titulo: json['titulo'] as String,
        texto: json['texto'] as String,
      );
}

class SalmoLiturgia {
  final String titulo;
  final String resposta;
  final List<String> versos;

  SalmoLiturgia({required this.titulo, required this.resposta, required this.versos});

  factory SalmoLiturgia.fromJson(Map<String, dynamic> json) => SalmoLiturgia(
        titulo: json['titulo'] as String,
        resposta: json['resposta'] as String,
        versos: (json['versos'] as List).map((e) => e as String).toList(),
      );
}

class LiturgiaDiaria {
  final bool disponivel;
  final String? data;
  final String? corLiturgica;
  final String? tempoLiturgico;
  final LeituraLiturgia? primeiraLeitura;
  final LeituraLiturgia? segundaLeitura;
  final SalmoLiturgia? salmo;
  final LeituraLiturgia? evangelho;
  final String fonteUrl;

  LiturgiaDiaria({
    required this.disponivel,
    this.data,
    this.corLiturgica,
    this.tempoLiturgico,
    this.primeiraLeitura,
    this.segundaLeitura,
    this.salmo,
    this.evangelho,
    required this.fonteUrl,
  });

  factory LiturgiaDiaria.fromJson(Map<String, dynamic> json) => LiturgiaDiaria(
        disponivel: json['disponivel'] as bool,
        data: json['data'] as String?,
        corLiturgica: json['cor_liturgica'] as String?,
        tempoLiturgico: json['tempo_liturgico'] as String?,
        primeiraLeitura: json['primeira_leitura'] != null
            ? LeituraLiturgia.fromJson(json['primeira_leitura'] as Map<String, dynamic>)
            : null,
        segundaLeitura: json['segunda_leitura'] != null
            ? LeituraLiturgia.fromJson(json['segunda_leitura'] as Map<String, dynamic>)
            : null,
        salmo: json['salmo'] != null ? SalmoLiturgia.fromJson(json['salmo'] as Map<String, dynamic>) : null,
        evangelho:
            json['evangelho'] != null ? LeituraLiturgia.fromJson(json['evangelho'] as Map<String, dynamic>) : null,
        fonteUrl: json['fonte_url'] as String,
      );
}
