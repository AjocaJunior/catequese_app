import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ministerio.dart';
import '../models/sector.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/ministerio_service.dart';
import '../services/sector_service.dart';

class SectoresScreen extends StatefulWidget {
  const SectoresScreen({super.key});

  @override
  State<SectoresScreen> createState() => _SectoresScreenState();
}

class _SectoresScreenState extends State<SectoresScreen> {
  late SectorService _service;
  late MinisterioService _ministerioService;
  bool _isAdmin = false;
  List<Sector> _sectores = [];
  bool _loading = true;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = SectorService(auth.token);
    _ministerioService = MinisterioService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final sectores = await _service.listar();
      if (!mounted) return;
      setState(() => _sectores = sectores);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar sectores');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mostrarFormulario({Sector? sector}) async {
    List<Ministerio> ministerios;
    try {
      ministerios = await _ministerioService.listar();
    } catch (e) {
      _mostrarErro(e);
      return;
    }
    if (!mounted) return;

    final nomeController = TextEditingController(text: sector?.nome ?? '');
    final horaController = TextEditingController(text: sector?.hora ?? '');
    final localController = TextEditingController(text: sector?.local ?? '');
    final responsavelController = TextEditingController(text: sector?.responsavelNome ?? '');
    DiaSemana? diaSemana = sector?.diaSemana;
    String? ministerioId = sector?.ministerioId;
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(sector == null ? 'Novo sector' : 'Editar sector'),
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
                      decoration: const InputDecoration(
                        labelText: 'Nome do sector',
                        hintText: 'Ex: Acolhimento, Acólitos',
                      ),
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Nome demasiado curto' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DiaSemana?>(
                      value: diaSemana,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Dia da semana do encontro (opcional)',
                        helperText: 'Deixa em branco para sectores sem encontro regular (ex: Finanças)',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sem encontro regular')),
                        ...DiaSemana.values.map((d) => DropdownMenuItem(value: d, child: Text(d.rotulo))),
                      ],
                      onChanged: (v) => setStateDialog(() => diaSemana = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: horaController,
                      decoration: const InputDecoration(labelText: 'Hora (opcional)', hintText: 'Ex: 18:00'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: localController,
                      decoration: const InputDecoration(labelText: 'Local (opcional)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: ministerioId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Ministério (opcional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sem ministério')),
                        ...ministerios.map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.nome, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) => setStateDialog(() => ministerioId = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: responsavelController,
                      decoration: const InputDecoration(
                        labelText: 'Responsável pelo sector (opcional)',
                        hintText: 'Nome de quem coordena este sector',
                      ),
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
      if (sector == null) {
        await _service.criar(
          nome: nomeController.text.trim(),
          diaSemana: diaSemana,
          hora: horaController.text.trim().isEmpty ? null : horaController.text.trim(),
          local: localController.text.trim(),
          ministerioId: ministerioId,
          responsavelNome: responsavelController.text.trim(),
        );
      } else {
        await _service.atualizar(
          sector.id,
          nome: nomeController.text.trim(),
          diaSemana: diaSemana,
          hora: horaController.text.trim().isEmpty ? null : horaController.text.trim(),
          local: localController.text.trim(),
          ministerioId: ministerioId,
          responsavelNome: responsavelController.text.trim(),
        );
      }
      _carregar();
    } catch (e) {
      _mostrarErro(e);
    }
  }

  Future<void> _apagar(Sector sector) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar sector'),
        content: Text('Tens a certeza que queres apagar "${sector.nome}"?'),
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
      await _service.apagar(sector.id);
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
      appBar: AppBar(title: const Text('Sectores da Comunidade')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: _sectores.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('Ainda não há sectores.\nToca em + para criar o primeiro.', textAlign: TextAlign.center)),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _sectores.length,
                          itemBuilder: (context, i) {
                            final s = _sectores[i];
                            final detalhes = [
                              if (s.diaSemana != null) '${s.diaSemana!.rotulo}, ${s.hora ?? "hora por definir"}'
                              else 'Sem encontro regular',
                              if (s.local != null) s.local!,
                              if (s.ministerioNome != null) 'Ministério: ${s.ministerioNome}',
                              if (s.responsavelNome != null) 'Responsável: ${s.responsavelNome}',
                            ].join(' · ');
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.groups_2_outlined)),
                              title: Text(s.nome),
                              subtitle: Text(detalhes),
                              isThreeLine: detalhes.length > 45,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Editar',
                                    onPressed: () => _mostrarFormulario(sector: s),
                                  ),
                                  if (_isAdmin)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Apagar',
                                      onPressed: () => _apagar(s),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        tooltip: 'Novo sector',
        child: const Icon(Icons.add),
      ),
    );
  }
}
