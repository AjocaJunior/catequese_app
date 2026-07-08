import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catequisando.dart';
import '../models/sector.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/inventario_service.dart';
import '../services/sector_service.dart';

class ImportarInventarioScreen extends StatefulWidget {
  const ImportarInventarioScreen({super.key});

  @override
  State<ImportarInventarioScreen> createState() => _ImportarInventarioScreenState();
}

class _ImportarInventarioScreenState extends State<ImportarInventarioScreen> {
  bool _isAdmin = false;
  List<Sector> _sectoresDisponiveis = [];
  String? _sectorId;
  bool _carregandoSectores = true;

  PlatformFile? _ficheiroEscolhido;
  bool _importando = false;
  ImportacaoResultado? _resultado;
  String? _erro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregarSectores();
  }

  Future<void> _carregarSectores() async {
    final auth = context.read<AuthService>();
    _isAdmin = auth.catequista?.isAdmin ?? false;
    final meusSectores = auth.catequista?.sectoresResponsavel ?? [];

    try {
      final todos = await SectorService(auth.token).listar();
      if (!mounted) return;
      setState(() {
        _sectoresDisponiveis =
            _isAdmin ? todos : todos.where((s) => meusSectores.any((m) => m.id == s.id)).toList();
        _sectorId = _isAdmin ? null : (_sectoresDisponiveis.isNotEmpty ? _sectoresDisponiveis.first.id : null);
      });
    } catch (_) {
      // ecrã continua utilizável; a escolha de sector fica vazia
    } finally {
      if (mounted) setState(() => _carregandoSectores = false);
    }
  }

  Future<void> _escolherFicheiro() async {
    final resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
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
    if (_ficheiroEscolhido == null || _ficheiroEscolhido!.bytes == null) return;

    setState(() {
      _importando = true;
      _erro = null;
      _resultado = null;
    });

    final token = context.read<AuthService>().token;
    final service = InventarioService(token);

    try {
      final resultado = await service.importar(
        sectorId: _sectorId,
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
      appBar: AppBar(title: const Text('Importar inventário')),
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
                  'Nome do Item, Imagem, Descrição, Categoria, Quantidade, Localização, Estado, Observação. '
                  'Só o Nome do Item é obrigatório.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                _carregandoSectores
                    ? const Center(child: CircularProgressIndicator())
                    : _isAdmin
                        ? DropdownButtonFormField<String?>(
                            value: _sectorId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Sector de destino',
                              helperText: 'Sem sector = inventário geral da catequese',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Geral (catequese)')),
                              ..._sectoresDisponiveis.map((s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.nome, overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _sectorId = v),
                          )
                        : _sectoresDisponiveis.length > 1
                            ? DropdownButtonFormField<String?>(
                                value: _sectorId,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Sector', border: OutlineInputBorder()),
                                items: _sectoresDisponiveis
                                    .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nome)))
                                    .toList(),
                                onChanged: (v) => setState(() => _sectorId = v),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Sector: ${_sectoresDisponiveis.isNotEmpty ? _sectoresDisponiveis.first.nome : "—"}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
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
                    onPressed: (_ficheiroEscolhido != null && !_importando) ? _importar : null,
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
                            '${_resultado!.criados} de ${_resultado!.totalLinhas} item(ns) importado(s) com sucesso.',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_resultado!.erros.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('${_resultado!.erros.length} linha(s) com problemas:',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            ..._resultado!.erros.map((e) => Text('• Linha ${e.linha}: ${e.motivo}')),
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
