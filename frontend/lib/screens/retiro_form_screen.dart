import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fase.dart';
import '../models/retiro.dart';
import '../models/sector.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/fase_service.dart';
import '../services/retiro_service.dart';
import '../services/sector_service.dart';

class RetiroFormScreen extends StatefulWidget {
  final Retiro? retiro;

  const RetiroFormScreen({super.key, this.retiro});

  @override
  State<RetiroFormScreen> createState() => _RetiroFormScreenState();
}

/// Linha editável da tabela "Programa do dia".
class _LinhaPrograma {
  final TextEditingController hora;
  final TextEditingController atividade;
  final TextEditingController responsavel;

  _LinhaPrograma({String hora = '', String atividade = '', String responsavel = ''})
      : hora = TextEditingController(text: hora),
        atividade = TextEditingController(text: atividade),
        responsavel = TextEditingController(text: responsavel);

  ProgramaItem toItem() => ProgramaItem(
        hora: hora.text.trim(),
        atividade: atividade.text.trim(),
        responsavel: responsavel.text.trim(),
      );

  void dispose() {
    hora.dispose();
    atividade.dispose();
    responsavel.dispose();
  }
}

class _RetiroFormScreenState extends State<RetiroFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _localController;
  late TextEditingController _temaController;
  late TextEditingController _oradorController;

  DateTime _data = DateTime.now();
  final Set<String> _faseIdsSelecionadas = {};
  final Set<String> _sectorIdsSelecionados = {};
  final List<String> _oradores = [];
  final List<_LinhaPrograma> _programa = [];

  List<Fase> _fasesDisponiveis = [];
  List<Sector> _sectoresDisponiveis = [];
  bool _carregandoFases = true;
  bool _carregandoSectores = true;
  bool _submitting = false;

  bool get _editando => widget.retiro != null;

  @override
  void initState() {
    super.initState();
    final r = widget.retiro;
    _tituloController = TextEditingController(text: r?.titulo ?? '');
    _localController = TextEditingController(text: r?.local ?? '');
    _temaController = TextEditingController(text: r?.tema ?? '');
    _oradorController = TextEditingController();

    if (r != null) {
      _data = r.data;
      _faseIdsSelecionadas.addAll(r.fases.map((f) => f.id));
      _sectorIdsSelecionados.addAll(r.sectores.map((s) => s.id));
      _oradores.addAll(r.oradores);
      for (final item in r.programa) {
        _programa.add(_LinhaPrograma(hora: item.hora, atividade: item.atividade, responsavel: item.responsavel));
      }
    }
    if (_programa.isEmpty) {
      _programa.add(_LinhaPrograma());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregarFases();
    _carregarSectores();
  }

  Future<void> _carregarFases() async {
    final token = context.read<AuthService>().token;
    try {
      final fases = await FaseService(token).listar();
      if (!mounted) return;
      setState(() => _fasesDisponiveis = fases);
    } catch (_) {
      // se falhar, o utilizador ainda consegue preencher o resto do formulário
    } finally {
      if (mounted) setState(() => _carregandoFases = false);
    }
  }

  Future<void> _carregarSectores() async {
    final token = context.read<AuthService>().token;
    try {
      final sectores = await SectorService(token).listar();
      if (!mounted) return;
      setState(() => _sectoresDisponiveis = sectores);
    } catch (_) {
      // se falhar, o utilizador ainda consegue preencher o resto do formulário
    } finally {
      if (mounted) setState(() => _carregandoSectores = false);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _localController.dispose();
    _temaController.dispose();
    _oradorController.dispose();
    for (final linha in _programa) {
      linha.dispose();
    }
    super.dispose();
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'Data do retiro',
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  void _adicionarOrador() {
    final texto = _oradorController.text.trim();
    if (texto.isEmpty) return;
    setState(() {
      _oradores.add(texto);
      _oradorController.clear();
    });
  }

  void _adicionarLinhaPrograma() {
    setState(() => _programa.add(_LinhaPrograma()));
  }

  void _removerLinhaPrograma(int index) {
    setState(() {
      _programa[index].dispose();
      _programa.removeAt(index);
    });
  }

  Future<void> _submeter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final token = context.read<AuthService>().token;
    final service = RetiroService(token);

    final programaValido = _programa
        .map((l) => l.toItem())
        .where((p) => p.hora.isNotEmpty || p.atividade.isNotEmpty || p.responsavel.isNotEmpty)
        .toList();

    try {
      if (_editando) {
        await service.atualizar(
          widget.retiro!.id,
          titulo: _tituloController.text.trim(),
          faseIds: _faseIdsSelecionadas.toList(),
          sectorIds: _sectorIdsSelecionados.toList(),
          data: _data,
          local: _localController.text.trim(),
          oradores: _oradores,
          tema: _temaController.text.trim(),
          programa: programaValido,
        );
      } else {
        await service.criar(
          titulo: _tituloController.text.trim(),
          faseIds: _faseIdsSelecionadas.toList(),
          sectorIds: _sectorIdsSelecionados.toList(),
          data: _data,
          local: _localController.text.trim(),
          oradores: _oradores,
          tema: _temaController.text.trim(),
          programa: programaValido,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : 'Erro ao guardar retiro';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar retiro' : 'Novo retiro')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ex: Retiro - 1ª Fase - 2026 I',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Título demasiado curto' : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _escolherData,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data do retiro',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        '${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _localController,
                    decoration: const InputDecoration(labelText: 'Local', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Local demasiado curto' : null,
                  ),
                  const SizedBox(height: 20),

                  // --- Fases contempladas ---
                  const Text('Fases contempladas (opcional)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _carregandoFases
                      ? const Center(child: CircularProgressIndicator())
                      : _fasesDisponiveis.isEmpty
                          ? const Text('Ainda não há fases criadas.')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _fasesDisponiveis.map((fase) {
                                final selecionada = _faseIdsSelecionadas.contains(fase.id);
                                return FilterChip(
                                  label: Text(fase.nome),
                                  selected: selecionada,
                                  onSelected: (v) {
                                    setState(() {
                                      if (v) {
                                        _faseIdsSelecionadas.add(fase.id);
                                      } else {
                                        _faseIdsSelecionadas.remove(fase.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                  const SizedBox(height: 20),

                  // --- Sectores participantes ---
                  const Text('Sectores participantes (opcional)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Padding(
                    padding: EdgeInsets.only(top: 2, bottom: 8),
                    child: Text(
                      'Para retiros dirigidos a catequisandos de um sector específico (ex: Acólitos).',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                  _carregandoSectores
                      ? const Center(child: CircularProgressIndicator())
                      : _sectoresDisponiveis.isEmpty
                          ? const Text('Ainda não há sectores criados.')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _sectoresDisponiveis.map((sector) {
                                final selecionado = _sectorIdsSelecionados.contains(sector.id);
                                return FilterChip(
                                  label: Text(sector.nome),
                                  selected: selecionado,
                                  onSelected: (v) {
                                    setState(() {
                                      if (v) {
                                        _sectorIdsSelecionados.add(sector.id);
                                      } else {
                                        _sectorIdsSelecionados.remove(sector.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                  const SizedBox(height: 20),

                  // --- Oradores ---
                  const Text('Oradores', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _oradorController,
                          decoration: const InputDecoration(
                            hintText: 'Nome do orador ou entidade',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onFieldSubmitted: (_) => _adicionarOrador(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _adicionarOrador,
                        icon: const Icon(Icons.add),
                        tooltip: 'Adicionar orador',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_oradores.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _oradores.asMap().entries.map((entry) {
                        return Chip(
                          label: Text(entry.value),
                          onDeleted: () => setState(() => _oradores.removeAt(entry.key)),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),

                  // --- Tema ---
                  TextFormField(
                    controller: _temaController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Tema', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),

                  // --- Programa do dia ---
                  Row(
                    children: [
                      const Text('Programa do dia', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _adicionarLinhaPrograma,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Linha'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._programa.asMap().entries.map((entry) {
                    final i = entry.key;
                    final linha = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              controller: linha.hora,
                              decoration: const InputDecoration(
                                labelText: 'Hora',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: linha.atividade,
                              decoration: const InputDecoration(
                                labelText: 'Actividade',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: linha.responsavel,
                              decoration: const InputDecoration(
                                labelText: 'Responsável',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Remover linha',
                            onPressed: _programa.length > 1 ? () => _removerLinhaPrograma(i) : null,
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submeter,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_editando ? 'Guardar alterações' : 'Criar retiro'),
                    ),
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
