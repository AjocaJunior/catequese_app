import 'package:flutter/material.dart';

import '../models/evento.dart';
import '../services/publico_service.dart';

class PublicoEventosScreen extends StatefulWidget {
  const PublicoEventosScreen({super.key});

  @override
  State<PublicoEventosScreen> createState() => _PublicoEventosScreenState();
}

class _PublicoEventosScreenState extends State<PublicoEventosScreen> {
  final _service = PublicoService();
  List<Evento> _eventos = [];
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
      final eventos = await _service.listarEventos();
      if (!mounted) return;
      setState(() => _eventos = eventos);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar os eventos. Verifica a tua ligação à internet.');
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
      appBar: AppBar(title: const Text('Eventos da Comunidade')),
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
                      child: _eventos.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Sem eventos agendados de momento.',
                                      style: TextStyle(color: Colors.grey.shade600)),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _eventos.length,
                              itemBuilder: (context, i) {
                                final e = _eventos[i];
                                return Card(
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
                                );
                              },
                            ),
                    ),
                  ),
                ),
    );
  }
}
