import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/relatorio.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/relatorio_service.dart';

enum _TipoRelatorio { faseGenero, situacaoFinal, assiduidade }

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  late RelatorioService _service;
  List<int> _anos = [];
  int? _anoSelecionado;
  _TipoRelatorio _tipo = _TipoRelatorio.faseGenero;

  RelatorioCatequisandosPorFaseGenero? _relFaseGenero;
  RelatorioSituacaoFinal? _relSituacaoFinal;
  RelatorioAssiduidade? _relAssiduidade;

  bool _loading = true;
  bool _imprimindo = false;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = RelatorioService(auth.token);
    _carregarAnos();
  }

  Future<void> _carregarAnos() async {
    try {
      final anos = await _service.anosDisponiveis();
      if (!mounted) return;
      setState(() {
        _anos = anos;
        _anoSelecionado = anos.isNotEmpty ? anos.first : null;
      });
      await _carregarRelatorio();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e is ApiException ? e.message : 'Erro ao carregar';
        _loading = false;
      });
    }
  }

  Future<void> _carregarRelatorio() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      switch (_tipo) {
        case _TipoRelatorio.faseGenero:
          _relFaseGenero = await _service.catequisandosPorFaseGenero(anoLetivo: _anoSelecionado);
          break;
        case _TipoRelatorio.situacaoFinal:
          _relSituacaoFinal = await _service.situacaoFinal(anoLetivo: _anoSelecionado);
          break;
        case _TipoRelatorio.assiduidade:
          _relAssiduidade = await _service.assiduidade(anoLetivo: _anoSelecionado);
          break;
      }
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar o relatório');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _imprimir() async {
    setState(() => _imprimindo = true);
    try {
      final bytes = switch (_tipo) {
        _TipoRelatorio.faseGenero => await _service.catequisandosPorFaseGeneroPdf(anoLetivo: _anoSelecionado),
        _TipoRelatorio.situacaoFinal => await _service.situacaoFinalPdf(anoLetivo: _anoSelecionado),
        _TipoRelatorio.assiduidade => await _service.assiduidadePdf(anoLetivo: _anoSelecionado),
      };
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao gerar PDF';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  Widget _chipTotal(String rotulo, String valor, Color cor) {
    return Expanded(
      child: Card(
        color: cor.withValues(alpha: 0.1),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            children: [
              Text(rotulo, style: TextStyle(fontSize: 12, color: cor.withValues(alpha: 0.9))),
              const SizedBox(height: 4),
              Text(valor, style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabela(List<String> cabecalhos, List<List<String>> linhas, {List<int>? flexes}) {
    final flexesReais = flexes ?? List.filled(cabecalhos.length, 1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: List.generate(cabecalhos.length, (i) {
                  return Expanded(
                    flex: flexesReais[i],
                    child: Text(
                      cabecalhos[i],
                      textAlign: i == 0 ? TextAlign.left : TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  );
                }),
              ),
            ),
            const Divider(height: 1),
            ...linhas.map((linha) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: List.generate(linha.length, (i) {
                      return Expanded(
                        flex: flexesReais[i],
                        child: Text(
                          linha[i],
                          overflow: TextOverflow.ellipsis,
                          textAlign: i == 0 ? TextAlign.left : TextAlign.center,
                          style: i == linha.length - 1 ? const TextStyle(fontWeight: FontWeight.bold) : null,
                        ),
                      );
                    }),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _conteudoRelatorio() {
    switch (_tipo) {
      case _TipoRelatorio.faseGenero:
        final r = _relFaseGenero;
        if (r == null || r.linhas.isEmpty) return const Center(child: Text('Sem dados para este ano letivo.'));
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Row(
              children: [
                _chipTotal('Total', '${r.totalGeral}', Colors.blueGrey),
                const SizedBox(width: 8),
                _chipTotal('Masculino', '${r.totalMasculino}', Colors.indigo),
                const SizedBox(width: 8),
                _chipTotal('Feminino', '${r.totalFeminino}', Colors.pink),
              ],
            ),
            const SizedBox(height: 16),
            _tabela(
              ['FASE', 'M', 'F', 'N/I', 'Total'],
              r.linhas.map((l) => [l.faseNome, '${l.masculino}', '${l.feminino}', '${l.naoInformado}', '${l.total}']).toList(),
              flexes: const [3, 1, 1, 1, 1],
            ),
            const SizedBox(height: 24),
          ],
        );
      case _TipoRelatorio.situacaoFinal:
        final r = _relSituacaoFinal;
        if (r == null || r.linhas.isEmpty) return const Center(child: Text('Sem dados para este ano letivo.'));
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Row(
              children: [
                _chipTotal('Permanece', '${r.totalPermanece}', Colors.orange),
                const SizedBox(width: 8),
                _chipTotal('Progride', '${r.totalProgride}', Colors.green),
                const SizedBox(width: 8),
                _chipTotal('Por definir', '${r.totalPorDefinir}', Colors.blueGrey),
              ],
            ),
            const SizedBox(height: 16),
            _tabela(
              ['FASE', 'Permanece', 'Progride', 'Por def.', 'Total'],
              r.linhas.map((l) => [l.faseNome, '${l.permanece}', '${l.progride}', '${l.porDefinir}', '${l.total}']).toList(),
              flexes: const [3, 1, 1, 1, 1],
            ),
            const SizedBox(height: 24),
          ],
        );
      case _TipoRelatorio.assiduidade:
        final r = _relAssiduidade;
        if (r == null || r.linhas.isEmpty) return const Center(child: Text('Sem dados para este ano letivo.'));
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Row(children: [_chipTotal('Assiduidade geral', '${r.taxaGeral.toStringAsFixed(1)}%', Colors.teal)]),
            const SizedBox(height: 16),
            _tabela(
              ['FASE', 'Cat.', 'Pres.', 'Faltas', 'Just.', 'Assid.'],
              r.linhas
                  .map((l) => [
                        l.faseNome,
                        '${l.totalCatequisandos}',
                        '${l.totalPresencas}',
                        '${l.totalFaltas}',
                        '${l.totalFaltasJustificadas}',
                        '${l.taxaAssiduidade.toStringAsFixed(1)}%',
                      ])
                  .toList(),
              flexes: const [3, 1, 1, 1, 1, 1],
            ),
            const SizedBox(height: 24),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            icon: _imprimindo
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.print_outlined),
            tooltip: 'Imprimir',
            onPressed: _imprimindo ? null : _imprimir,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: DropdownButtonFormField<_TipoRelatorio>(
                  value: _tipo,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Relatório',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: _TipoRelatorio.faseGenero, child: Text('Catequisandos por Fase e Género')),
                    DropdownMenuItem(value: _TipoRelatorio.situacaoFinal, child: Text('Situação Final por Fase')),
                    DropdownMenuItem(value: _TipoRelatorio.assiduidade, child: Text('Assiduidade Geral')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _tipo = v);
                    _carregarRelatorio();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: DropdownButtonFormField<int>(
                  value: _anoSelecionado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ano letivo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _anos.map((a) => DropdownMenuItem(value: a, child: Text('$a'))).toList(),
                  onChanged: (v) {
                    setState(() => _anoSelecionado = v);
                    _carregarRelatorio();
                  },
                ),
              ),
              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_erro != null)
                Expanded(child: Center(child: Text(_erro!)))
              else
                Expanded(child: _conteudoRelatorio()),
            ],
          ),
        ),
      ),
    );
  }
}
