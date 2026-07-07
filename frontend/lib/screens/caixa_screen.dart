import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/caixa.dart';
import '../models/catequisando.dart';
import '../models/fase.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/caixa_service.dart';
import '../services/catequisando_service.dart';
import '../services/fase_service.dart';

class CaixaScreen extends StatefulWidget {
  const CaixaScreen({super.key});

  @override
  State<CaixaScreen> createState() => _CaixaScreenState();
}

class _CaixaScreenState extends State<CaixaScreen> {
  late CaixaService _service;
  late CatequisandoService _catequisandoService;
  late FaseService _faseService;
  bool _isAdmin = false;

  List<CaixaTransacao> _transacoes = [];
  ResumoCaixa? _resumo;
  TipoTransacao? _filtro;
  bool _loading = true;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = CaixaService(auth.token);
    _catequisandoService = CatequisandoService(auth.token);
    _faseService = FaseService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final resumo = await _service.resumo();
      final transacoes = await _service.listar(tipo: _filtro);
      if (!mounted) return;
      setState(() {
        _resumo = resumo;
        _transacoes = transacoes;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar o caixa');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatarMT(double v) => '${v.toStringAsFixed(2)} MT';

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _mostrarFormulario({CaixaTransacao? transacao}) async {
    List<Catequisando> catequisandos;
    List<Fase> fases;
    try {
      catequisandos = await _catequisandoService.listar();
      fases = await _faseService.listar();
    } catch (e) {
      _mostrarErro(e);
      return;
    }
    if (!mounted) return;

    TipoTransacao tipo = transacao?.tipo ?? TipoTransacao.receita;
    final categoriaController = TextEditingController(text: transacao?.categoria ?? '');
    final valorController = TextEditingController(text: transacao?.valor.toStringAsFixed(2) ?? '');
    final descricaoController = TextEditingController(text: transacao?.descricao ?? '');
    MetodoPagamento? metodo = transacao?.metodoPagamento;
    Catequisando? catequisandoSelecionado;
    if (transacao?.catequisandoId != null) {
      for (final c in catequisandos) {
        if (c.id == transacao!.catequisandoId) {
          catequisandoSelecionado = c;
          break;
        }
      }
    }
    Fase? faseSelecionada;
    if (transacao?.faseId != null) {
      for (final f in fases) {
        if (f.id == transacao!.faseId) {
          faseSelecionada = f;
          break;
        }
      }
    }
    DateTime data = transacao?.data ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(transacao == null ? 'Nova transação' : 'Editar transação'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<TipoTransacao>(
                      segments: const [
                        ButtonSegment(value: TipoTransacao.receita, label: Text('Receita')),
                        ButtonSegment(value: TipoTransacao.despesa, label: Text('Despesa')),
                      ],
                      selected: {tipo},
                      onSelectionChanged: (v) => setStateDialog(() => tipo = v.first),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: categoriaController,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        hintText: 'Ex: Inscrição, Doação, Material...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Indica a categoria' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: valorController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Valor (MT)', border: OutlineInputBorder()),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                        return (n == null || n <= 0) ? 'Indica um valor válido' : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MetodoPagamento?>(
                      value: metodo,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Método de pagamento (opcional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Não aplicável')),
                        ...MetodoPagamento.values.map((m) => DropdownMenuItem(value: m, child: Text(m.rotulo))),
                      ],
                      onChanged: (v) => setStateDialog(() => metodo = v),
                    ),
                    const SizedBox(height: 12),
                    Autocomplete<Catequisando>(
                      displayStringForOption: (c) => c.nome,
                      initialValue: TextEditingValue(text: catequisandoSelecionado?.nome ?? ''),
                      optionsBuilder: (v) {
                        if (v.text.isEmpty) return const Iterable<Catequisando>.empty();
                        return catequisandos.where((c) => c.nome.toLowerCase().contains(v.text.toLowerCase()));
                      },
                      onSelected: (c) => setStateDialog(() => catequisandoSelecionado = c),
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Catequisando (opcional)',
                          hintText: 'Pesquisar por nome',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          if (v.isEmpty) setStateDialog(() => catequisandoSelecionado = null);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Fase?>(
                      value: faseSelecionada,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Fase (obrigatória para Inscrição/Renovação)',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Nenhuma')),
                        ...fases.map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.nome, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) => setStateDialog(() => faseSelecionada = v),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final escolhida = await showDatePicker(
                          context: context,
                          initialDate: data,
                          firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (escolhida != null) setStateDialog(() => data = escolhida);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                        ),
                        child: Text(_formatarData(data)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descricaoController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Descrição (opcional)', border: OutlineInputBorder()),
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

    final valor = double.parse(valorController.text.replaceAll(',', '.'));

    try {
      if (transacao == null) {
        await _service.criar(
          tipo: tipo,
          categoria: categoriaController.text.trim(),
          valor: valor,
          metodoPagamento: metodo,
          catequisandoId: catequisandoSelecionado?.id,
          faseId: faseSelecionada?.id,
          descricao: descricaoController.text.trim(),
          data: data,
        );
      } else {
        await _service.atualizar(
          transacao.id,
          tipo: tipo,
          categoria: categoriaController.text.trim(),
          valor: valor,
          metodoPagamento: metodo,
          catequisandoId: catequisandoSelecionado?.id,
          faseId: faseSelecionada?.id,
          descricao: descricaoController.text.trim(),
          data: data,
        );
      }
      _carregar();
    } catch (e) {
      _mostrarErro(e);
    }
  }

  Future<void> _apagar(CaixaTransacao t) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar transação'),
        content: Text('Tens a certeza que queres apagar "${t.categoria}" (${_formatarMT(t.valor)})?'),
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
      await _service.apagar(t.id);
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
      appBar: AppBar(title: const Text('Caixa da Catequese')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (_resumo != null)
                        Row(
                          children: [
                            Expanded(child: _CartaoResumo(titulo: 'Receitas', valor: _resumo!.totalReceitas, cor: Colors.green)),
                            const SizedBox(width: 8),
                            Expanded(child: _CartaoResumo(titulo: 'Despesas', valor: _resumo!.totalDespesas, cor: Colors.red)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CartaoResumo(
                                titulo: 'Saldo',
                                valor: _resumo!.saldo,
                                cor: _resumo!.saldo >= 0 ? Colors.blueGrey : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Todas'),
                            selected: _filtro == null,
                            onSelected: (_) {
                              setState(() => _filtro = null);
                              _carregar();
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Receitas'),
                            selected: _filtro == TipoTransacao.receita,
                            onSelected: (_) {
                              setState(() => _filtro = TipoTransacao.receita);
                              _carregar();
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Despesas'),
                            selected: _filtro == TipoTransacao.despesa,
                            onSelected: (_) {
                              setState(() => _filtro = TipoTransacao.despesa);
                              _carregar();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_transacoes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text('Sem transações registadas.')),
                        )
                      else
                        ..._transacoes.map((t) {
                          final receita = t.tipo == TipoTransacao.receita;
                          final detalhes = [
                            _formatarData(t.data),
                            if (t.catequisandoNome != null) t.catequisandoNome!,
                            if (t.faseNome != null) t.faseNome!,
                            if (t.metodoPagamento != null) t.metodoPagamento!.rotulo,
                            'por ${t.registadoPorNome}',
                          ].join(' · ');
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: (receita ? Colors.green : Colors.red).withValues(alpha: 0.15),
                                child: Icon(
                                  receita ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: receita ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(t.categoria),
                              subtitle: Text(detalhes),
                              isThreeLine: false,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${receita ? '+' : '-'}${_formatarMT(t.valor)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: receita ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  if (_isAdmin) ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      onPressed: () => _mostrarFormulario(transacao: t),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      onPressed: () => _apagar(t),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () => _mostrarFormulario(),
              tooltip: 'Nova transação',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _CartaoResumo extends StatelessWidget {
  final String titulo;
  final double valor;
  final Color cor;

  const _CartaoResumo({required this.titulo, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cor.withValues(alpha: 0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(titulo, style: TextStyle(fontSize: 12, color: cor.withValues(alpha: 0.9))),
            const SizedBox(height: 4),
            Text(
              '${valor.toStringAsFixed(2)} MT',
              style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
