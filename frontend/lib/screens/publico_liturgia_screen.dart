import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/liturgia.dart';
import '../services/api_client.dart';
import '../services/publico_service.dart';

class PublicoLiturgiaScreen extends StatefulWidget {
  const PublicoLiturgiaScreen({super.key});

  @override
  State<PublicoLiturgiaScreen> createState() => _PublicoLiturgiaScreenState();
}

class _PublicoLiturgiaScreenState extends State<PublicoLiturgiaScreen> {
  final _service = PublicoService();
  LiturgiaDiaria? _liturgia;
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
      final liturgia = await _service.liturgiaDiaria();
      if (!mounted) return;
      setState(() => _liturgia = liturgia);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar a liturgia de hoje');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirFonte(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Color _corLiturgica(String? cor) {
    switch (cor?.toLowerCase()) {
      case 'verde':
        return Colors.green;
      case 'roxo':
      case 'violeta':
        return Colors.deepPurple;
      case 'vermelho':
        return Colors.red;
      case 'rosa':
        return Colors.pink;
      case 'branco':
        return Colors.grey.shade300;
      case 'dourado':
      case 'ouro':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _cartaoLeitura(String titulo, String texto, {IconData icon = Icons.menu_book_outlined}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(texto, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _cartaoFallback(String fonteUrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Não foi possível carregar a liturgia de hoje neste momento.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _abrirFonte(fonteUrl),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ler no site da liturgia'),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _carregar, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Liturgia Diária')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 700 : double.infinity),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _erro != null
                  ? Center(child: Text(_erro!))
                  : (_liturgia == null || !_liturgia!.disponivel)
                      ? _cartaoFallback(_liturgia?.fonteUrl ?? 'https://sagradaliturgia.com.br/')
                      : RefreshIndicator(
                          onRefresh: _carregar,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: _corLiturgica(_liturgia!.corLiturgica),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _liturgia!.tempoLiturgico ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              if (_liturgia!.data != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                                  child: Text(_liturgia!.data!, style: const TextStyle(color: Colors.black54)),
                                )
                              else
                                const SizedBox(height: 16),
                              if (_liturgia!.primeiraLeitura != null)
                                _cartaoLeitura(
                                  _liturgia!.primeiraLeitura!.titulo,
                                  _liturgia!.primeiraLeitura!.texto,
                                  icon: Icons.looks_one_outlined,
                                ),
                              if (_liturgia!.salmo != null)
                                _cartaoLeitura(
                                  '${_liturgia!.salmo!.titulo} — ${_liturgia!.salmo!.resposta}',
                                  _liturgia!.salmo!.versos.join('\n'),
                                  icon: Icons.music_note_outlined,
                                ),
                              if (_liturgia!.segundaLeitura != null)
                                _cartaoLeitura(
                                  _liturgia!.segundaLeitura!.titulo,
                                  _liturgia!.segundaLeitura!.texto,
                                  icon: Icons.looks_two_outlined,
                                ),
                              if (_liturgia!.evangelho != null)
                                _cartaoLeitura(
                                  _liturgia!.evangelho!.titulo,
                                  _liturgia!.evangelho!.texto,
                                  icon: Icons.auto_stories_outlined,
                                ),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => _abrirFonte(_liturgia!.fonteUrl),
                                  icon: const Icon(Icons.open_in_new, size: 16),
                                  label: const Text('Fonte: sagradaliturgia.com.br'),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
        ),
      ),
    );
  }
}
