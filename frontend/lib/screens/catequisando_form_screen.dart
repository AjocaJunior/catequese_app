import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catequisando.dart';
import '../models/fase.dart';
import '../models/sector.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/catequisando_service.dart';
import '../services/sector_service.dart';

class CatequisandoFormScreen extends StatefulWidget {
  final List<Fase> fases;
  final Catequisando? catequisando;

  const CatequisandoFormScreen({super.key, required this.fases, this.catequisando});

  @override
  State<CatequisandoFormScreen> createState() => _CatequisandoFormScreenState();
}

class _CatequisandoFormScreenState extends State<CatequisandoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _encarregadoNomeController;
  late TextEditingController _encarregadoContactoController;
  late TextEditingController _encarregadoParentescoController;
  late TextEditingController _observacoesController;
  String? _faseId;
  String? _sectorId;
  List<Sector> _sectoresDisponiveis = [];
  bool _carregandoSectores = true;
  DateTime? _dataNascimento;
  bool _submitting = false;

  bool get _editando => widget.catequisando != null;

  @override
  void initState() {
    super.initState();
    final c = widget.catequisando;
    _nomeController = TextEditingController(text: c?.nome ?? '');
    _encarregadoNomeController = TextEditingController(text: c?.encarregadoNome ?? '');
    _encarregadoContactoController = TextEditingController(text: c?.encarregadoContacto ?? '');
    _encarregadoParentescoController = TextEditingController(text: c?.encarregadoParentesco ?? '');
    _observacoesController = TextEditingController(text: c?.observacoes ?? '');
    _faseId = c?.faseId ?? (widget.fases.isNotEmpty ? widget.fases.first.id : null);
    _sectorId = c?.sectorId;
    _dataNascimento = c?.dataNascimento;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregarSectores();
  }

  Future<void> _carregarSectores() async {
    final token = context.read<AuthService>().token;
    try {
      final sectores = await SectorService(token).listar();
      if (!mounted) return;
      setState(() => _sectoresDisponiveis = sectores);
    } catch (_) {
      // ecrã continua utilizável sem sector, se a lista falhar
    } finally {
      if (mounted) setState(() => _carregandoSectores = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _encarregadoNomeController.dispose();
    _encarregadoContactoController.dispose();
    _encarregadoParentescoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final agora = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(agora.year - 8),
      firstDate: DateTime(agora.year - 100),
      lastDate: agora,
      helpText: 'Data de nascimento',
    );
    if (escolhida != null) setState(() => _dataNascimento = escolhida);
  }

  Future<void> _submeter() async {
    if (!_formKey.currentState!.validate()) return;
    if (_faseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleciona uma fase')));
      return;
    }

    setState(() => _submitting = true);
    final token = context.read<AuthService>().token;
    final service = CatequisandoService(token);

    final dados = <String, dynamic>{
      'nome': _nomeController.text.trim(),
      'fase_id': _faseId,
      if (_sectorId != null) 'sector_id': _sectorId,
      if (_dataNascimento != null)
        'data_nascimento': _dataNascimento!.toIso8601String().split('T').first,
      if (_encarregadoNomeController.text.trim().isNotEmpty)
        'encarregado_nome': _encarregadoNomeController.text.trim(),
      if (_encarregadoContactoController.text.trim().isNotEmpty)
        'encarregado_contacto': _encarregadoContactoController.text.trim(),
      if (_encarregadoParentescoController.text.trim().isNotEmpty)
        'encarregado_parentesco': _encarregadoParentescoController.text.trim(),
      if (_observacoesController.text.trim().isNotEmpty)
        'observacoes': _observacoesController.text.trim(),
    };

    try {
      if (_editando) {
        await service.atualizar(widget.catequisando!.id, dados);
      } else {
        await service.criar(dados);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : 'Ocorreu um erro';
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
      appBar: AppBar(title: Text(_editando ? 'Editar catequisando' : 'Novo catequisando')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 560 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome completo', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Nome demasiado curto' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _faseId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Fase', border: OutlineInputBorder()),
                    items: widget.fases
                        .map((f) => DropdownMenuItem(
                              value: f.id,
                              child: Text(f.nome, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _faseId = v),
                    validator: (v) => v == null ? 'Seleciona uma fase' : null,
                  ),
                  const SizedBox(height: 16),
                  _carregandoSectores
                      ? const LinearProgressIndicator()
                      : DropdownButtonFormField<String?>(
                          value: _sectorId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Sector pastoral (opcional)',
                            hintText: 'Ex: Acólitos, se também participar',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Nenhum')),
                            ..._sectoresDisponiveis.map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.nome, overflow: TextOverflow.ellipsis),
                                )),
                          ],
                          onChanged: (v) => setState(() => _sectorId = v),
                        ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _escolherData,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data de nascimento (opcional)',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _dataNascimento == null
                            ? 'Não definida'
                            : '${_dataNascimento!.day.toString().padLeft(2, '0')}/'
                                '${_dataNascimento!.month.toString().padLeft(2, '0')}/'
                                '${_dataNascimento!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _encarregadoNomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do encarregado de educação (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _encarregadoContactoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contacto do encarregado (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _encarregadoParentescoController,
                    decoration: const InputDecoration(
                      labelText: 'Grau de parentesco (opcional)',
                      hintText: 'Ex: Mãe, Pai, Avó...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _observacoesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
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
                          : Text(_editando ? 'Guardar alterações' : 'Registar catequisando'),
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
