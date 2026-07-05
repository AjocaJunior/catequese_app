import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/catequista.dart';
import '../models/fase.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/catequista_service.dart';
import '../services/fase_service.dart';

class FasesScreen extends StatefulWidget {
  const FasesScreen({super.key});

  @override
  State<FasesScreen> createState() => _FasesScreenState();
}

class _FasesScreenState extends State<FasesScreen> {
  late FaseService _service;
  late CatequistaService _catequistaService;
  bool _isAdmin = false;
  List<Fase> _fases = [];
  bool _loading = true;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = FaseService(auth.token);
    _catequistaService = CatequistaService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final fases = await _service.listar();
      if (!mounted) return;
      setState(() => _fases = fases);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar fases');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mostrarFormulario({Fase? fase}) async {
    final nomeController = TextEditingController(text: fase?.nome ?? '');
    final catecismoController = TextEditingController(text: fase?.nomeCatecismo ?? '');
    final localController = TextEditingController(text: fase?.local ?? '');
    final programaController = TextEditingController(text: fase?.programaPdfUrl ?? '');
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fase == null ? 'Nova fase' : 'Editar fase'),
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
                    labelText: 'Nome da fase',
                    hintText: 'Ex: 1º Ano, Crisma, Pré-Catequese...',
                  ),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Nome demasiado curto' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: catecismoController,
                  decoration: const InputDecoration(
                    labelText: 'Catecismo (opcional)',
                    hintText: 'Ex: Jesus Entre Nós',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: localController,
                  decoration: const InputDecoration(
                    labelText: 'Local (opcional)',
                    hintText: 'Ex: Sala 1',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: programaController,
                  decoration: const InputDecoration(
                    labelText: 'Link do programa em PDF (opcional)',
                    hintText: 'Link do Google Drive',
                  ),
                  keyboardType: TextInputType.url,
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
      if (fase == null) {
        await _service.criar(
          nomeController.text.trim(),
          nomeCatecismo: catecismoController.text.trim(),
          local: localController.text.trim(),
          programaPdfUrl: programaController.text.trim(),
        );
      } else {
        await _service.atualizar(
          fase.id,
          nome: nomeController.text.trim(),
          nomeCatecismo: catecismoController.text.trim(),
          local: localController.text.trim(),
          programaPdfUrl: programaController.text.trim(),
        );
      }
      _carregar();
    } catch (e) {
      _mostrarErro(e);
    }
  }

  Future<void> _apagar(Fase fase) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar fase'),
        content: Text('Tens a certeza que queres apagar "${fase.nome}"?'),
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
      await _service.apagar(fase.id);
      _carregar();
    } catch (e) {
      _mostrarErro(e);
    }
  }

  Future<void> _gerirCatequistasDaFase(Fase fase) async {
    List<Catequista> todos;
    try {
      todos = await _catequistaService.listar();
    } catch (e) {
      _mostrarErro(e);
      return;
    }
    if (!mounted) return;

    final selecionados = <String>{...fase.catequistas.map((c) => c.id)};

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Catequistas de "${fase.nome}"'),
          content: SizedBox(
            width: double.maxFinite,
            child: todos.isEmpty
                ? const Text('Ainda não há catequistas registados.')
                : ListView(
                    shrinkWrap: true,
                    children: todos.map((c) {
                      return CheckboxListTile(
                        title: Text(c.nome),
                        subtitle: Text(c.email),
                        value: selecionados.contains(c.id),
                        onChanged: (v) {
                          setStateDialog(() {
                            if (v == true) {
                              selecionados.add(c.id);
                            } else {
                              selecionados.remove(c.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (confirmar != true) return;

    try {
      await _service.definirCatequistas(fase.id, selecionados.toList());
      _carregar();
    } catch (e) {
      _mostrarErro(e);
    }
  }

  Future<void> _abrirPrograma(Fase fase) async {
    final url = fase.programaPdfUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _mostrarErro('Link do programa inválido');
      return;
    }
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link do programa')),
      );
    }
  }

  void _mostrarErro(Object e) {
    if (!mounted) return;
    final msg = e is ApiException ? e.message : e.toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fases catequéticas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: _fases.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 100),
                            Center(
                              child: Text(
                                _isAdmin
                                    ? 'Ainda não há fases.\nToca em + para criar a primeira.'
                                    : 'Ainda não há fases criadas.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _fases.length,
                          itemBuilder: (context, i) {
                            final fase = _fases[i];
                            final nomesCatequistas = fase.catequistas.map((c) => c.nome).join(', ');
                            final detalhes = [
                              if (fase.nomeCatecismo != null && fase.nomeCatecismo!.isNotEmpty)
                                'Catecismo: ${fase.nomeCatecismo}',
                              if (fase.local != null && fase.local!.isNotEmpty) 'Local: ${fase.local}',
                              nomesCatequistas.isEmpty ? 'Sem catequistas atribuídos' : nomesCatequistas,
                            ].join(' · ');
                            return ListTile(
                              leading: CircleAvatar(child: Text('${fase.ordem}')),
                              title: Text(fase.nome),
                              subtitle: Text(detalhes),
                              isThreeLine: detalhes.length > 40,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (fase.programaPdfUrl != null && fase.programaPdfUrl!.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.picture_as_pdf_outlined),
                                      tooltip: 'Abrir programa (PDF)',
                                      onPressed: () => _abrirPrograma(fase),
                                    ),
                                  if (_isAdmin) ...[
                                    IconButton(
                                      icon: const Icon(Icons.group_outlined),
                                      tooltip: 'Catequistas da fase',
                                      onPressed: () => _gerirCatequistasDaFase(fase),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Editar',
                                      onPressed: () => _mostrarFormulario(fase: fase),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Apagar',
                                      onPressed: () => _apagar(fase),
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
              tooltip: 'Nova fase',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
