import 'package:flutter/material.dart';

import '../models/retiro_publico.dart';
import '../services/publico_service.dart';

class PublicoRetirosScreen extends StatefulWidget {
  const PublicoRetirosScreen({super.key});

  @override
  State<PublicoRetirosScreen> createState() => _PublicoRetirosScreenState();
}

class _PublicoRetirosScreenState extends State<PublicoRetirosScreen> {
  final _service = PublicoService();
  List<RetiroPublico> _retiros = [];
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
      final retiros = await _service.listarRetiros();
      if (!mounted) return;
      setState(() => _retiros = retiros);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar os retiros. Verifica a tua ligação à internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Retiros')),
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
                      child: _retiros.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Sem retiros agendados de momento.',
                                      style: TextStyle(color: Colors.grey.shade600)),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _retiros.length,
                              itemBuilder: (context, i) {
                                final r = _retiros[i];
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.self_improvement_outlined),
                                    title: Text(r.titulo),
                                    subtitle: Text(
                                      '${_formatarData(r.data)} · ${r.local}'
                                      '${r.fases.isNotEmpty ? '\nFases: ${r.fases.join(', ')}' : ''}',
                                    ),
                                    isThreeLine: r.fases.isNotEmpty,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
    );
  }
}
