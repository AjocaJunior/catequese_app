import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/catequista.dart';
import '../models/inventario.dart';
import '../models/sector.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/inventario_service.dart';
import '../services/sector_service.dart';
import 'importar_inventario_screen.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  late InventarioService _service;
  late SectorService _sectorService;
  bool _isAdmin = false;
  List<SectorResumoCatequista> _meusSectores = [];
  List<Sector> _sectores = [];
  List<ItemInventario> _itens = [];
  bool _loading = true;
  String? _erro;

  bool get _podeCriar => _isAdmin || _meusSectores.isNotEmpty;

  bool _podeGerir(ItemInventario item) {
    if (_isAdmin) return true;
    if (item.sectorId == null) return false;
    return _meusSectores.any((s) => s.id == item.sectorId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = InventarioService(auth.token);
    _sectorService = SectorService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _meusSectores = auth.catequista?.sectoresResponsavel ?? [];
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final itens = await _service.listar();
      final sectores = await _sectorService.listar();
      if (!mounted) return;
      setState(() {
        _itens = itens;
        _sectores = sectores;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar o inventário');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Sector> get _sectoresDisponiveisParaMim {
    if (_isAdmin) return _sectores;
    return _sectores.where((s) => _meusSectores.any((m) => m.id == s.id)).toList();
  }

  Future<void> _abrirImagem(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _mostrarFormulario({ItemInventario? item}) async {
    final nomeController = TextEditingController(text: item?.nome ?? '');
    final categoriaController = TextEditingController(text: item?.categoria ?? '');
    final quantidadeController = TextEditingController(text: item?.quantidade.toString() ?? '');
    final descricaoController = TextEditingController(text: item?.descricao ?? '');
    final localizacaoController = TextEditingController(text: item?.localizacao ?? '');
    final imagemController = TextEditingController(text: item?.imagemUrl ?? '');
    EstadoItem? estado = item?.estado;

    final opcoesSector = _sectoresDisponiveisParaMim;
    String? sectorId = item?.sectorId ?? (_isAdmin ? null : (opcoesSector.isNotEmpty ? opcoesSector.first.id : null));

    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(item == null ? 'Novo item' : 'Editar item'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nomeController,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Nome do item', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Nome demasiado curto' : null,
                    ),
                    const SizedBox(height: 12),
                    if (_isAdmin)
                      DropdownButtonFormField<String?>(
                        value: sectorId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Sector',
                          helperText: 'Sem sector = inventário geral da catequese',
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Geral (catequese)')),
                          ...opcoesSector.map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.nome, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) => setStateDialog(() => sectorId = v),
                      )
                    else if (opcoesSector.length > 1)
                      DropdownButtonFormField<String?>(
                        value: sectorId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Sector'),
                        items: opcoesSector
                            .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nome)))
                            .toList(),
                        onChanged: (v) => setStateDialog(() => sectorId = v),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Sector: ${opcoesSector.isNotEmpty ? opcoesSector.first.nome : "—"}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: categoriaController,
                      decoration: const InputDecoration(
                        labelText: 'Categoria (opcional)',
                        hintText: 'Ex: Mobiliário, Material litúrgico...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: quantidadeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantidade', border: OutlineInputBorder()),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n < 0) ? 'Indica uma quantidade válida' : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<EstadoItem?>(
                      value: estado,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Estado (opcional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Não definido')),
                        ...EstadoItem.values.map((e) => DropdownMenuItem(value: e, child: Text(e.rotulo))),
                      ],
                      onChanged: (v) => setStateDialog(() => estado = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: localizacaoController,
                      decoration: const InputDecoration(
                        labelText: 'Localização (opcional)',
                        hintText: 'Ex: Armazém, Sacristia...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: imagemController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Link da imagem (opcional)',
                        hintText: 'Link do Google Drive',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descricaoController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Descrição (opcional)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) return;

    try {
      if (item == null) {
        await _service.criar(
          nome: nomeController.text.trim(),
          sectorId: sectorId,
          categoria: categoriaController.text.trim(),
          quantidade: int.parse(quantidadeController.text),
          descricao: descricaoController.text.trim(),
          localizacao: localizacaoController.text.trim(),
          imagemUrl: imagemController.text.trim(),
          estado: estado,
        );
      } else {
        await _service.atualizar(
          item.id,
          nome: nomeController.text.trim(),
          sectorId: sectorId,
          categoria: categoriaController.text.trim(),
          quantidade: int.parse(quantidadeController.text),
          descricao: descricaoController.text.trim(),
          localizacao: localizacaoController.text.trim(),
          imagemUrl: imagemController.text.trim(),
          estado: estado,
        );
      }
      _carregar();
    } catch (e) {
      _mostrarErro(e);
    }
  }

  Future<void> _apagar(ItemInventario item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar item'),
        content: Text('Tens a certeza que queres apagar "${item.nome}"?'),
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
      await _service.apagar(item.id);
      _carregar();
    } catch (e) {
      _mostrarErro(e);
    }
  }

  void _mostrarErro(Object e) {
    if (!mounted) return;
    final msg = e is ApiException ? e.message : 'Ocorreu um erro';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventário'),
        actions: [
          if (_podeCriar)
            IconButton(
              icon: const Icon(Icons.upload_file_outlined),
              tooltip: 'Importar de ficheiro Excel',
              onPressed: () async {
                final resultado = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const ImportarInventarioScreen()),
                );
                if (resultado == true) _carregar();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: _itens.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(
                                child: Text('Ainda não há itens no inventário.\nToca em + para adicionar o primeiro.',
                                    textAlign: TextAlign.center)),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _itens.length,
                          itemBuilder: (context, i) {
                            final item = _itens[i];
                            final podeGerir = _podeGerir(item);
                            final detalhes = [
                              if (item.sectorNome != null) item.sectorNome! else 'Geral',
                              if (item.categoria != null) item.categoria!,
                              if (item.localizacao != null) item.localizacao!,
                              if (item.estado != null) item.estado!.rotulo,
                            ].join(' · ');
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
                              title: Text(item.nome),
                              subtitle: Text(detalhes),
                              isThreeLine: detalhes.length > 40,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('${item.quantidade}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  if (item.imagemUrl != null && item.imagemUrl!.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.image_outlined),
                                      tooltip: 'Ver imagem',
                                      onPressed: () => _abrirImagem(item.imagemUrl!),
                                    ),
                                  if (podeGerir) ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Editar',
                                      onPressed: () => _mostrarFormulario(item: item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Apagar',
                                      onPressed: () => _apagar(item),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: _podeCriar
          ? FloatingActionButton(
              onPressed: () => _mostrarFormulario(),
              tooltip: 'Novo item',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
