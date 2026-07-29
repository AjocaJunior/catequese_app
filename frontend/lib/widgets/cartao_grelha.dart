import 'package:flutter/material.dart';

/// Cartão compacto para a grelha da tela principal — ícone grande + rótulo
/// curto. Usa [destaque] para as categorias (fundo com cor de destaque),
/// deixando os itens individuais mais neutros.
class CartaoGrelha extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final VoidCallback onTap;
  final bool destaque;

  const CartaoGrelha({
    super.key,
    required this.icon,
    required this.titulo,
    required this.onTap,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 0,
      color: destaque ? cor.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: destaque ? cor.withValues(alpha: 0.35) : Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 30, color: destaque ? cor : Colors.black87),
              const SizedBox(height: 8),
              Text(
                titulo,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: destaque ? cor : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
