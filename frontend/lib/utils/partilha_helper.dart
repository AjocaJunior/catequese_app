import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Partilha um PDF (em memória, sem precisar de gravar em disco — funciona
/// tanto em telemóvel como na Web) através do menu nativo de partilha do
/// dispositivo, onde o utilizador escolhe a app (WhatsApp, email, etc.).
Future<void> partilharPdf(
  BuildContext context,
  Uint8List bytes, {
  required String nomeFicheiro,
  String? legenda,
}) async {
  try {
    final ficheiro = XFile.fromData(bytes, mimeType: 'application/pdf', name: nomeFicheiro);
    await Share.shareXFiles([ficheiro], text: legenda);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível partilhar. Tenta imprimir e partilhar a partir daí.')),
      );
    }
  }
}
