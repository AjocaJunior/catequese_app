import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/catequisando.dart';
import '../models/fase.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/catequisando_service.dart';
import '../services/fase_service.dart';
import 'catequisando_detalhe_screen.dart';
import 'catequisando_form_screen.dart';
import 'importar_catequisandos_screen.dart';

class CatequisandosScreen extends StatefulWidget {
  const CatequisandosScreen({super.key});

  @override
  State<CatequisandosScreen> createState() => _CatequisandosScreenState();
}

class _CatequisandosScreenState extends State<CatequisandosScreen> {
  late CatequisandoService _catequisandoService;
  late FaseService _faseService;
  List<Catequisando> _catequisandos = [];
  List<Fase> _fases = [];
  String? _fasesFiltroId;
  bool _loading = true;
  String? _erro;
  bool _imprimindo = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.read<AuthService>().token;
    _catequisandoService = CatequisandoService(token);
    _faseService = FaseService(token);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final fases = await _faseService.listar();
      final catequisandos = await _catequisandoService.listar(faseId: _fasesFiltroId);
      if (!mounted) return;
      setState(() {
        _fases = fases;
        _catequisandos = catequisandos;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar catequisandos');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _imprimirLista() async {
    if (_fasesFiltroId == null) return;
    setState(() => _imprimindo = true);
    try {
      final bytes = await _catequisandoService.baixarListaPdf(_fasesFiltroId!);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao gerar PDF da lista';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  Future<void> _abrirImportacao() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ImportarCatequisandosScreen()),
    );
    if (resultado == true) _carregar();
  }

  Future<void> _abrirDetalhe(Catequisando c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CatequisandoDetalheScreen(catequisando: c)),
    );
    // Recarrega sempre ao voltar (pode ter havido edição dentro do ecrã de detalhe)
    _carregar();
  }

  Future<void> _mudarFase(Catequisando c) async {
    String? novaFaseId = c.faseId;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Mudar de fase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Catequisando: ${c.nome}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: novaFaseId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Nova fase', border: OutlineInputBorder()),
                items: _fases
                    .map((f) => DropdownMenuItem(
                          value: f.id,
                          child: Text(f.nome, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setStateDialog(() => novaFaseId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
          ],
        ),
      ),
    );

    if (confirmar != true || novaFaseId == null || novaFaseId == c.faseId) return;

    try {
      await _catequisandoService.atualizar(c.id, {'fase_id': novaFaseId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fase atualizada')));
      _carregar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao mudar de fase';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _abrirFormulario({Catequisando? catequisando}) async {
    if (_fases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cria pelo menos uma fase antes de registar catequisandos')),
      );
      return;
    }
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CatequisandoFormScreen(fases: _fases, catequisando: catequisando),
      ),
    );
    if (resultado == true) _carregar();
  }

  Future<void> _apagar(Catequisando c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar catequisando'),
        content: Text('Tens a certeza que queres apagar "${c.nome}"?'),
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
      await _catequisandoService.apagar(c.id);
      _carregar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Ocorreu um erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().catequista?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catequisandos'),
        actions: [
          if (_fasesFiltroId != null)
            IconButton(
              icon: _imprimindo
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.print_outlined),
              tooltip: 'Imprimir lista desta fase',
              onPressed: _imprimindo ? null : _imprimirLista,
            ),
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Importar de ficheiro',
            onPressed: _abrirImportacao,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButtonFormField<String?>(
              value: _fasesFiltroId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Filtrar por fase',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas as fases')),
                ..._fases.map((f) => DropdownMenuItem(
                      value: f.id,
                      child: Text(f.nome, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (value) {
                setState(() => _fasesFiltroId = value);
                _carregar();
              },
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_erro != null)
            Expanded(child: Center(child: Text(_erro!)))
          else if (_catequisandos.isEmpty)
            const Expanded(child: Center(child: Text('Nenhum catequisando encontrado.')))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _carregar,
                child: ListView.builder(
                  itemCount: _catequisandos.length,
                  itemBuilder: (context, i) {
                    final c = _catequisandos[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(c.nome),
                      subtitle: Text(c.faseNome),
                      trailing: isAdmin
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.swap_horiz),
                                  tooltip: 'Mudar de fase',
                                  onPressed: () => _mudarFase(c),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Editar',
                                  onPressed: () => _abrirFormulario(catequisando: c),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Apagar',
                                  onPressed: () => _apagar(c),
                                ),
                              ],
                            )
                          : null,
                      onTap: () => _abrirDetalhe(c),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Novo catequisando',
        child: const Icon(Icons.add),
      ),
    );
  }
}
