import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/catequisando.dart';
import '../models/fase.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/catequisando_service.dart';
import '../services/fase_service.dart';
import 'catequisando_detalhe_screen.dart';
import 'catequisando_form_screen.dart';
import 'importar_catequisandos_screen.dart';

class CatequisandosScreen extends StatefulWidget {
  const CatequisandosScreen({super.key});

  @override
  State<CatequisandosScreen> createState() => _CatequisandosScreenState();
}

class _CatequisandosScreenState extends State<CatequisandosScreen> {
  late CatequisandoService _catequisandoService;
  late FaseService _faseService;
  List<Catequisando> _catequisandos = [];
  List<Fase> _fases = [];
  String? _fasesFiltroId;
  SituacaoCatequisando? _situacaoFiltro = SituacaoCatequisando.ativo;
  final _pesquisaController = TextEditingController();
  String _termoPesquisa = '';
  bool _loading = true;
  String? _erro;
  bool _imprimindo = false;

  List<Catequisando> get _catequisandosFiltrados {
    if (_termoPesquisa.trim().isEmpty) return _catequisandos;
    final termo = _termoPesquisa.trim().toLowerCase();
    return _catequisandos.where((c) => c.nome.toLowerCase().contains(termo)).toList();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.read<AuthService>().token;
    _catequisandoService = CatequisandoService(token);
    _faseService = FaseService(token);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final fases = await _faseService.listar();
      final catequisandos = await _catequisandoService.listar(faseId: _fasesFiltroId, situacao: _situacaoFiltro);
      if (!mounted) return;
      setState(() {
        _fases = fases;
        _catequisandos = catequisandos;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar catequisandos');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _imprimirLista() async {
    if (_fasesFiltroId == null) return;
    setState(() => _imprimindo = true);
    try {
      final bytes = await _catequisandoService.baixarListaPdf(_fasesFiltroId!);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao gerar PDF da lista';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  Future<void> _abrirImportacao() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ImportarCatequisandosScreen()),
    );
    if (resultado == true) _carregar();
  }

  Future<void> _abrirDetalhe(Catequisando c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CatequisandoDetalheScreen(catequisando: c)),
    );
    // Recarrega sempre ao voltar (pode ter havido edição dentro do ecrã de detalhe)
    _carregar();
  }

  Future<void> _mudarFase(Catequisando c) async {
    String? novaFaseId = c.faseId;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Mudar de fase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Catequisando: ${c.nome}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: novaFaseId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Nova fase', border: OutlineInputBorder()),
                items: _fases
                    .map((f) => DropdownMenuItem(
                          value: f.id,
                          child: Text(f.nome, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setStateDialog(() => novaFaseId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
          ],
        ),
      ),
    );

    if (confirmar != true || novaFaseId == null || novaFaseId == c.faseId) return;

    try {
      await _catequisandoService.atualizar(c.id, {'fase_id': novaFaseId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fase atualizada')));
      _carregar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao mudar de fase';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _alternarCrismado(Catequisando c) async {
    final vaiCrismar = c.situacao == SituacaoCatequisando.ativo;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vaiCrismar ? 'Marcar como Crismado' : 'Reativar catequisando'),
        content: Text(
          vaiCrismar
              ? '${c.nome} deixa de aparecer nas presenças e pautas ativas de "${c.faseNome}". '
                  'O histórico mantém-se, e podes reverter isto a qualquer momento.'
              : '${c.nome} volta a aparecer como Ativo em "${c.faseNome}".',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      if (vaiCrismar) {
        await _catequisandoService.crismar(c.id);
      } else {
        await _catequisandoService.reativar(c.id);
      }
      _carregar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Ocorreu um erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _mostrarFormularioTransferencia(Catequisando c) async {
    final numeroController = TextEditingController(text: c.transferenciaNumero ?? '');
    final anoGuiaController = TextEditingController(
      text: (c.transferenciaAnoGuia ?? DateTime.now().year).toString(),
    );
    final anoFrequentadoController = TextEditingController(
      text: (c.transferenciaAnoFrequentado ?? DateTime.now().year).toString(),
    );
    final destinoComunidadeController = TextEditingController(text: c.transferenciaDestinoComunidade ?? '');
    final destinoArquidioceseController = TextEditingController(text: c.transferenciaDestinoArquidiocese ?? 'Maputo');
    final observacaoController = TextEditingController(text: c.transferenciaObservacao ?? '');
    DateTime dataImpressao = c.transferenciaData ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Transferir ${c.nome}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Gera a Guia de Transferência e marca o catequisando como Transferido '
                      '(deixa de aparecer nas presenças e pautas ativas).',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: numeroController,
                            decoration: const InputDecoration(labelText: 'Nº da guia', border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: anoGuiaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Ano da guia', border: OutlineInputBorder()),
                            validator: (v) => (int.tryParse(v ?? '') == null) ? 'Ano inválido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: anoFrequentadoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ano em que frequentou nesta paróquia',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (int.tryParse(v ?? '') == null) ? 'Ano inválido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: destinoComunidadeController,
                      decoration: const InputDecoration(
                        labelText: 'Paróquia/Comunidade de destino',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: destinoArquidioceseController,
                      decoration: const InputDecoration(labelText: 'Arquidiocese de destino', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final escolhida = await showDatePicker(
                          context: context,
                          initialDate: dataImpressao,
                          firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (escolhida != null) setStateDialog(() => dataImpressao = escolhida);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data de impressão',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                        ),
                        child: Text(
                          '${dataImpressao.day.toString().padLeft(2, '0')}/${dataImpressao.month.toString().padLeft(2, '0')}/${dataImpressao.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: observacaoController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'NB (observação, opcional)', border: OutlineInputBorder()),
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
              child: const Text('Transferir'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) return;

    try {
      await _catequisandoService.transferir(
        c.id,
        numero: numeroController.text.trim(),
        anoGuia: int.parse(anoGuiaController.text.trim()),
        anoFrequentado: int.parse(anoFrequentadoController.text.trim()),
        destinoComunidade: destinoComunidadeController.text.trim(),
        destinoArquidiocese: destinoArquidioceseController.text.trim(),
        observacao: observacaoController.text.trim(),
        dataImpressao: dataImpressao,
      );
      if (!mounted) return;
      _carregar();

      final imprimir = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Transferência registada'),
          content: const Text('Queres imprimir a Guia de Transferência agora?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Mais tarde')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Imprimir')),
          ],
        ),
      );
      if (imprimir == true) await _imprimirGuiaTransferencia(c);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao transferir';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _imprimirGuiaTransferencia(Catequisando c) async {
    try {
      final bytes = await _catequisandoService.baixarGuiaTransferenciaPdf(c.id);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao gerar a guia';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _abrirFormulario({Catequisando? catequisando}) async {
    if (_fases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cria pelo menos uma fase antes de registar catequisandos')),
      );
      return;
    }
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CatequisandoFormScreen(fases: _fases, catequisando: catequisando),
      ),
    );
    if (resultado == true) _carregar();
  }

  Future<void> _apagar(Catequisando c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar catequisando'),
        content: Text('Tens a certeza que queres apagar "${c.nome}"?'),
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
      await _catequisandoService.apagar(c.id);
      _carregar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Ocorreu um erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().catequista?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catequisandos'),
        actions: [
          if (_fasesFiltroId != null)
            IconButton(
              icon: _imprimindo
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.print_outlined),
              tooltip: 'Imprimir lista desta fase',
              onPressed: _imprimindo ? null : _imprimirLista,
            ),
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Importar de ficheiro',
            onPressed: _abrirImportacao,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButtonFormField<String?>(
              value: _fasesFiltroId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Filtrar por fase',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas as fases')),
                ..._fases.map((f) => DropdownMenuItem(
                      value: f.id,
                      child: Text(f.nome, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (value) {
                setState(() => _fasesFiltroId = value);
                _carregar();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Ativos'),
                  selected: _situacaoFiltro == SituacaoCatequisando.ativo,
                  onSelected: (_) {
                    setState(() => _situacaoFiltro = SituacaoCatequisando.ativo);
                    _carregar();
                  },
                ),
                ChoiceChip(
                  label: const Text('Crismados'),
                  selected: _situacaoFiltro == SituacaoCatequisando.crismado,
                  onSelected: (_) {
                    setState(() => _situacaoFiltro = SituacaoCatequisando.crismado);
                    _carregar();
                  },
                ),
                ChoiceChip(
                  label: const Text('Transferidos'),
                  selected: _situacaoFiltro == SituacaoCatequisando.transferido,
                  onSelected: (_) {
                    setState(() => _situacaoFiltro = SituacaoCatequisando.transferido);
                    _carregar();
                  },
                ),
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _situacaoFiltro == null,
                  onSelected: (_) {
                    setState(() => _situacaoFiltro = null);
                    _carregar();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: _pesquisaController,
              decoration: InputDecoration(
                labelText: 'Pesquisar por nome',
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
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_erro != null)
            Expanded(child: Center(child: Text(_erro!)))
          else if (_catequisandosFiltrados.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  _catequisandos.isEmpty
                      ? 'Nenhum catequisando encontrado.'
                      : 'Nenhum catequisando corresponde a "$_termoPesquisa".',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _carregar,
                child: ListView.builder(
                  itemCount: _catequisandosFiltrados.length,
                  itemBuilder: (context, i) {
                    final c = _catequisandosFiltrados[i];
                    final eCrismado = c.situacao == SituacaoCatequisando.crismado;
                    final eTransferido = c.situacao == SituacaoCatequisando.transferido;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: eCrismado
                            ? Colors.amber.withValues(alpha: 0.2)
                            : eTransferido
                                ? Colors.blueGrey.withValues(alpha: 0.2)
                                : null,
                        child: Icon(eCrismado
                            ? Icons.workspace_premium_outlined
                            : eTransferido
                                ? Icons.moving_outlined
                                : Icons.person_outline),
                      ),
                      title: Text(c.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        eCrismado
                            ? '${c.faseNome} · Crismado'
                            : eTransferido
                                ? '${c.faseNome} · Transferido para ${c.transferenciaDestinoComunidade ?? "—"}'
                                : c.faseNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isAdmin
                          ? PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (valor) {
                                switch (valor) {
                                  case 'crismar':
                                  case 'reativar':
                                    _alternarCrismado(c);
                                    break;
                                  case 'transferir':
                                    _mostrarFormularioTransferencia(c);
                                    break;
                                  case 'guia':
                                    _imprimirGuiaTransferencia(c);
                                    break;
                                  case 'fase':
                                    _mudarFase(c);
                                    break;
                                  case 'editar':
                                    _abrirFormulario(catequisando: c);
                                    break;
                                  case 'apagar':
                                    _apagar(c);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: eCrismado ? 'reativar' : 'crismar',
                                  child: ListTile(
                                    leading: Icon(eCrismado ? Icons.undo : Icons.workspace_premium_outlined),
                                    title: Text(eCrismado ? 'Reativar' : 'Marcar como Crismado'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: eTransferido ? 'guia' : 'transferir',
                                  child: ListTile(
                                    leading: Icon(eTransferido ? Icons.print_outlined : Icons.moving_outlined),
                                    title: Text(eTransferido ? 'Imprimir Guia de Transferência' : 'Transferir'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'fase',
                                  child: ListTile(
                                    leading: Icon(Icons.swap_horiz),
                                    title: Text('Mudar de fase'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'editar',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Editar'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'apagar',
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline),
                                    title: Text('Apagar'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            )
                          : null,
                      onTap: () => _abrirDetalhe(c),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Novo catequisando',
        child: const Icon(Icons.add),
      ),
    );
  }
}
