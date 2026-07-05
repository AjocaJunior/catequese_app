import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/fase.dart';
import '../models/presenca.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/fase_service.dart';
import '../services/presenca_service.dart';

class PresencasScreen extends StatefulWidget {
  const PresencasScreen({super.key});

  @override
  State<PresencasScreen> createState() => _PresencasScreenState();
}

class _PresencasScreenState extends State<PresencasScreen> {
  late FaseService _faseService;
  late PresencaService _presencaService;
  bool _isAdmin = false;
  String? _meuId;

  List<Fase> _fases = [];
  String? _faseId;
  DateTime _data = _proximoFimDeSemana();
  List<PresencaItem> _presencas = [];

  bool _carregandoFases = true;
  bool _carregandoPresencas = false;
  bool _guardando = false;
  bool _imprimindoRelatorio = false;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _faseService = FaseService(auth.token);
    _presencaService = PresencaService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _meuId = auth.catequista?.id;
    _carregarFases();
  }

  static DateTime _proximoFimDeSemana() {
    var d = DateTime.now();
    while (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
      d = d.add(const Duration(days: 1));
    }
    return DateTime(d.year, d.month, d.day);
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
      if (_faseId != null) await _carregarPresencas();
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar fases');
    } finally {
      if (mounted) setState(() => _carregandoFases = false);
    }
  }

  Future<void> _carregarPresencas() async {
    if (_faseId == null) return;
    setState(() {
      _carregandoPresencas = true;
      _erro = null;
    });
    try {
      final presencas = await _presencaService.listar(faseId: _faseId!, data: _data);
      if (!mounted) return;
      setState(() => _presencas = presencas);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar presenças');
    } finally {
      if (mounted) setState(() => _carregandoPresencas = false);
    }
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Data da catequese (sábado ou domingo)',
      selectableDayPredicate: (d) => d.weekday == DateTime.saturday || d.weekday == DateTime.sunday,
    );
    if (escolhida != null) {
      setState(() => _data = escolhida);
      await _carregarPresencas();
    }
  }

  Future<void> _guardar() async {
    if (_faseId == null) return;
    setState(() => _guardando = true);
    try {
      final atualizado = await _presencaService.marcar(
        faseId: _faseId!,
        data: _data,
        presencas: _presencas,
      );
      if (!mounted) return;
      setState(() => _presencas = atualizado);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presenças guardadas')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao guardar presenças';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _imprimirRelatorio() async {
    if (_faseId == null) return;
    setState(() => _imprimindoRelatorio = true);
    try {
      final bytes = await _presencaService.baixarRelatorioPdf(_faseId!);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao gerar relatório';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _imprimindoRelatorio = false);
    }
  }

  String _formatarDataVisual(DateTime d) {
    const diasSemana = {7: 'Domingo', 6: 'Sábado'};
    final dia = diasSemana[d.weekday] ?? '';
    return '$dia, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Color _corStatus(StatusPresenca s) {
    switch (s) {
      case StatusPresenca.presente:
        return Colors.green;
      case StatusPresenca.falta:
        return Colors.red;
      case StatusPresenca.faltaJustificada:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcar presenças'),
        actions: [
          if (_faseId != null)
            IconButton(
              icon: _imprimindoRelatorio
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.summarize_outlined),
              tooltip: 'Relatório de presenças da fase',
              onPressed: _imprimindoRelatorio ? null : _imprimirRelatorio,
            ),
        ],
      ),
      body: _carregandoFases
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 640 : double.infinity),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
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
                                _carregarPresencas();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _escolherData,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Data',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                                ),
                                child: Text(_formatarDataVisual(_data)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_presencas.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: StatusPresenca.values.map((s) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 10, height: 10, color: _corStatus(s)),
                                  const SizedBox(width: 4),
                                  Text('${s.rotuloCurto} = ${s.rotulo}', style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                            );
                          }).toList(),
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
                                  : 'Ainda não foste atribuído a nenhuma fase.\nPede a um administrador para te associar a uma fase em "Fases catequéticas".',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    else if (_carregandoPresencas)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else if (_presencas.isEmpty)
                      const Expanded(child: Center(child: Text('Não há catequisandos nesta fase.')))
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: _presencas.length,
                          itemBuilder: (context, i) {
                            final p = _presencas[i];
                            return ListTile(
                              title: Text(p.catequisandoNome),
                              trailing: SegmentedButton<StatusPresenca>(
                                segments: StatusPresenca.values
                                    .map((s) => ButtonSegment(value: s, label: Text(s.rotuloCurto)))
                                    .toList(),
                                selected: {p.status},
                                showSelectedIcon: false,
                                onSelectionChanged: (novo) => setState(() => p.status = novo.first),
                                style: SegmentedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  selectedBackgroundColor: _corStatus(p.status).withValues(alpha: 0.2),
                                  selectedForegroundColor: _corStatus(p.status),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (_presencas.isNotEmpty)
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
                            label: Text(_guardando ? 'A guardar...' : 'Guardar presenças'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
