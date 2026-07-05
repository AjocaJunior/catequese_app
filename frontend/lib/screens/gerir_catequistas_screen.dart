import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catequista.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/catequista_service.dart';

class GerirCatequistasScreen extends StatefulWidget {
  const GerirCatequistasScreen({super.key});

  @override
  State<GerirCatequistasScreen> createState() => _GerirCatequistasScreenState();
}

class _GerirCatequistasScreenState extends State<GerirCatequistasScreen> {
  late CatequistaService _service;
  String _meuId = '';
  List<Catequista> _catequistas = [];
  bool _loading = true;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = CatequistaService(auth.token);
    _meuId = auth.catequista?.id ?? '';
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final lista = await _service.listar();
      if (!mounted) return;
      setState(() => _catequistas = lista);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar catequistas');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _alternarAdmin(Catequista c, bool novoValor) async {
    try {
      await _service.alterarAdmin(c.id, novoValor);
      _carregar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao alterar permissão';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerir catequistas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    itemCount: _catequistas.length,
                    itemBuilder: (context, i) {
                      final c = _catequistas[i];
                      final souEu = c.id == _meuId;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(c.isAdmin ? Icons.shield_outlined : Icons.person_outline),
                        ),
                        title: Text(c.nome + (souEu ? ' (tu)' : '')),
                        subtitle: Text(c.email),
                        trailing: Switch(
                          value: c.isAdmin,
                          onChanged: souEu ? null : (v) => _alternarAdmin(c, v),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
