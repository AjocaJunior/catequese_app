import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Ecrã temporário do Módulo 1: apenas confirma que o Flutter
/// consegue falar com o backend e com o MongoDB.
/// Será substituído pelo ecrã de login no Módulo 2.
class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  String _status = 'A verificar ligação...';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.checkHealth();
      setState(() {
        _status = 'API: ${result['api']}\nMongoDB: ${result['mongodb']}';
      });
    } catch (e) {
      setState(() => _status = 'Erro ao ligar à API: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestão Catequética')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 480 : double.infinity),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.church, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Módulo 1 — Infraestrutura',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (_loading) const CircularProgressIndicator(),
                if (!_loading)
                  Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _checkConnection,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Verificar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
