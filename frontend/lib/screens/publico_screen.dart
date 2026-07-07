import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/foto.dart';
import '../services/auth_service.dart';
import '../services/publico_service.dart';
import 'login_screen.dart';
import 'publico_eventos_screen.dart';
import 'publico_links_screen.dart';
import 'publico_organograma_screen.dart';
import 'publico_retiros_screen.dart';
import 'publico_sectores_screen.dart';

class PublicoScreen extends StatefulWidget {
  const PublicoScreen({super.key});

  @override
  State<PublicoScreen> createState() => _PublicoScreenState();
}

class _PublicoScreenState extends State<PublicoScreen> {
  final _service = PublicoService();

  List<Foto> _fotos = [];
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
      final fotos = await _service.listarFotos();
      if (!mounted) return;
      setState(() => _fotos = fotos);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar a informação. Verifica a tua ligação à internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;
    final jaAutenticado = context.watch<AuthService>().isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Comunidade Santa Ana de Mastrong', style: TextStyle(fontSize: 17)),
            Text(
              'Paróquia de Nossa Senhora da Assunção – Liberdade',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (!jaAutenticado)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Entrar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/icone_comunidade.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_erro != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(_erro!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                      ],
                    ),
                  )
                else if (_fotos.isNotEmpty)
                  _CarrosselFotos(fotos: _fotos),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    _CartaoNav(
                      icon: Icons.self_improvement_outlined,
                      titulo: 'Retiros',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PublicoRetirosScreen()),
                      ),
                    ),
                    _CartaoNav(
                      icon: Icons.event_outlined,
                      titulo: 'Eventos',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PublicoEventosScreen()),
                      ),
                    ),
                    _CartaoNav(
                      icon: Icons.groups_2_outlined,
                      titulo: 'Encontros dos Sectores',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PublicoSectoresScreen()),
                      ),
                    ),
                    _CartaoNav(
                      icon: Icons.account_tree_outlined,
                      titulo: 'Organograma',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PublicoOrganogramaScreen()),
                      ),
                    ),
                    _CartaoNav(
                      icon: Icons.share_outlined,
                      titulo: 'Links & Redes Sociais',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PublicoLinksScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão de navegação em grelha (ícone + título), usado na página pública.
class _CartaoNav extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final VoidCallback onTap;

  const _CartaoNav({required this.icon, required this.titulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(radius: 24, child: Icon(icon)),
              const SizedBox(height: 10),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carrossel de fotos com avanço automático e indicadores de página.
class _CarrosselFotos extends StatefulWidget {
  final List<Foto> fotos;

  const _CarrosselFotos({required this.fotos});

  @override
  State<_CarrosselFotos> createState() => _CarrosselFotosState();
}

class _CarrosselFotosState extends State<_CarrosselFotos> {
  late final PageController _controller;
  int _paginaAtual = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.fotos.length < 2) return;
      final proxima = (_paginaAtual + 1) % widget.fotos.length;
      _controller.animateToPage(
        proxima,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.fotos.length,
              onPageChanged: (i) => setState(() => _paginaAtual = i),
              itemBuilder: (context, i) {
                final foto = widget.fotos[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      foto.urlImagem,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                      ),
                    ),
                    if (foto.titulo != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                            ),
                          ),
                          child: Text(
                            foto.titulo!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (widget.fotos.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.fotos.length, (i) {
                    final ativo = i == _paginaAtual;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: ativo ? 10 : 7,
                      height: ativo ? 10 : 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ativo ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
