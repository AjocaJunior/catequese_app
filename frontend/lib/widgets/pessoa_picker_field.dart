import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pessoa.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/pessoa_service.dart';

/// Campo para escolher uma Pessoa (pai, mãe, padrinho ou madrinha) já
/// registada, pesquisando por nome — ou criar uma nova se ainda não existir.
/// Nunca duplica dados: se dois irmãos têm o mesmo pai, escolhe-se a mesma
/// Pessoa nos dois registos, e editar uma vez atualiza os dois.
class PessoaPickerField extends StatefulWidget {
  final String rotulo;
  final List<Pessoa> pessoasDisponiveis;
  final Pessoa? valorInicial;
  final bool incluirNaturalDe;
  final ValueChanged<Pessoa?> onChanged;

  const PessoaPickerField({
    super.key,
    required this.rotulo,
    required this.pessoasDisponiveis,
    required this.onChanged,
    this.valorInicial,
    this.incluirNaturalDe = true,
  });

  @override
  State<PessoaPickerField> createState() => _PessoaPickerFieldState();
}

class _PessoaPickerFieldState extends State<PessoaPickerField> {
  Pessoa? _selecionada;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selecionada = widget.valorInicial;
    _controller.text = widget.valorInicial?.nome ?? '';
  }

  Future<void> _criarNovaPessoa(String nomeSugerido) async {
    final nomeController = TextEditingController(text: nomeSugerido);
    final naturalDeController = TextEditingController();
    final provinciaController = TextEditingController();
    final estadoController = TextEditingController();
    final profissaoController = TextEditingController();
    final residenciaController = TextEditingController();
    final comunidadeController = TextEditingController();
    final contactoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova pessoa — ${widget.rotulo}'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomeController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Nome completo', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Nome demasiado curto' : null,
                  ),
                  if (widget.incluirNaturalDe) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: naturalDeController,
                      decoration: const InputDecoration(labelText: 'Natural de (opcional)', border: OutlineInputBorder()),
                    ),
                  ],
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
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!mounted) return;

    try {
      final token = context.read<AuthService>().token;
      final nova = await PessoaService(token).criar(
        nome: nomeController.text.trim(),
        naturalDe: naturalDeController.text.trim(),
        provincia: provinciaController.text.trim(),
        estadoCivil: estadoController.text.trim(),
        profissao: profissaoController.text.trim(),
        residencia: residenciaController.text.trim(),
        comunidade: comunidadeController.text.trim(),
        contacto: contactoController.text.trim(),
      );
      setState(() {
        _selecionada = nova;
        _controller.text = nova.nome;
        widget.pessoasDisponiveis.add(nova);
      });
      widget.onChanged(nova);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao criar pessoa';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<Pessoa>(
          displayStringForOption: (p) => p.nome,
          initialValue: TextEditingValue(text: _selecionada?.nome ?? ''),
          optionsBuilder: (v) {
            if (v.text.isEmpty) return const Iterable<Pessoa>.empty();
            return widget.pessoasDisponiveis.where((p) => p.nome.toLowerCase().contains(v.text.toLowerCase()));
          },
          onSelected: (p) {
            setState(() => _selecionada = p);
            widget.onChanged(p);
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: widget.rotulo,
              hintText: 'Pesquisar por nome...',
              border: const OutlineInputBorder(),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        controller.clear();
                        setState(() => _selecionada = null);
                        widget.onChanged(null);
                      },
                    )
                  : null,
            ),
            onChanged: (v) {
              if (_selecionada != null && v != _selecionada!.nome) {
                setState(() => _selecionada = null);
                widget.onChanged(null);
              }
            },
          ),
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220, maxWidth: 400),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: options
                      .map((p) => ListTile(
                            dense: true,
                            title: Text(p.nome),
                            subtitle: p.profissao != null ? Text(p.profissao!) : null,
                            onTap: () => onSelected(p),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
        if (_selecionada == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _criarNovaPessoa(_controller.text.trim()),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                label: const Text('Não encontrado? Criar nova pessoa'),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              [_selecionada!.profissao, _selecionada!.residencia].where((v) => v != null).join(' · '),
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
