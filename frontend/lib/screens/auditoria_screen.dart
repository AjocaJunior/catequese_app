import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/auditoria.dart';
import '../services/api_client.dart';
import '../services/auditoria_service.dart';
import '../services/auth_service.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  late AuditoriaService _service;
  List<RegistoAuditoria> _registos = [];
  List<String> _entidades = [];
  String? _filtroEntidade;
  bool _loading = true;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = AuditoriaService(auth.token);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final entidades = await _service.listarEntidades();
      final registos = await _service.listar(entidade: _filtroEntidade);
      if (!mounted) return;
      setState(() {
        _entidades = entidades;
        _registos = registos;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar o log de auditoria');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatarData(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  IconData _iconePara(AcaoAuditoria acao) {
    switch (acao) {
      case AcaoAuditoria.criar:
        return Icons.add_circle_outline;
      case AcaoAuditoria.atualizar:
        return Icons.edit_outlined;
      case AcaoAuditoria.apagar:
        return Icons.delete_outline;
    }
  }

  Color _corPara(AcaoAuditoria acao) {
    switch (acao) {
      case AcaoAuditoria.criar:
        return Colors.green;
      case AcaoAuditoria.atualizar:
        return Colors.blue;
      case AcaoAuditoria.apagar:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Registo de Atividade')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String?>(
                  value: _filtroEntidade,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por tipo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tudo')),
                    ..._entidades.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                  ],
                  onChanged: (v) {
                    setState(() => _filtroEntidade = v);
                    _carregar();
                  },
                ),
              ),
              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_erro != null)
                Expanded(child: Center(child: Text(_erro!)))
              else if (_registos.isEmpty)
                const Expanded(child: Center(child: Text('Ainda não há atividade registada.')))
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _carregar,
                    child: ListView.builder(
                      itemCount: _registos.length,
                      itemBuilder: (context, i) {
                        final r = _registos[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _corPara(r.acao).withValues(alpha: 0.15),
                            child: Icon(_iconePara(r.acao), color: _corPara(r.acao), size: 20),
                          ),
                          title: Text(r.resumo),
                          subtitle: Text('${r.catequistaNome} · ${_formatarData(r.data)} · ${r.entidade}'),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
