import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pessoa.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/pessoa_service.dart';
import '../utils/whatsapp_helper.dart';

class PessoasScreen extends StatefulWidget {
  const PessoasScreen({super.key});

  @override
  State<PessoasScreen> createState() => _PessoasScreenState();
}

class _PessoasScreenState extends State<PessoasScreen> {
  late PessoaService _service;
  bool _isAdmin = false;

  List<Pessoa> _pessoas = [];
  bool _loading = true;
  String? _erro;
  final _pesquisaController = TextEditingController();
  String _termoPesquisa = '';

  List<Pessoa> get _pessoasFiltradas {
    if (_termoPesquisa.isEmpty) return _pessoas;
    final termo = _termoPesquisa.toLowerCase();
    return _pessoas.where((p) => p.nome.toLowerCase().contains(termo)).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = PessoaService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _carregar();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final pessoas = await _service.listar();
      if (!mounted) return;
      setState(() => _pessoas = pessoas);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar pessoas');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mostrarFormulario({Pessoa? pessoa}) async {
    final editando = pessoa != null;
    final nomeController = TextEditingController(text: pessoa?.nome ?? '');
    final naturalDeController = TextEditingController(text: pessoa?.naturalDe ?? '');
    final provinciaController = TextEditingController(text: pessoa?.provincia ?? '');
    final estadoController = TextEditingController(text: pessoa?.estadoCivil ?? '');
    final profissaoController = TextEditingController(text: pessoa?.profissao ?? '');
    final residenciaController = TextEditingController(text: pessoa?.residencia ?? '');
    final comunidadeController = TextEditingController(text: pessoa?.comunidade ?? '');
    final contactoController = TextEditingController(text: pessoa?.contacto ?? '');
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editando ? 'Editar pessoa' : 'Nova pessoa'),
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
                    autofocus: !editando,
                    decoration: const InputDecoration(labelText: 'Nome completo', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Nome demasiado curto' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: naturalDeController,
                    decoration: const InputDecoration(labelText: 'Natural de (opcional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: provinciaController,
                    decoration: const InputDecoration(labelText: 'Província (opcional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: estadoController,
                    decoration: const InputDecoration(labelText: 'Estado civil (opcional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: profissaoController,
                    decoration: const InputDecoration(labelText: 'Profissão (opcional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: residenciaController,
                    decoration: const InputDecoration(labelText: 'Residência (opcional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: comunidadeController,
                    decoration: const InputDecoration(
                      labelText: 'Comunidade/paróquia (opcional)',
                      hintText: 'Se pertencer a outra comunidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contactoController,
                    decoration: const InputDecoration(labelText: 'Contacto (opcional)', border: OutlineInputBorder()),
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
            child: Text(editando ? 'Guardar' : 'Criar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      if (editando) {
        await _service.atualizar(
          pessoa.id,
          nome: nomeController.text.trim(),
          naturalDe: naturalDeController.text.trim(),
          provincia: provinciaController.text.trim(),
          estadoCivil: estadoController.text.trim(),
          profissao: profissaoController.text.trim(),
          residencia: residenciaController.text.trim(),
          comunidade: comunidadeController.text.trim(),
          contacto: contactoController.text.trim(),
        );
      } else {
        await _service.criar(
          nome: nomeController.text.trim(),
          naturalDe: naturalDeController.text.trim(),
          provincia: provinciaController.text.trim(),
          estadoCivil: estadoController.text.trim(),
          profissao: profissaoController.text.trim(),
          residencia: residenciaController.text.trim(),
          comunidade: comunidadeController.text.trim(),
          contacto: contactoController.text.trim(),
        );
      }
      _carregar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao guardar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _verVinculos(Pessoa pessoa) async {
    List<VinculoPessoa>? vinculos;
    String? erro;
    try {
      vinculos = await _service.vinculos(pessoa.id);
    } catch (e) {
      erro = e is ApiException ? e.message : 'Erro ao carregar vínculos';
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vínculos de ${pessoa.nome}'),
        content: SizedBox(
          width: 380,
          child: erro != null
              ? Text(erro)
              : (vinculos == null || vinculos.isEmpty)
                  ? const Text('Ainda não está associada a nenhum catequisando.')
                  : SizedBox(
                      height: 300,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: vinculos.length,
                        itemBuilder: (context, i) {
                          final v = vinculos![i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.person_outline),
                            title: Text(v.catequisandoNome),
                            subtitle: Text(v.papelRotulo),
                          );
                        },
                      ),
                    ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Future<void> _apagar(Pessoa pessoa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar pessoa'),
        content: Text('Tens a certeza que queres apagar "${pessoa.nome}"?'),
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
      await _service.apagar(pessoa.id);
      _carregar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao apagar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Pessoas')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 700 : double.infinity),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pais, mães, padrinhos e madrinhas registados — cada um pode ser associado a '
                      'vários catequisandos (irmãos, afilhados) sem duplicar dados.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _pesquisaController,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar por nome...',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _termoPesquisa.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _pesquisaController.clear();
                                  setState(() => _termoPesquisa = '');
                                },
                              ),
                      ),
                      onChanged: (v) => setState(() => _termoPesquisa = v),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_erro != null)
                Expanded(child: Center(child: Text(_erro!)))
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _carregar,
                    child: _pessoasFiltradas.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 100),
                              Center(
                                child: Text(
                                  _pessoas.isEmpty
                                      ? 'Ainda não há pessoas registadas.\nToca em + para adicionar a primeira.'
                                      : 'Nenhuma pessoa corresponde à pesquisa.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _pessoasFiltradas.length,
                            itemBuilder: (context, i) {
                              final p = _pessoasFiltradas[i];
                              final detalhes = [p.profissao, p.residencia].where((v) => v != null).join(' · ');
                              return ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                                title: Text(p.nome),
                                subtitle: detalhes.isNotEmpty ? Text(detalhes) : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    BotaoWhatsApp(telefone: p.contacto),
                                    IconButton(
                                      icon: const Icon(Icons.link, size: 20),
                                      tooltip: 'Ver vínculos (filhos/afilhados)',
                                      onPressed: () => _verVinculos(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Editar',
                                      onPressed: () => _mostrarFormulario(pessoa: p),
                                    ),
                                    if (_isAdmin)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: 'Apagar',
                                        onPressed: () => _apagar(p),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
