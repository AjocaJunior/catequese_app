import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/retiro.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/retiro_service.dart';
import 'retiro_form_screen.dart';

class RetirosScreen extends StatefulWidget {
  const RetirosScreen({super.key});

  @override
  State<RetirosScreen> createState() => _RetirosScreenState();
}

class _RetirosScreenState extends State<RetirosScreen> {
  late RetiroService _service;
  bool _isAdmin = false;
  List<Retiro> _retiros = [];
  bool _loading = true;
  String? _erro;
  String? _aImprimirId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = RetiroService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final retiros = await _service.listar();
      if (!mounted) return;
      setState(() => _retiros = retiros);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar retiros');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirFormulario({Retiro? retiro}) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RetiroFormScreen(retiro: retiro)),
    );
    if (resultado == true) _carregar();
  }

  Future<void> _imprimir(Retiro retiro) async {
    setState(() => _aImprimirId = retiro.id);
    try {
      final bytes = await _service.baixarPdf(retiro.id);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao gerar PDF';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _aImprimirId = null);
    }
  }

  Future<void> _apagar(Retiro retiro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar retiro'),
        content: Text('Tens a certeza que queres apagar "${retiro.titulo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _service.apagar(retiro.id);
      _carregar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao apagar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retiros')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: _retiros.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('Ainda não há retiros.\nToca em + para criar o primeiro.', textAlign: TextAlign.center)),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _retiros.length,
                          itemBuilder: (context, i) {
                            final r = _retiros[i];
                            final fasesTexto = r.fases.map((f) => f.nome).join(', ');
                            final sectoresTexto = r.sectores.map((s) => s.nome).join(', ');
                            final participantesTexto = [fasesTexto, sectoresTexto]
                                .where((t) => t.isNotEmpty)
                                .join(' · ');
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.self_improvement_outlined)),
                              title: Text(r.titulo),
                              subtitle: Text(
                                '${_formatarData(r.data)} · ${r.local}'
                                '${participantesTexto.isNotEmpty ? '\n$participantesTexto' : ''}',
                              ),
                              isThreeLine: participantesTexto.isNotEmpty,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: _aImprimirId == r.id
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.print_outlined),
                                    tooltip: 'Imprimir / exportar PDF',
                                    onPressed: _aImprimirId == null ? () => _imprimir(r) : null,
                                  ),
                                  if (_isAdmin)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Apagar',
                                      onPressed: () => _apagar(r),
                                    ),
                                ],
                              ),
                              onTap: () => _abrirFormulario(retiro: r),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Novo retiro',
        child: const Icon(Icons.add),
      ),
    );
  }
}
