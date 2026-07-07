import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inventario.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/inventario_service.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  late InventarioService _service;
  bool _isAdmin = false;
  List<ItemInventario> _itens = [];
  bool _loading = true;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = InventarioService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final itens = await _service.listar();
      if (!mounted) return;
      setState(() => _itens = itens);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar o inventário');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mostrarFormulario({ItemInventario? item}) async {
    final nomeController = TextEditingController(text: item?.nome ?? '');
    final quantidadeController = TextEditingController(text: item?.quantidade.toString() ?? '');
    final descricaoController = TextEditingController(text: item?.descricao ?? '');
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Novo item' : 'Editar item'),
        content: SizedBox(
          width: 400,
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
                TextFormField(
                  controller: descricaoController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descrição (opcional)', border: OutlineInputBorder()),
                ),
              ],
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
    );

    if (confirmar != true) return;

    try {
      if (item == null) {
        await _service.criar(
          nome: nomeController.text.trim(),
          quantidade: int.parse(quantidadeController.text),
          descricao: descricaoController.text.trim(),
        );
      } else {
        await _service.atualizar(
          item.id,
          nome: nomeController.text.trim(),
          quantidade: int.parse(quantidadeController.text),
          descricao: descricaoController.text.trim(),
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
      appBar: AppBar(title: const Text('Inventário da Catequese')),
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
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
                              title: Text(item.nome),
                              subtitle: Text(
                                item.descricao != null && item.descricao!.isNotEmpty
                                    ? item.descricao!
                                    : 'Sem descrição',
                              ),
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
                                  if (_isAdmin) ...[
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
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () => _mostrarFormulario(),
              tooltip: 'Novo item',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
