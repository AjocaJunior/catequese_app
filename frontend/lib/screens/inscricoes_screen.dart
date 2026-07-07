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

/// As 3 taxas cobradas pela catequese, com o respetivo valor sugerido.
enum _TipoInscricao {
  inscricao(CategoriaCaixa.inscricao, 30),
  renovacao(CategoriaCaixa.renovacao, 30),
  ficha(CategoriaCaixa.fichaCatecumeno, 50);

  final String categoria;
  final double valorSugerido;
  const _TipoInscricao(this.categoria, this.valorSugerido);
}

class InscricoesScreen extends StatefulWidget {
  const InscricoesScreen({super.key});

  @override
  State<InscricoesScreen> createState() => _InscricoesScreenState();
}

class _InscricoesScreenState extends State<InscricoesScreen> {
  late CaixaService _caixaService;
  late CatequisandoService _catequisandoService;
  late FaseService _faseService;
  bool _isAdmin = false;

  List<CaixaTransacao> _historico = [];
  List<Catequisando> _catequisandos = [];
  List<Fase> _fases = [];
  bool _loading = true;
  bool _submitting = false;
  String? _erro;

  // Estado do formulário (só usado se _isAdmin)
  Catequisando? _catequisandoSelecionado;
  Fase? _faseSelecionada;
  _TipoInscricao _tipo = _TipoInscricao.inscricao;
  MetodoPagamento _metodo = MetodoPagamento.numerario;
  final _valorController = TextEditingController(text: '30.00');
  DateTime _data = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  static const _categoriasConhecidas = [
    CategoriaCaixa.inscricao,
    CategoriaCaixa.renovacao,
    CategoriaCaixa.fichaCatecumeno,
  ];

  bool get _exigeFase => _tipo != _TipoInscricao.ficha;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _caixaService = CaixaService(auth.token);
    _catequisandoService = CatequisandoService(auth.token);
    _faseService = FaseService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _carregar();
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final todas = await _caixaService.listar(tipo: TipoTransacao.receita);
      final historico = todas.where((t) => _categoriasConhecidas.contains(t.categoria)).toList();
      final catequisandos = _isAdmin ? await _catequisandoService.listar() : <Catequisando>[];
      final fases = _isAdmin ? await _faseService.listar() : <Fase>[];
      if (!mounted) return;
      setState(() {
        _historico = historico;
        _catequisandos = catequisandos;
        _fases = fases;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatarMT(double v) => '${v.toStringAsFixed(2)} MT';

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _registar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_catequisandoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona o catequisando')),
      );
      return;
    }
    if (_exigeFase && _faseSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona a fase')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _caixaService.criar(
        tipo: TipoTransacao.receita,
        categoria: _tipo.categoria,
        valor: double.parse(_valorController.text.replaceAll(',', '.')),
        metodoPagamento: _metodo,
        catequisandoId: _catequisandoSelecionado!.id,
        faseId: _faseSelecionada?.id,
        data: _data,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_tipo.categoria} registada para ${_catequisandoSelecionado!.nome}')),
      );
      setState(() {
        _catequisandoSelecionado = null;
        _faseSelecionada = null;
      });
      _carregar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao registar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Ao escolher o catequisando, sugere automaticamente a fase em que ele
  /// está atualmente — o admin pode mudar (ex: renovação com promoção de fase).
  void _selecionarCatequisando(Catequisando c) {
    setState(() {
      _catequisandoSelecionado = c;
      Fase? faseAtual;
      for (final f in _fases) {
        if (f.id == c.faseId) {
          faseAtual = f;
          break;
        }
      }
      _faseSelecionada = faseAtual;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Inscrições e Renovações')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_isAdmin) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Text('Registar nova inscrição / renovação',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 16),
                                      Autocomplete<Catequisando>(
                                        displayStringForOption: (c) => c.nome,
                                        optionsBuilder: (v) {
                                          if (v.text.isEmpty) return const Iterable<Catequisando>.empty();
                                          return _catequisandos
                                              .where((c) => c.nome.toLowerCase().contains(v.text.toLowerCase()));
                                        },
                                        onSelected: _selecionarCatequisando,
                                        fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
                                            TextFormField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          decoration: const InputDecoration(
                                            labelText: 'Catequisando',
                                            hintText: 'Pesquisar por nome',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SegmentedButton<_TipoInscricao>(
                                        segments: _TipoInscricao.values
                                            .map((t) => ButtonSegment(value: t, label: Text(t.categoria)))
                                            .toList(),
                                        selected: {_tipo},
                                        onSelectionChanged: (v) {
                                          setState(() {
                                            _tipo = v.first;
                                            _valorController.text = _tipo.valorSugerido.toStringAsFixed(2);
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      if (_exigeFase)
                                        DropdownButtonFormField<Fase>(
                                          value: _faseSelecionada,
                                          isExpanded: true,
                                          decoration: const InputDecoration(labelText: 'Fase'),
                                          items: _fases
                                              .map((f) => DropdownMenuItem(
                                                    value: f,
                                                    child: Text(f.nome, overflow: TextOverflow.ellipsis),
                                                  ))
                                              .toList(),
                                          onChanged: (v) => setState(() => _faseSelecionada = v),
                                        ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _valorController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(labelText: 'Valor (MT)', border: OutlineInputBorder()),
                                        validator: (v) {
                                          final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                                          return (n == null || n <= 0) ? 'Valor inválido' : null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<MetodoPagamento>(
                                        value: _metodo,
                                        isExpanded: true,
                                        decoration: const InputDecoration(labelText: 'Método de pagamento'),
                                        items: MetodoPagamento.values
                                            .map((m) => DropdownMenuItem(value: m, child: Text(m.rotulo)))
                                            .toList(),
                                        onChanged: (v) => setState(() => _metodo = v ?? _metodo),
                                      ),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        onTap: () async {
                                          final escolhida = await showDatePicker(
                                            context: context,
                                            initialDate: _data,
                                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                            lastDate: DateTime.now().add(const Duration(days: 30)),
                                          );
                                          if (escolhida != null) setState(() => _data = escolhida);
                                        },
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Data',
                                            border: OutlineInputBorder(),
                                            suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                                          ),
                                          child: Text(_formatarData(_data)),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 48,
                                        child: FilledButton(
                                          onPressed: _submitting ? null : _registar,
                                          child: _submitting
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Text('Registar pagamento'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          const Text('Histórico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          if (_historico.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('Ainda não há inscrições, renovações ou fichas registadas.'),
                            )
                          else
                            ..._historico.map((t) => Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.receipt_long_outlined),
                                    title: Text('${t.categoria} — ${t.catequisandoNome ?? "—"}'),
                                    subtitle: Text(
                                      '${_formatarData(t.data)}'
                                      '${t.faseNome != null ? ' · ${t.faseNome}' : ''}'
                                      '${t.metodoPagamento != null ? ' · ${t.metodoPagamento!.rotulo}' : ''}'
                                      ' · por ${t.registadoPorNome}',
                                    ),
                                    trailing: Text(
                                      _formatarMT(t.valor),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
