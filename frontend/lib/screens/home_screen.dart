import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'catequisandos_screen.dart';
import 'eventos_screen.dart';
import 'fases_screen.dart';
import 'gerir_catequistas_screen.dart';
import 'ministerios_screen.dart';
import 'presencas_screen.dart';
import 'retiros_screen.dart';
import 'sectores_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final catequista = auth.catequista;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão Catequética'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Terminar sessão',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 640 : double.infinity),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  'Bem-vindo(a), ${catequista?.nome ?? ''}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _CartaoMenu(
                  icon: Icons.groups_outlined,
                  titulo: 'Catequisandos',
                  subtitulo: 'Registar, editar e consultar por fase',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CatequisandosScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _CartaoMenu(
                  icon: Icons.check_circle_outline,
                  titulo: 'Presenças',
                  subtitulo: 'Marcar presenças de sábado e domingo',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PresencasScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _CartaoMenu(
                  icon: Icons.self_improvement_outlined,
                  titulo: 'Retiros',
                  subtitulo: 'Criar, editar e imprimir a ficha do retiro',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RetirosScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _CartaoMenu(
                  icon: Icons.event_outlined,
                  titulo: 'Eventos da Paróquia',
                  subtitulo: 'Festa da padroeira, baptismos, crismas...',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EventosScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _CartaoMenu(
                  icon: Icons.account_tree_outlined,
                  titulo: 'Ministérios',
                  subtitulo: 'Organograma: ministérios e coordenadores',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MinisteriosScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _CartaoMenu(
                  icon: Icons.groups_2_outlined,
                  titulo: 'Sectores da Paróquia',
                  subtitulo: 'Acolhimento, Acólitos e outros encontros',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SectoresScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _CartaoMenu(
                  icon: Icons.stairs_outlined,
                  titulo: 'Fases catequéticas',
                  subtitulo: 'Criar e organizar as fases (anos, turmas...)',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FasesScreen()),
                  ),
                ),
                if (catequista?.isAdmin ?? false) ...[
                  const SizedBox(height: 12),
                  _CartaoMenu(
                    icon: Icons.admin_panel_settings_outlined,
                    titulo: 'Gerir catequistas',
                    subtitulo: 'Promover ou remover permissões de administrador',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GerirCatequistasScreen()),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaoMenu extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _CartaoMenu({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(radius: 24, child: Icon(icon)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
