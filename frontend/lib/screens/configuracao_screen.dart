import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/configuracao.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/configuracao_service.dart';

class ConfiguracaoScreen extends StatefulWidget {
  const ConfiguracaoScreen({super.key});

  @override
  State<ConfiguracaoScreen> createState() => _ConfiguracaoScreenState();
}

class _ConfiguracaoScreenState extends State<ConfiguracaoScreen> {
  late ConfiguracaoService _service;
  bool _isAdmin = false;
  Configuracao? _configuracao;
  bool _loading = true;
  bool _avancando = false;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = ConfiguracaoService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final config = await _service.obter();
      if (!mounted) return;
      setState(() => _configuracao = config);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// "Maria, Joana e mais 3" — para não encher o diálogo com listas longas.
  String _resumirNomes(List<CatequisandoTransicao> lista, {int max = 6}) {
    final nomes = lista.map((c) => c.nome).toList();
    if (nomes.length <= max) return nomes.join(', ');
    return '${nomes.take(max).join(', ')} e mais ${nomes.length - max}';
  }

  Future<void> _avancarAno() async {
    final anoAtual = _configuracao!.anoLetivoAtual;
    final novoAno = anoAtual + 1;

    // 1) Pré-visualização: o que acontece a cada catequisando (não altera nada).
    setState(() => _avancando = true);
    PreviaTransicao? previaCarregada;
    String? erroPrevia;
    try {
      previaCarregada = await _service.previaTransicao(novoAno);
    } catch (e) {
      erroPrevia = e is ApiException ? e.message : 'Erro ao preparar a transição';
    }
    if (!mounted) return;
    setState(() => _avancando = false);
    if (previaCarregada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erroPrevia ?? 'Erro ao preparar a transição')),
      );
      return;
    }
    final PreviaTransicao previa = previaCarregada;

    // 2) Confirmação, com a prévia à vista.
    bool aplicarTransicao = true;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final linhasComMovimento = previa.linhas
              .where((l) => l.aMover > 0 || l.semFaseSeguinte > 0 || l.porDefinir > 0)
              .toList();
          return AlertDialog(
            title: Text('Avançar para $novoAno'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'As pautas e os relatórios de $anoAtual ficam guardados tal como estão — '
                      'mesmo que os catequisandos mudem de fase.',
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mover quem progride para a fase seguinte'),
                      subtitle: const Text('Só quem tem resultado "Progride" na pauta.'),
                      value: aplicarTransicao,
                      onChanged: (v) => setStateDialog(() => aplicarTransicao = v),
                    ),
                    if (aplicarTransicao) ...[
                      const Divider(),
                      Text(
                        '${previa.totalAMover} mudam de fase · ${previa.totalPermanecem} ficam na fase actual',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (linhasComMovimento.isEmpty)
                        const Text('Ninguém tem resultado "Progride" para mover.'),
                      for (final l in linhasComMovimento) ...[
                        Text(
                          l.faseSeguinteNome != null ? '${l.faseNome} → ${l.faseSeguinteNome}' : l.faseNome,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          [
                            if (l.aMover > 0) '${l.aMover} mudam de fase',
                            if (l.transitoria) 'fase transitória: sai quem tem data de baptismo',
                            if (l.semFaseSeguinte > 0) '${l.semFaseSeguinte} sem fase seguinte',
                            if (l.porDefinir > 0 && !l.transitoria) '${l.porDefinir} sem resultado',
                          ].join(' · '),
                          style: const TextStyle(color: Colors.black54),
                        ),
                        if (l.listaSemFaseSeguinte.isNotEmpty)
                          Text(
                            'Sem fase seguinte: ${_resumirNomes(l.listaSemFaseSeguinte)}',
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        if (l.listaPorDefinir.isNotEmpty && !l.transitoria)
                          Text(
                            'Sem resultado: ${_resumirNomes(l.listaPorDefinir)}',
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        const SizedBox(height: 8),
                      ],
                      if (previa.avisos.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            border: Border.all(color: Colors.orange.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Atenção', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              for (final a in previa.avisos)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(a, style: const TextStyle(fontSize: 13)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'As atribuições de catequistas continuam iguais em $novoAno. A matrícula de cada um '
                      'fica registada quando lançares a inscrição/renovação — quem ainda não renovou '
                      'aparece em "Inscrições e Renovações".',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Avançar para $novoAno'),
              ),
            ],
          );
        },
      ),
    );
    if (confirmar != true) return;

    setState(() => _avancando = true);
    try {
      final resultado = await _service.avancarAnoLetivo(novoAno, aplicarTransicao: aplicarTransicao);
      if (!mounted) return;
      setState(() => _configuracao = Configuracao(anoLetivoAtual: resultado.anoLetivoAtual));
      final texto = resultado.transicaoAplicada
          ? 'Ano letivo avançado para $novoAno — ${resultado.movidos} catequisando(s) mudaram de fase'
          : 'Ano letivo avançado para $novoAno';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao avançar o ano letivo';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _avancando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Ano Letivo')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 480 : double.infinity),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.calendar_month_outlined, size: 40, color: Colors.blueGrey),
                                  const SizedBox(height: 12),
                                  const Text('Ano letivo corrente', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_configuracao?.anoLetivoAtual ?? '—'}',
                                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_isAdmin) ...[
                            const Text(
                              'Ao avançar o ano, os registos do ano corrente (inscrições, renovações, '
                              'pautas, atribuições de catequistas) ficam guardados e não são mais alterados. '
                              'Antes de confirmares, vês quem muda de fase.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: _avancando ? null : _avancarAno,
                                icon: _avancando
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.arrow_forward),
                                label: Text(_avancando
                                    ? 'A avançar...'
                                    : 'Avançar para ${(_configuracao?.anoLetivoAtual ?? 0) + 1}'),
                              ),
                            ),
                          ] else
                            const Text(
                              'Só administradores podem avançar o ano letivo.',
                              style: TextStyle(color: Colors.black54),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
