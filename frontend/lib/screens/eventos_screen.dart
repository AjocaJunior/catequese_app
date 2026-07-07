import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/evento.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/evento_service.dart';

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  late EventoService _service;
  bool _isAdmin = false;
  List<Evento> _eventos = [];
  bool _loading = true;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = EventoService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final eventos = await _service.listar();
      if (!mounted) return;
      setState(() => _eventos = eventos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar eventos');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mostrarFormulario({Evento? evento}) async {
    final tituloController = TextEditingController(text: evento?.titulo ?? '');
    final localController = TextEditingController(text: evento?.local ?? '');
    final descricaoController = TextEditingController(text: evento?.descricao ?? '');
    DateTime data = evento?.data ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(evento == null ? 'Novo evento' : 'Editar evento'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: tituloController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ex: Festa da Padroeira, Baptismo Comunitário',
                    ),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Título demasiado curto' : null,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final escolhida = await showDatePicker(
                        context: context,
                        initialDate: data,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (escolhida != null) setStateDialog(() => data = escolhida);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                      ),
                      child: Text('${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: localController,
                    decoration: const InputDecoration(labelText: 'Local (opcional)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descricaoController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
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
      ),
    );

    if (confirmar != true) return;

    try {
      if (evento == null) {
        await _service.criar(
          titulo: tituloController.text.trim(),
          data: data,
          local: localController.text.trim(),
          descricao: descricaoController.text.trim(),
        );
      } else {
        await _service.atualizar(
          evento.id,
          titulo: tituloController.text.trim(),
          data: data,
          local: localController.text.trim(),
          descricao: descricaoController.text.trim(),
        );
      }
      _carregar();
    } catch (e) {
      _mostrarErro(e);
    }
  }

  Future<void> _apagar(Evento evento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar evento'),
        content: Text('Tens a certeza que queres apagar "${evento.titulo}"?'),
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
      await _service.apagar(evento.id);
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

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos da Comunidade')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: _eventos.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('Ainda não há eventos.\nToca em + para criar o primeiro.', textAlign: TextAlign.center)),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _eventos.length,
                          itemBuilder: (context, i) {
                            final ev = _eventos[i];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.event_outlined)),
                              title: Text(ev.titulo),
                              subtitle: Text(
                                '${_formatarData(ev.data)}${ev.local != null ? ' · ${ev.local}' : ''}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Editar',
                                    onPressed: () => _mostrarFormulario(evento: ev),
                                  ),
                                  if (_isAdmin)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Apagar',
                                      onPressed: () => _apagar(ev),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        tooltip: 'Novo evento',
        child: const Icon(Icons.add),
      ),
    );
  }
}
