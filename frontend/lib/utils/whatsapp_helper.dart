import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Normaliza um número de telefone moçambicano para o formato internacional
/// (+258...), aceitando os vários formatos que já podem estar guardados
/// (com espaços, com ou sem +258, com 0 inicial, etc.). Devolve null se não
/// conseguir reconhecer nada de válido.
String? normalizarTelefoneMz(String? numero) {
  if (numero == null || numero.trim().isEmpty) return null;

  var limpo = numero.replaceAll(RegExp(r'[^\d+]'), '');
  if (limpo.isEmpty) return null;

  if (limpo.startsWith('+258')) return limpo;
  if (limpo.startsWith('258')) return '+$limpo';
  if (limpo.startsWith('0')) limpo = limpo.substring(1);
  if (limpo.length == 9) return '+258$limpo';
  return limpo.startsWith('+') ? limpo : '+$limpo';
}

/// Mensagem inicial sugerida para contactar o encarregado/padrinho/madrinha
/// sobre um catequisando — o catequista continua a partir daqui antes de
/// enviar.
String mensagemPadraoCatequista(String nomeCatequisando) {
  return 'Olá, espero que esteja bem de saúde. Aqui Catequista da Comunidade Santa Ana de Mastrong. '
      'Sobre $nomeCatequisando: ';
}

/// Abre o WhatsApp (app instalada, ou WhatsApp Web se não houver) numa
/// conversa com o número indicado, já com uma mensagem pré-escrita —
/// o catequista só precisa de rever e carregar em enviar.
Future<void> abrirWhatsApp(
  BuildContext context, {
  required String? telefone,
  String mensagem = '',
}) async {
  final normalizado = normalizarTelefoneMz(telefone);
  if (normalizado == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não há contacto registado para esta pessoa')),
    );
    return;
  }

  final numeroSemMais = normalizado.replaceFirst('+', '');
  final uri = Uri.parse('https://wa.me/$numeroSemMais?text=${Uri.encodeComponent(mensagem)}');

  try {
    final aberto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!aberto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
      );
    }
  }
}

/// Ícone de ação para enviar uma mensagem de WhatsApp — mostra-se só se
/// houver um contacto registado.
class BotaoWhatsApp extends StatelessWidget {
  final String? telefone;
  final String mensagem;

  const BotaoWhatsApp({super.key, required this.telefone, this.mensagem = ''});

  @override
  Widget build(BuildContext context) {
    if (telefone == null || telefone!.trim().isEmpty) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.chat_outlined, color: Colors.green, size: 20),
      tooltip: 'Enviar WhatsApp',
      onPressed: () => abrirWhatsApp(context, telefone: telefone, mensagem: mensagem),
    );
  }
}
