import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ministerio.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/ministerio_service.dart';

class MinisteriosScreen extends StatefulWidget {
  const MinisteriosScreen({super.key});

  @override
  State<MinisteriosScreen> createState() => _MinisteriosScreenState();
}

class _MinisteriosScreenState extends State<MinisteriosScreen> {
  late MinisterioService _service;
  bool _isAdmin = false;
  List<Ministerio> _ministerios = [];
  bool _loading = true;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = MinisterioService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final ministerios = await _service.listar();
      if (!mounted) return;
      setState(() => _ministerios = ministerios);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar ministérios');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mostrarFormulario({Ministerio? ministerio}) async {
    final nomeController = TextEditingController(text: ministerio?.nome ?? '');
    final coordenadorController = TextEditingController(text: ministerio?.coordenadorNome ?? '');
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ministerio == null ? 'Novo ministério' : 'Editar ministério'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nome do ministério',
                    hintText: 'Ex: Ministério da Liturgia',
                  ),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Nome demasiado curto' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: coordenadorController,
                  decoration: const InputDecoration(
                    labelText: 'Coordenador(a) (opcional)',
                    hintText: 'Nome de quem coordena o ministério',
                  ),
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
      if (ministerio == null) {
        await _service.criar(
          nome: nomeController.text.trim(),
          coordenadorNome: coordenadorController.text.trim(),
        );
      } else {
        await _service.atualizar(
          ministerio.id,
          nome: nomeController.text.trim(),
          coordenadorNome: coordenadorController.text.trim(),
        );
      }
      _carregar();
    } catch (e) {
      _mostrarErro(e);
    }
  }

  Future<void> _apagar(Ministerio ministerio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar ministério'),
        content: Text('Tens a certeza que queres apagar "${ministerio.nome}"?'),
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
      await _service.apagar(ministerio.id);
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
      appBar: AppBar(title: const Text('Ministérios')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: _ministerios.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('Ainda não há ministérios.\nToca em + para criar o primeiro.', textAlign: TextAlign.center)),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _ministerios.length,
                          itemBuilder: (context, i) {
                            final m = _ministerios[i];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.account_tree_outlined)),
                              title: Text(m.nome),
                              subtitle: Text(m.coordenadorNome != null
                                  ? 'Coordenador(a): ${m.coordenadorNome}'
                                  : 'Sem coordenador(a) definido'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Editar',
                                    onPressed: () => _mostrarFormulario(ministerio: m),
                                  ),
                                  if (_isAdmin)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Apagar',
                                      onPressed: () => _apagar(m),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        tooltip: 'Novo ministério',
        child: const Icon(Icons.add),
      ),
    );
  }
}
