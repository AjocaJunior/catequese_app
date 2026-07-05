import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/evento.dart';
import '../models/organograma.dart';
import '../models/retiro_publico.dart';
import '../models/sector.dart';
import '../services/publico_service.dart';

class PublicoScreen extends StatefulWidget {
  const PublicoScreen({super.key});

  @override
  State<PublicoScreen> createState() => _PublicoScreenState();
}

class _PublicoScreenState extends State<PublicoScreen> {
  final _service = PublicoService();

  List<RetiroPublico> _retiros = [];
  List<Evento> _eventos = [];
  List<Sector> _sectores = [];
  Organograma? _organograma;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final resultados = await Future.wait([
        _service.listarRetiros(),
        _service.listarEventos(),
        _service.listarSectores(),
        _service.organograma(),
      ]);
      if (!mounted) return;
      setState(() {
        _retiros = resultados[0] as List<RetiroPublico>;
        _eventos = resultados[1] as List<Evento>;
        _sectores = resultados[2] as List<Sector>;
        _organograma = resultados[3] as Organograma;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar a informação. Verifica a tua ligação à internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir $url')),
      );
    }
  }

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Paróquia de Nossa Senhora da Assunção')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_erro!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        OutlinedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _tituloSeccao('Retiros'),
                          if (_retiros.isEmpty)
                            _semInformacao('Sem retiros agendados de momento.')
                          else
                            ..._retiros.map((r) => Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.self_improvement_outlined),
                                    title: Text(r.titulo),
                                    subtitle: Text(
                                      '${_formatarData(r.data)} · ${r.local}'
                                      '${r.fases.isNotEmpty ? '\nFases: ${r.fases.join(', ')}' : ''}',
                                    ),
                                    isThreeLine: r.fases.isNotEmpty,
                                  ),
                                )),
                          const SizedBox(height: 20),
                          _tituloSeccao('Eventos da Paróquia'),
                          if (_eventos.isEmpty)
                            _semInformacao('Sem eventos agendados de momento.')
                          else
                            ..._eventos.map((e) => Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.event_outlined),
                                    title: Text(e.titulo),
                                    subtitle: Text(
                                      '${_formatarData(e.data)}'
                                      '${e.local != null ? ' · ${e.local}' : ''}'
                                      '${e.descricao != null ? '\n${e.descricao}' : ''}',
                                    ),
                                    isThreeLine: e.descricao != null,
                                  ),
                                )),
                          const SizedBox(height: 20),
                          _tituloSeccao('Encontros dos Sectores'),
                          Builder(builder: (context) {
                            final comEncontro = _sectores.where((s) => s.diaSemana != null).toList();
                            if (comEncontro.isEmpty) {
                              return _semInformacao('Sem encontros regulares divulgados de momento.');
                            }
                            return Column(
                              children: comEncontro
                                  .map((s) => Card(
                                        child: ListTile(
                                          leading: const Icon(Icons.groups_2_outlined),
                                          title: Text(s.nome),
                                          subtitle: Text(
                                            '${s.diaSemana!.rotulo}, ${s.hora ?? "hora por definir"}'
                                            '${s.local != null ? ' · ${s.local}' : ''}',
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            );
                          }),
                          const SizedBox(height: 20),
                          _tituloSeccao('Organograma'),
                          if (_organograma == null ||
                              (_organograma!.ministerios.isEmpty && _organograma!.sectoresSemMinisterio.isEmpty))
                            _semInformacao('Organograma ainda por definir.')
                          else ...[
                            ..._organograma!.ministerios.map((m) => Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.account_tree_outlined, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(m.nome,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            ),
                                          ],
                                        ),
                                        if (m.coordenadorNome != null)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 28, top: 4),
                                            child: Text('Coordenador(a): ${m.coordenadorNome}'),
                                          ),
                                        if (m.sectores.isNotEmpty) ...[
                                          const Padding(
                                            padding: EdgeInsets.only(left: 28, top: 8, bottom: 2),
                                            child: Text('Sectores:', style: TextStyle(fontWeight: FontWeight.w600)),
                                          ),
                                          ...m.sectores.map((s) => Padding(
                                                padding: const EdgeInsets.only(left: 40, top: 2),
                                                child: Text(
                                                  '• ${s.nome}${s.responsavelNome != null ? ' — ${s.responsavelNome}' : ''}',
                                                ),
                                              )),
                                        ],
                                      ],
                                    ),
                                  ),
                                )),
                            if (_organograma!.sectoresSemMinisterio.isNotEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Outros sectores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      ..._organograma!.sectoresSemMinisterio.map((s) => Padding(
                                            padding: const EdgeInsets.only(left: 12, top: 4),
                                            child: Text(
                                              '• ${s.nome}${s.responsavelNome != null ? ' — ${s.responsavelNome}' : ''}',
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 20),
                          _tituloSeccao('Links Úteis'),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.calendar_month_outlined),
                              title: const Text('Calendário Litúrgico 2026'),
                              trailing: const Icon(Icons.open_in_new, size: 18),
                              onTap: () => _abrirLink('https://gcatholic.org/calendar/2026/General-G-pt'),
                            ),
                          ),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.menu_book_outlined),
                              title: const Text('Catecismo da Igreja Católica'),
                              trailing: const Icon(Icons.open_in_new, size: 18),
                              onTap: () => _abrirLink(
                                'https://www.vatican.va/archive/cathechism_po/index_new/prima-pagina-cic_po.html',
                              ),
                            ),
                          ),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.church_outlined),
                              title: const Text('Site da Paróquia'),
                              trailing: const Icon(Icons.open_in_new, size: 18),
                              onTap: () => _abrirLink('https://www.assuncaoliberdade.org.mz/'),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _tituloSeccao(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _semInformacao(String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(texto, style: TextStyle(color: Colors.grey.shade600)),
      );
}
