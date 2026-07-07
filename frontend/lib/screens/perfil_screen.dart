import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'alterar_senha_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _contactoController;
  bool _editando = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final c = context.read<AuthService>().catequista;
    _nomeController = TextEditingController(text: c?.nome ?? '');
    _contactoController = TextEditingController(text: c?.contacto ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _contactoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final auth = context.read<AuthService>();
    final erro = await auth.atualizarPerfil(
      nome: _nomeController.text.trim(),
      contacto: _contactoController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (erro == null) _editando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(erro ?? 'Perfil atualizado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final c = auth.catequista;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('O meu perfil'),
        actions: [
          if (!_editando)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => setState(() => _editando = true),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 460 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      child: Text(
                        (c?.nome.isNotEmpty ?? false) ? c!.nome[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (c?.isAdmin ?? false)
                    const Center(
                      child: Chip(
                        label: Text('Administrador'),
                        avatar: Icon(Icons.shield_outlined, size: 18),
                      ),
                    ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nomeController,
                    enabled: _editando,
                    decoration: const InputDecoration(labelText: 'Nome completo', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Nome demasiado curto' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: c?.email ?? '',
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      helperText: 'O email não pode ser alterado aqui',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactoController,
                    enabled: _editando,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contacto (telefone)',
                      hintText: 'Ex: 841234567',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_editando)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () {
                                    setState(() {
                                      _editando = false;
                                      _nomeController.text = c?.nome ?? '';
                                      _contactoController.text = c?.contacto ?? '';
                                    });
                                  },
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submitting ? null : _guardar,
                            child: _submitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AlterarSenhaScreen()),
                      );
                    },
                    icon: const Icon(Icons.password_outlined),
                    label: const Text('Alterar palavra-passe'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
