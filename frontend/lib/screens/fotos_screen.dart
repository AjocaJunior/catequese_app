import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/foto.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/foto_service.dart';

class FotosScreen extends StatefulWidget {
  const FotosScreen({super.key});

  @override
  State<FotosScreen> createState() => _FotosScreenState();
}

class _FotosScreenState extends State<FotosScreen> {
  late FotoService _service;
  bool _isAdmin = false;
  List<Foto> _fotos = [];
  bool _loading = true;
  bool _enviando = false;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    _service = FotoService(auth.token);
    _isAdmin = auth.catequista?.isAdmin ?? false;
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final fotos = await _service.listar();
      if (!mounted) return;
      setState(() => _fotos = fotos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar fotos');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _escolherEEnviar() async {
    final picker = ImagePicker();
    final ficheiro = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (ficheiro == null) return;

    final tituloController = TextEditingController();
    final legenda = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Legenda (opcional)'),
        content: TextField(
          controller: tituloController,
          decoration: const InputDecoration(hintText: 'Ex: Festa da Criança 2026'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, tituloController.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (legenda == null) return; // cancelou

    setState(() => _enviando = true);
    try {
      final bytes = await ficheiro.readAsBytes();
      await _service.enviar(bytes: bytes, nomeFicheiro: ficheiro.name, titulo: legenda.isEmpty ? null : legenda);
      _carregar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao enviar foto';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _apagar(Foto foto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar foto'),
        content: Text('Tens a certeza que queres apagar "${foto.titulo ?? 'esta foto'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _service.apagar(foto.id);
      _carregar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao apagar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fotos do Carrossel')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: _fotos.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(
                                child: Text('Ainda não há fotos.\nToca em + para adicionar a primeira.',
                                    textAlign: TextAlign.center)),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                          itemCount: _fotos.length,
                          itemBuilder: (context, i) {
                            final foto = _fotos[i];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    foto.urlImagem,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) => Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                                  if (foto.titulo != null)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        color: Colors.black.withValues(alpha: 0.55),
                                        child: Text(
                                          foto.titulo!,
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  if (_isAdmin)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.white),
                                        style: IconButton.styleFrom(backgroundColor: Colors.black45),
                                        onPressed: () => _apagar(foto),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enviando ? null : _escolherEEnviar,
        tooltip: 'Adicionar foto',
        child: _enviando
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }
}
