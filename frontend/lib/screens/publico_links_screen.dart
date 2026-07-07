import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PublicoLinksScreen extends StatelessWidget {
  const PublicoLinksScreen({super.key});

  Future<void> _abrirLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Links & Redes Sociais')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Redes Sociais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                  title: const Text('Facebook'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _abrirLink(
                    context,
                    'https://www.facebook.com/profile.php?id=61552397130822',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.music_note_outlined),
                  title: const Text('TikTok'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _abrirLink(context, 'https://www.tiktok.com/@santa.ana.mastron'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.smart_display_outlined, color: Color(0xFFFF0000)),
                  title: const Text('YouTube'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _abrirLink(
                    context,
                    'https://www.youtube.com/@ComunidadeSantaAnaMastrong',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Links Úteis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Calendário Litúrgico 2026'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _abrirLink(context, 'https://gcatholic.org/calendar/2026/General-G-pt'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('Catecismo da Igreja Católica'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _abrirLink(
                    context,
                    'https://www.vatican.va/archive/cathechism_po/index_new/prima-pagina-cic_po.html',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.church_outlined),
                  title: const Text('Site da Paróquia'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _abrirLink(context, 'https://www.assuncaoliberdade.org.mz/'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
