import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/cartao_grelha.dart';
import '../widgets/cartao_menu.dart';
import 'auditoria_screen.dart';
import 'caixa_screen.dart';
import 'categoria_screen.dart';
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
import 'pessoas_screen.dart';
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
    final isAdmin = catequista?.isAdmin ?? false;

    void abrirCategoria(String titulo, List<Widget> itens) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CategoriaScreen(titulo: titulo, itens: itens)),
      );
    }

    // --- Itens de cada categoria (construídos aqui, usados no ecrã da categoria) ---
    final itensCatequese = <Widget>[
      CartaoMenu(
        icon: Icons.groups_outlined,
        titulo: 'Catequisandos',
        subtitulo: 'Registar, editar e consultar por fase',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CatequisandosScreen())),
      ),
      CartaoMenu(
        icon: Icons.check_circle_outline,
        titulo: 'Presenças',
        subtitulo: 'Marcar presenças de sábado e domingo',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PresencasScreen())),
      ),
      CartaoMenu(
        icon: Icons.fact_check_outlined,
        titulo: 'Pauta',
        subtitulo: 'Situação dos catequisandos por fase (permanece/progride)',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PautaScreen())),
      ),
    ];

    final itensComunidade = <Widget>[
      CartaoMenu(
        icon: Icons.account_tree_outlined,
        titulo: 'Ministérios',
        subtitulo: 'Organograma: ministérios e coordenadores',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MinisteriosScreen())),
      ),
      CartaoMenu(
        icon: Icons.groups_2_outlined,
        titulo: 'Sectores',
        subtitulo: 'Acolhimento, Acólitos e outros encontros',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SectoresScreen())),
      ),
    ];

    final itensGestao = <Widget>[
      if (isAdmin)
        CartaoMenu(
          icon: Icons.admin_panel_settings_outlined,
          titulo: 'Gerir catequistas',
          subtitulo: 'Promover ou remover permissões de administrador',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GerirCatequistasScreen())),
        ),
      if (isAdmin)
        CartaoMenu(
          icon: Icons.bar_chart_outlined,
          titulo: 'Relatórios',
          subtitulo: 'Estatísticas de catequisandos por fase e género',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RelatoriosScreen())),
        ),
      if (isAdmin)
        CartaoMenu(
          icon: Icons.history_outlined,
          titulo: 'Registo de Atividade',
          subtitulo: 'Quem criou, editou e apagou o quê (auditoria)',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuditoriaScreen())),
        ),
      CartaoMenu(
        icon: Icons.app_registration_outlined,
        titulo: 'Inscrições e Renovações',
        subtitulo: 'Registar pagamentos de inscrição, renovação e ficha',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InscricoesScreen())),
      ),
      CartaoMenu(
        icon: Icons.calendar_month_outlined,
        titulo: 'Ano Letivo',
        subtitulo: 'Ver o ano corrente e avançar para o próximo',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConfiguracaoScreen())),
      ),
    ];

    // --- Grelha da tela principal: categorias + itens que não se agrupam ---
    final itensGrelha = <Widget>[
      CartaoGrelha(
        icon: Icons.public,
        titulo: 'Ver página pública',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PublicoScreen())),
      ),
      CartaoGrelha(
        icon: Icons.stairs_outlined,
        titulo: 'Fases catequéticas',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FasesScreen())),
      ),
      if (temAcessoCompleto)
        CartaoGrelha(
          icon: Icons.groups_outlined,
          titulo: 'Catequese',
          destaque: true,
          onTap: () => abrirCategoria('Catequese', itensCatequese),
        ),
      if (temAcessoCompleto)
        CartaoGrelha(
          icon: Icons.family_restroom_outlined,
          titulo: 'Pessoas',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PessoasScreen())),
        ),
      if (temAcessoCompleto)
        CartaoGrelha(
          icon: Icons.account_tree_outlined,
          titulo: 'Comunidade',
          destaque: true,
          onTap: () => abrirCategoria('Comunidade', itensComunidade),
        ),
      if (temAcessoCompleto)
        CartaoGrelha(
          icon: Icons.self_improvement_outlined,
          titulo: 'Retiros',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RetirosScreen())),
        ),
      if (temAcessoCompleto)
        CartaoGrelha(
          icon: Icons.event_outlined,
          titulo: 'Eventos da Comunidade',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventosScreen())),
        ),
      if (temAcessoCompleto)
        CartaoGrelha(
          icon: Icons.photo_library_outlined,
          titulo: 'Fotos do Carrossel',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FotosScreen())),
        ),
      if (temAcessoCompleto)
        CartaoGrelha(
          icon: Icons.point_of_sale_outlined,
          titulo: 'Caixa da Catequese',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CaixaScreen())),
        ),
      if (temAcessoCompleto || eResponsavelDeSector)
        CartaoGrelha(
          icon: Icons.inventory_2_outlined,
          titulo: 'Inventário',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InventarioScreen())),
        ),
      if (temAcessoCompleto)
        CartaoGrelha(
          icon: Icons.settings_outlined,
          titulo: 'Gestão',
          destaque: true,
          onTap: () => abrirCategoria('Gestão', itensGestao),
        ),
    ];

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
            constraints: BoxConstraints(maxWidth: isWide ? 700 : double.infinity),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo(a), ${catequista?.nome ?? ''}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
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
                  GridView.count(
                    crossAxisCount: isWide ? 4 : 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.95,
                    children: itensGrelha,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
