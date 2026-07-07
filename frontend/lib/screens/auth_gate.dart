import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'publico_screen.dart';

/// Ponto de entrada da navegação: no arranque tenta restaurar a sessão
/// guardada. Com sessão válida mostra o HomeScreen; sem sessão, mostra a
/// área pública (PublicoScreen), que por sua vez tem um botão para aceder
/// ao login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().tryAutoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return auth.isAuthenticated ? const HomeScreen() : const PublicoScreen();
  }
}
