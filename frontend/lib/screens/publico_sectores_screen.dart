import 'package:flutter/material.dart';

import '../models/sector.dart';
import '../services/publico_service.dart';

class PublicoSectoresScreen extends StatefulWidget {
  const PublicoSectoresScreen({super.key});

  @override
  State<PublicoSectoresScreen> createState() => _PublicoSectoresScreenState();
}

class _PublicoSectoresScreenState extends State<PublicoSectoresScreen> {
  final _service = PublicoService();
  List<Sector> _sectores = [];
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
      final sectores = await _service.listarSectores();
      if (!mounted) return;
      setState(() => _sectores = sectores);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar os sectores. Verifica a tua ligação à internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;
    final comEncontro = _sectores.where((s) => s.diaSemana != null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Encontros dos Sectores')),
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
                      child: comEncontro.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Sem encontros regulares divulgados de momento.',
                                      style: TextStyle(color: Colors.grey.shade600)),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: comEncontro.length,
                              itemBuilder: (context, i) {
                                final s = comEncontro[i];
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.groups_2_outlined),
                                    title: Text(s.nome),
                                    subtitle: Text(
                                      '${s.diaSemana!.rotulo}, ${s.hora ?? "hora por definir"}'
                                      '${s.local != null ? ' · ${s.local}' : ''}',
                                    ),
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
