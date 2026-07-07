import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/fase.dart';
import '../models/pauta.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/fase_service.dart';
import '../services/pauta_service.dart';

class PautaScreen extends StatefulWidget {
  const PautaScreen({super.key});

  @override
  State<PautaScreen> createState() => _PautaScreenState();
}

class _PautaScreenState extends State<PautaScreen> {
  late FaseService _faseService;
  late PautaService _pautaService;
  bool _isAdmin = false;
  String? _meuId;

  List<Fase> _fases = [];
  String? _faseId;
  Pauta? _pauta;

  bool _carregandoFases = true;
  bool _carregandoPauta = false;
  bool _guardando = false;
  bool _imprimindo = false;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _faseService = FaseService(auth.token);
    _pautaService = PautaService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _meuId = auth.catequista?.id;
    _carregarFases();
  }

  Future<void> _carregarFases() async {
    setState(() => _carregandoFases = true);
    try {
      final todasAsFases = await _faseService.listar();
      final fasesPermitidas = _isAdmin
          ? todasAsFases
          : todasAsFases.where((f) => f.catequistas.any((c) => c.id == _meuId)).toList();
      if (!mounted) return;
      setState(() {
        _fases = fasesPermitidas;
        _faseId ??= fasesPermitidas.isNotEmpty ? fasesPermitidas.first.id : null;
      });
      if (_faseId != null) await _carregarPauta();
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar fases');
    } finally {
      if (mounted) setState(() => _carregandoFases = false);
    }
  }

  Future<void> _carregarPauta() async {
    if (_faseId == null) return;
    setState(() {
      _carregandoPauta = true;
      _erro = null;
    });
    try {
      final pauta = await _pautaService.obter(faseId: _faseId!);
      if (!mounted) return;
      setState(() => _pauta = pauta);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar a pauta');
    } finally {
      if (mounted) setState(() => _carregandoPauta = false);
    }
  }

  Future<void> _guardar() async {
    if (_pauta == null) return;
    setState(() => _guardando = true);
    try {
      final atualizada = await _pautaService.definir(faseId: _pauta!.faseId, itens: _pauta!.itens);
      if (!mounted) return;
      setState(() => _pauta = atualizada);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pauta guardada')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao guardar a pauta';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _imprimir() async {
    if (_pauta == null) return;
    setState(() => _imprimindo = true);
    try {
      final bytes = await _pautaService.baixarPdf(faseId: _pauta!.faseId);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao gerar PDF';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pauta'),
        actions: [
          if (_pauta != null)
            IconButton(
              icon: _imprimindo
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.print_outlined),
              tooltip: 'Imprimir pauta',
              onPressed: _imprimindo ? null : _imprimir,
            ),
        ],
      ),
      body: _carregandoFases
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: DropdownButtonFormField<String>(
                        value: _faseId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Fase',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _fases
                            .map((f) => DropdownMenuItem(
                                  value: f.id,
                                  child: Text(f.nome, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _faseId = v);
                          _carregarPauta();
                        },
                      ),
                    ),
                    if (_pauta != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Text('Ano letivo: ${_pauta!.anoLetivo}', style: const TextStyle(color: Colors.black54)),
                            if (_pauta!.atualizadoPorNome != null) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Última atualização por ${_pauta!.atualizadoPorNome}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (_erro != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(_erro!, style: const TextStyle(color: Colors.red)),
                      ),
                    if (_fases.isEmpty)
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              _isAdmin
                                  ? 'Cria uma fase e regista catequisandos primeiro.'
                                  : 'Ainda não foste atribuído a nenhuma fase.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    else if (_carregandoPauta)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else if (_pauta == null || _pauta!.itens.isEmpty)
                      const Expanded(child: Center(child: Text('Não há catequisandos nesta fase.')))
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: _pauta!.itens.length,
                          itemBuilder: (context, i) {
                            final item = _pauta!.itens[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.catequisandoNome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _chip('${item.totalPresencas}', 'presenças', Colors.green),
                                        const SizedBox(width: 6),
                                        _chip('${item.totalFaltas}', 'faltas', Colors.red),
                                        const SizedBox(width: 6),
                                        _chip('${item.totalFaltasJustificadas}', 'justif.', Colors.orange),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SegmentedButton<Situacao>(
                                      segments: const [
                                        ButtonSegment(value: Situacao.permanece, label: Text('Permanece')),
                                        ButtonSegment(value: Situacao.progride, label: Text('Progride')),
                                      ],
                                      selected: item.situacao != null ? {item.situacao!} : {},
                                      emptySelectionAllowed: true,
                                      onSelectionChanged: (v) {
                                        setState(() => item.situacao = v.isEmpty ? null : v.first);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (_pauta != null && _pauta!.itens.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _guardando ? null : _guardar,
                            icon: _guardando
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_guardando ? 'A guardar...' : 'Guardar pauta'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _chip(String valor, String rotulo, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text('$valor $rotulo', style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
