import 'package:flutter/material.dart';

import '../widgets/cartao_menu.dart';

/// Ecrã partilhado para as categorias da tela principal (Catequese,
/// Comunidade, Gestão) — recebe o título e os cartões já construídos.
class CategoriaScreen extends StatelessWidget {
  final String titulo;
  final List<Widget> itens;

  const CategoriaScreen({super.key, required this.titulo, required this.itens});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    final itensEspacados = <Widget>[];
    for (var i = 0; i < itens.length; i++) {
      itensEspacados.add(itens[i]);
      if (i < itens.length - 1) itensEspacados.add(const SizedBox(height: 12));
    }

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 640 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: itensEspacados,
            ),
          ),
        ),
      ),
    );
  }
}
