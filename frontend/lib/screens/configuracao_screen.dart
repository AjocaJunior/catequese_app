import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/configuracao.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/configuracao_service.dart';

class ConfiguracaoScreen extends StatefulWidget {
  const ConfiguracaoScreen({super.key});

  @override
  State<ConfiguracaoScreen> createState() => _ConfiguracaoScreenState();
}

class _ConfiguracaoScreenState extends State<ConfiguracaoScreen> {
  late ConfiguracaoService _service;
  bool _isAdmin = false;
  Configuracao? _configuracao;
  bool _loading = true;
  bool _avancando = false;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = ConfiguracaoService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final config = await _service.obter();
      if (!mounted) return;
      setState(() => _configuracao = config);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _avancarAno() async {
    final anoAtual = _configuracao!.anoLetivoAtual;
    final novoAno = anoAtual + 1;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avançar ano letivo'),
        content: Text(
          'Vais avançar de $anoAtual para $novoAno.\n\n'
          'As atribuições de catequistas às fases continuam iguais no novo ano '
          '(podes ajustar depois em "Catequistas da fase") — o ano de $anoAtual '
          'fica registado e já não é alterado.\n\n'
          'Os catequisandos não são afetados diretamente: a matrícula de cada um '
          'em $novoAno fica registada quando lançares a respetiva inscrição/renovação.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Avançar para $novoAno'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _avancando = true);
    try {
      final config = await _service.avancarAnoLetivo(novoAno);
      if (!mounted) return;
      setState(() => _configuracao = config);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ano letivo avançado para $novoAno')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao avançar o ano letivo';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _avancando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Ano Letivo')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 480 : double.infinity),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.calendar_month_outlined, size: 40, color: Colors.blueGrey),
                                  const SizedBox(height: 12),
                                  const Text('Ano letivo corrente', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_configuracao?.anoLetivoAtual ?? '—'}',
                                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_isAdmin) ...[
                            const Text(
                              'Ao avançar o ano, os registos do ano corrente (inscrições, renovações, '
                              'atribuições de catequistas) ficam guardados e não são mais alterados.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: _avancando ? null : _avancarAno,
                                icon: _avancando
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.arrow_forward),
                                label: Text(_avancando
                                    ? 'A avançar...'
                                    : 'Avançar para ${(_configuracao?.anoLetivoAtual ?? 0) + 1}'),
                              ),
                            ),
                          ] else
                            const Text(
                              'Só administradores podem avançar o ano letivo.',
                              style: TextStyle(color: Colors.black54),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
