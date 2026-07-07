import 'package:flutter/material.dart';

import '../models/organograma.dart';
import '../services/publico_service.dart';

class PublicoOrganogramaScreen extends StatefulWidget {
  const PublicoOrganogramaScreen({super.key});

  @override
  State<PublicoOrganogramaScreen> createState() => _PublicoOrganogramaScreenState();
}

class _PublicoOrganogramaScreenState extends State<PublicoOrganogramaScreen> {
  final _service = PublicoService();
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
      final organograma = await _service.organograma();
      if (!mounted) return;
      setState(() => _organograma = organograma);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar o organograma. Verifica a tua ligação à internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;
    final vazio = _organograma == null ||
        (_organograma!.ministerios.isEmpty && _organograma!.sectoresSemMinisterio.isEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('Organograma')),
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
                      child: vazio
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Organograma ainda por definir.',
                                      style: TextStyle(color: Colors.grey.shade600)),
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
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
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.bold, fontSize: 15)),
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
                                                child: Text('Sectores:',
                                                    style: TextStyle(fontWeight: FontWeight.w600)),
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
                                          const Text('Outros sectores',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                            ),
                    ),
                  ),
                ),
    );
  }
}
