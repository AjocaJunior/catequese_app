import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/catequisando.dart';
import '../models/presenca.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/catequisando_service.dart';
import '../services/fase_service.dart';
import '../services/presenca_service.dart';
import 'catequisando_form_screen.dart';

class CatequisandoDetalheScreen extends StatefulWidget {
  final Catequisando catequisando;

  const CatequisandoDetalheScreen({super.key, required this.catequisando});

  @override
  State<CatequisandoDetalheScreen> createState() => _CatequisandoDetalheScreenState();
}

class _CatequisandoDetalheScreenState extends State<CatequisandoDetalheScreen> {
  late Catequisando _catequisando;
  HistoricoPresencas? _historico;
  bool _carregandoHistorico = true;
  bool _imprimindo = false;
  bool _editando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _catequisando = widget.catequisando;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _carregandoHistorico = true);
    final token = context.read<AuthService>().token;
    try {
      final historico = await PresencaService(token).historico(_catequisando.id);
      if (!mounted) return;
      setState(() {
        _historico = historico;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar histórico de presenças');
    } finally {
      if (mounted) setState(() => _carregandoHistorico = false);
    }
  }

  Future<void> _editar() async {
    final token = context.read<AuthService>().token;
    setState(() => _editando = true);

    try {
      final fases = await FaseService(token).listar();
      if (!mounted) return;

      final resultado = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CatequisandoFormScreen(fases: fases, catequisando: _catequisando),
        ),
      );

      if (resultado == true) {
        final atualizados = await CatequisandoService(token).listar();
        final encontrado = atualizados.where((c) => c.id == _catequisando.id);
        if (encontrado.isNotEmpty && mounted) {
          setState(() => _catequisando = encontrado.first);
        }
        _carregarHistorico();
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao abrir edição';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _editando = false);
    }
  }

  Future<void> _imprimir() async {
    setState(() => _imprimindo = true);
    final token = context.read<AuthService>().token;
    try {
      final bytes = await CatequisandoService(token).baixarProcessoPdf(_catequisando.id);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao gerar PDF';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().catequista?.isAdmin ?? false;
    final c = _catequisando;

    return Scaffold(
        appBar: AppBar(
          title: Text(c.nome),
          actions: [
            IconButton(
              icon: _imprimindo
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.print_outlined),
              tooltip: 'Imprimir processo',
              onPressed: _imprimindo ? null : _imprimir,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _linha('Fase', c.faseNome),
                    if (c.sectorNome != null) _linha('Sector pastoral', c.sectorNome!),
                    if (c.dataNascimento != null)
                      _linha('Data de nascimento', _formatarData(c.dataNascimento!)),
                    if (c.encarregadoNome != null) _linha('Encarregado', c.encarregadoNome!),
                    if (c.encarregadoContacto != null) _linha('Contacto', c.encarregadoContacto!),
                    if (c.encarregadoParentesco != null) _linha('Parentesco', c.encarregadoParentesco!),
                    if (c.observacoes != null) _linha('Observações', c.observacoes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Presenças', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_carregandoHistorico)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_erro != null)
              Text(_erro!, style: const TextStyle(color: Colors.red))
            else if (_historico != null) ...[
              Row(
                children: [
                  _resumoChip('${_historico!.totalPresencas}', 'presenças', Colors.green),
                  const SizedBox(width: 8),
                  _resumoChip('${_historico!.totalFaltas}', 'faltas', Colors.red),
                  const SizedBox(width: 8),
                  _resumoChip('${_historico!.totalFaltasJustificadas}', 'justificadas', Colors.orange),
                  const SizedBox(width: 8),
                  _resumoChip(
                    _historico!.totalRegistos > 0
                        ? '${(_historico!.totalPresencas / _historico!.totalRegistos * 100).round()}%'
                        : '—',
                    'assiduidade',
                    Colors.blueGrey,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_historico!.registos.isEmpty)
                const Text('Ainda não há registos de presença.')
              else
                ..._historico!.registos.reversed.map((r) {
                  final IconData icone;
                  final Color cor;
                  switch (r.status) {
                    case StatusPresenca.presente:
                      icone = Icons.check_circle_outline;
                      cor = Colors.green;
                      break;
                    case StatusPresenca.falta:
                      icone = Icons.cancel_outlined;
                      cor = Colors.red;
                      break;
                    case StatusPresenca.faltaJustificada:
                      icone = Icons.shield_outlined;
                      cor = Colors.orange;
                      break;
                  }
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icone, color: cor),
                    title: Text(_formatarData(r.data)),
                    trailing: Text(r.status.rotulo),
                  );
                }),
            ],
          ],
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton(
                onPressed: _editando ? null : _editar,
                tooltip: 'Editar',
                child: _editando
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.edit_outlined),
              )
            : null,
    );
  }

  Widget _resumoChip(String valor, String rotulo, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
            Text(rotulo, style: TextStyle(fontSize: 11, color: cor)),
          ],
        ),
      ),
    );
  }

  Widget _linha(String rotulo, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(text: '$rotulo: ', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: valor),
            ],
          ),
        ),
      );
}
