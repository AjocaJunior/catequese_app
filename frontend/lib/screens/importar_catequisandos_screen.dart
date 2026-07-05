import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catequisando.dart';
import '../models/fase.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/catequisando_service.dart';
import '../services/fase_service.dart';

class ImportarCatequisandosScreen extends StatefulWidget {
  const ImportarCatequisandosScreen({super.key});

  @override
  State<ImportarCatequisandosScreen> createState() => _ImportarCatequisandosScreenState();
}

class _ImportarCatequisandosScreenState extends State<ImportarCatequisandosScreen> {
  List<Fase> _fases = [];
  String? _faseId;
  bool _carregandoFases = true;

  PlatformFile? _ficheiroEscolhido;
  bool _importando = false;
  ImportacaoResultado? _resultado;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregarFases();
  }

  Future<void> _carregarFases() async {
    final token = context.read<AuthService>().token;
    try {
      final fases = await FaseService(token).listar();
      if (!mounted) return;
      setState(() {
        _fases = fases;
        _faseId = fases.isNotEmpty ? fases.first.id : null;
      });
    } catch (_) {
      // ecrã continua utilizável; o dropdown fica vazio
    } finally {
      if (mounted) setState(() => _carregandoFases = false);
    }
  }

  Future<void> _escolherFicheiro() async {
    final resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true, // necessário para obter os bytes diretamente (funciona também na Web)
    );
    if (resultado != null && resultado.files.isNotEmpty) {
      setState(() {
        _ficheiroEscolhido = resultado.files.first;
        _resultado = null;
        _erro = null;
      });
    }
  }

  Future<void> _importar() async {
    if (_faseId == null || _ficheiroEscolhido == null || _ficheiroEscolhido!.bytes == null) return;

    setState(() {
      _importando = true;
      _erro = null;
      _resultado = null;
    });

    final token = context.read<AuthService>().token;
    final service = CatequisandoService(token);

    try {
      final resultado = await service.importar(
        faseId: _faseId!,
        bytes: _ficheiroEscolhido!.bytes!,
        nomeFicheiro: _ficheiroEscolhido!.name,
      );
      if (!mounted) return;
      setState(() => _resultado = resultado);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao importar ficheiro');
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Importar catequisandos')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 600 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'O ficheiro deve ser .xlsx com as colunas, por esta ordem: '
                  'Nome, Data de Nascimento, Telefone (contacto do encarregado), '
                  'Grau de parentesco. Só o Nome é obrigatório.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),

                _carregandoFases
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _faseId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Fase de destino',
                          border: OutlineInputBorder(),
                        ),
                        items: _fases
                            .map((f) => DropdownMenuItem(
                                  value: f.id,
                                  child: Text(f.nome, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _faseId = v),
                      ),
                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: _escolherFicheiro,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(_ficheiroEscolhido?.name ?? 'Escolher ficheiro .xlsx'),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: (_faseId != null && _ficheiroEscolhido != null && !_importando)
                        ? _importar
                        : null,
                    child: _importando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Importar'),
                  ),
                ),

                if (_erro != null) ...[
                  const SizedBox(height: 16),
                  Text(_erro!, style: const TextStyle(color: Colors.red)),
                ],

                if (_resultado != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_resultado!.criados} de ${_resultado!.totalLinhas} catequisando(s) importado(s) com sucesso.',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_resultado!.erros.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('${_resultado!.erros.length} linha(s) com problemas:',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            ..._resultado!.erros.map(
                              (e) => Text('• Linha ${e.linha}: ${e.motivo}'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Concluído'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
