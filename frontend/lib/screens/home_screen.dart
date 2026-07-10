import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'auditoria_screen.dart';
import 'caixa_screen.dart';
import 'catequisandos_screen.dart';
import 'configuracao_screen.dart';
import 'eventos_screen.dart';
import 'fases_screen.dart';
import 'fotos_screen.dart';
import 'gerir_catequistas_screen.dart';
import 'inscricoes_screen.dart';
import 'inventario_screen.dart';
import 'ministerios_screen.dart';
import 'pauta_screen.dart';
import 'perfil_screen.dart';
import 'presencas_screen.dart';
import 'publico_screen.dart';
import 'relatorios_screen.dart';
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

    // Nível de acesso: admin ou atribuído a uma fase vê tudo; responsável de
    // sector vê (além do básico) o Inventário; sem nenhum dos dois, só o
    // essencial — até um administrador atribuir algo.
    final temAcessoCompleto = catequista?.temAcessoCompleto ?? false;
    final eResponsavelDeSector = catequista?.eResponsavelDeSector ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/images/icone_comunidade.png'),
          ),
        ),
        title: const Text('Gestão Catequética'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'O meu perfil',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PerfilScreen()),
            ),
          ),
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
                if (!temAcessoCompleto && !eResponsavelDeSector)
                  Card(
                    color: Colors.amber.withValues(alpha: 0.12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.amber.shade300),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'A tua conta ainda não foi atribuída a nenhuma fase ou sector. '
                              'Pede a um administrador para te atribuir, e os módulos de gestão vão aparecer aqui.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!temAcessoCompleto && !eResponsavelDeSector) const SizedBox(height: 16),
                _CartaoMenu(
                  icon: Icons.public,
                  titulo: 'Ver página pública',
                  subtitulo: 'O que é mostrado a quem não tem sessão iniciada',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PublicoScreen()),
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
                if (temAcessoCompleto) ...[
                  const SizedBox(height: 12),
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
                    icon: Icons.fact_check_outlined,
                    titulo: 'Pauta',
                    subtitulo: 'Situação dos catequisandos por fase (permanece/progride)',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PautaScreen()),
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
                    titulo: 'Eventos da Comunidade',
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
                    titulo: 'Sectores',
                    subtitulo: 'Acolhimento, Acólitos e outros encontros',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SectoresScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CartaoMenu(
                    icon: Icons.photo_library_outlined,
                    titulo: 'Fotos do Carrossel',
                    subtitulo: 'Fotos mostradas na página pública',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FotosScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CartaoMenu(
                    icon: Icons.point_of_sale_outlined,
                    titulo: 'Caixa da Catequese',
                    subtitulo: 'Receitas, despesas e saldo',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CaixaScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CartaoMenu(
                    icon: Icons.app_registration_outlined,
                    titulo: 'Inscrições e Renovações',
                    subtitulo: 'Registar pagamentos de inscrição, renovação e ficha',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InscricoesScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CartaoMenu(
                    icon: Icons.calendar_month_outlined,
                    titulo: 'Ano Letivo',
                    subtitulo: 'Ver o ano corrente e avançar para o próximo',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ConfiguracaoScreen()),
                    ),
                  ),
                ],
                if (temAcessoCompleto || eResponsavelDeSector) ...[
                  const SizedBox(height: 12),
                  _CartaoMenu(
                    icon: Icons.inventory_2_outlined,
                    titulo: 'Inventário',
                    subtitulo: eResponsavelDeSector && !temAcessoCompleto
                        ? 'Material do(s) teu(s) sector(es)'
                        : 'Material e equipamento disponível',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InventarioScreen()),
                    ),
                  ),
                ],
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
                  const SizedBox(height: 12),
                  _CartaoMenu(
                    icon: Icons.bar_chart_outlined,
                    titulo: 'Relatórios',
                    subtitulo: 'Estatísticas de catequisandos por fase e género',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RelatoriosScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CartaoMenu(
                    icon: Icons.history_outlined,
                    titulo: 'Registo de Atividade',
                    subtitulo: 'Quem criou, editou e apagou o quê (auditoria)',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuditoriaScreen()),
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
