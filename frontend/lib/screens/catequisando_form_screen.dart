import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catequisando.dart';
import '../models/fase.dart';
import '../models/pessoa.dart';
import '../models/sector.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/catequisando_service.dart';
import '../services/pessoa_service.dart';
import '../services/sector_service.dart';
import '../widgets/pessoa_picker_field.dart';

class CatequisandoFormScreen extends StatefulWidget {
  final Catequisando? catequisando;
  final List<Fase> fases;

  const CatequisandoFormScreen({super.key, this.catequisando, required this.fases});

  @override
  State<CatequisandoFormScreen> createState() => _CatequisandoFormScreenState();
}

class _CatequisandoFormScreenState extends State<CatequisandoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _naturalDeController;
  late TextEditingController _estadoCivilController;
  late TextEditingController _profissaoController;
  late TextEditingController _residenciaController;
  late TextEditingController _fichaAnoController;
  late TextEditingController _fichaNumeroController;
  late TextEditingController _encarregadoNomeController;
  late TextEditingController _encarregadoContactoController;
  late TextEditingController _encarregadoParentescoController;
  late TextEditingController _avoPaternoController;
  late TextEditingController _avoPaternaController;
  late TextEditingController _avoMaternoController;
  late TextEditingController _avoMaternaController;
  late TextEditingController _baptismoLocalController;
  late TextEditingController _baptismoCertidaoController;
  late TextEditingController _observacoesController;
  late TextEditingController _nucleoComunidadeController;
  late TextEditingController _baptismoArquidioceseController;
  late TextEditingController _baptismoLivroController;
  late TextEditingController _baptismoNumeroRegistoController;
  late TextEditingController _baptismoPaginaController;
  late TextEditingController _primeiraComunhaoHoraController;
  late TextEditingController _primeiraComunhaoLivroController;
  late TextEditingController _primeiraComunhaoNumeroRegistoController;
  late TextEditingController _primeiraComunhaoPaginaController;
  late TextEditingController _crismaHoraController;
  late TextEditingController _crismaLivroController;
  late TextEditingController _crismaNumeroRegistoController;
  late TextEditingController _crismaPaginaController;

  String? _faseId;
  String? _sectorId;
  String? _nucleoId;
  Genero? _genero;
  DateTime? _dataNascimento;
  DateTime? _eleicaoData;
  DateTime? _escrutinio1Data;
  DateTime? _escrutinio2Data;
  DateTime? _escrutinio3Data;
  DateTime? _baptismoData;
  DateTime? _primeiraComunhaoData;
  DateTime? _crismaData;

  List<Sector> _sectoresDisponiveis = [];
  List<Pessoa> _pessoas = [];
  Pessoa? _pai;
  Pessoa? _mae;
  Pessoa? _padrinho;
  Pessoa? _madrinha;

  bool _carregando = true;
  bool _submitting = false;
  String? _erro;

  bool get _editando => widget.catequisando != null;

  @override
  void initState() {
    super.initState();
    final c = widget.catequisando;
    _nomeController = TextEditingController(text: c?.nome ?? '');
    _naturalDeController = TextEditingController(text: c?.naturalDe ?? '');
    _estadoCivilController = TextEditingController(text: c?.estadoCivil ?? '');
    _profissaoController = TextEditingController(text: c?.profissao ?? '');
    _residenciaController = TextEditingController(text: c?.residencia ?? '');
    _fichaAnoController = TextEditingController(text: c?.fichaAno?.toString() ?? '');
    _fichaNumeroController = TextEditingController(text: c?.fichaNumero ?? '');
    _encarregadoNomeController = TextEditingController(text: c?.encarregadoNome ?? '');
    _encarregadoContactoController = TextEditingController(text: c?.encarregadoContacto ?? '');
    _encarregadoParentescoController = TextEditingController(text: c?.encarregadoParentesco ?? '');
    _avoPaternoController = TextEditingController(text: c?.avoPaternoNome ?? '');
    _avoPaternaController = TextEditingController(text: c?.avoPaternaNome ?? '');
    _avoMaternoController = TextEditingController(text: c?.avoMaternoNome ?? '');
    _avoMaternaController = TextEditingController(text: c?.avoMaternaNome ?? '');
    _baptismoLocalController = TextEditingController(text: c?.baptismoLocal ?? '');
    _baptismoCertidaoController = TextEditingController(text: c?.baptismoCertidaoUrl ?? '');
    _observacoesController = TextEditingController(text: c?.observacoes ?? '');
    _nucleoComunidadeController = TextEditingController(text: c?.nucleoComunidade ?? '');
    _baptismoArquidioceseController = TextEditingController(text: c?.baptismoArquidiocese ?? '');
    _baptismoLivroController = TextEditingController(text: c?.baptismoLivro ?? '');
    _baptismoNumeroRegistoController = TextEditingController(text: c?.baptismoNumeroRegisto ?? '');
    _baptismoPaginaController = TextEditingController(text: c?.baptismoPagina ?? '');
    _primeiraComunhaoHoraController = TextEditingController(text: c?.primeiraComunhaoHora ?? '');
    _primeiraComunhaoLivroController = TextEditingController(text: c?.primeiraComunhaoLivro ?? '');
    _primeiraComunhaoNumeroRegistoController = TextEditingController(text: c?.primeiraComunhaoNumeroRegisto ?? '');
    _primeiraComunhaoPaginaController = TextEditingController(text: c?.primeiraComunhaoPagina ?? '');
    _crismaHoraController = TextEditingController(text: c?.crismaHora ?? '');
    _crismaLivroController = TextEditingController(text: c?.crismaLivro ?? '');
    _crismaNumeroRegistoController = TextEditingController(text: c?.crismaNumeroRegisto ?? '');
    _crismaPaginaController = TextEditingController(text: c?.crismaPagina ?? '');

    _faseId = c?.faseId ?? (widget.fases.isNotEmpty ? widget.fases.first.id : null);
    _sectorId = c?.sectorId;
    _nucleoId = c?.nucleoId;
    _genero = c?.genero;
    _dataNascimento = c?.dataNascimento;
    _eleicaoData = c?.eleicaoData;
    _escrutinio1Data = c?.escrutinio1Data;
    _escrutinio2Data = c?.escrutinio2Data;
    _escrutinio3Data = c?.escrutinio3Data;
    _baptismoData = c?.baptismoData;
    _primeiraComunhaoData = c?.primeiraComunhaoData;
    _crismaData = c?.crismaData;
    _pai = c?.pai;
    _mae = c?.mae;
    _padrinho = c?.padrinho;
    _madrinha = c?.madrinha;

    _carregarListas();
  }

  Future<void> _carregarListas() async {
    final auth = context.read<AuthService>();
    try {
      final sectores = await SectorService(auth.token).listar();
      final pessoas = await PessoaService(auth.token).listar();
      if (!mounted) return;
      setState(() {
        _sectoresDisponiveis = sectores;
        _pessoas = pessoas;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException ? e.message : 'Erro ao carregar dados');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _naturalDeController.dispose();
    _estadoCivilController.dispose();
    _profissaoController.dispose();
    _residenciaController.dispose();
    _fichaAnoController.dispose();
    _fichaNumeroController.dispose();
    _encarregadoNomeController.dispose();
    _encarregadoContactoController.dispose();
    _encarregadoParentescoController.dispose();
    _avoPaternoController.dispose();
    _avoPaternaController.dispose();
    _avoMaternoController.dispose();
    _avoMaternaController.dispose();
    _baptismoLocalController.dispose();
    _baptismoCertidaoController.dispose();
    _observacoesController.dispose();
    _nucleoComunidadeController.dispose();
    _baptismoArquidioceseController.dispose();
    _baptismoLivroController.dispose();
    _baptismoNumeroRegistoController.dispose();
    _baptismoPaginaController.dispose();
    _primeiraComunhaoHoraController.dispose();
    _primeiraComunhaoLivroController.dispose();
    _primeiraComunhaoNumeroRegistoController.dispose();
    _primeiraComunhaoPaginaController.dispose();
    _crismaHoraController.dispose();
    _crismaLivroController.dispose();
    _crismaNumeroRegistoController.dispose();
    _crismaPaginaController.dispose();
    super.dispose();
  }

  Future<DateTime?> _escolherData(DateTime? atual) {
    return showDatePicker(
      context: context,
      initialDate: atual ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  String _formatarData(DateTime? d) =>
      d == null ? 'Não definida' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _campoData(String rotulo, DateTime? valor, ValueChanged<DateTime?> onChanged) {
    return InkWell(
      onTap: () async {
        final escolhida = await _escolherData(valor);
        if (escolhida != null) onChanged(escolhida);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: rotulo,
          border: const OutlineInputBorder(),
          suffixIcon: valor != null
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => onChanged(null))
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(_formatarData(valor)),
      ),
    );
  }

  Widget _tituloSeccao(String texto) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(texto, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_faseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleciona a fase')));
      return;
    }

    setState(() => _submitting = true);

    final dados = <String, dynamic>{
      'nome': _nomeController.text.trim(),
      'fase_id': _faseId,
      if (_sectorId != null) 'sector_id': _sectorId,
      if (_nucleoId != null) 'nucleo_id': _nucleoId,
      'nucleo_comunidade': _nucleoComunidadeController.text.trim(),
      if (_genero != null) 'genero': _genero!.valor,
      if (_dataNascimento != null)
        'data_nascimento':
            '${_dataNascimento!.year.toString().padLeft(4, '0')}-${_dataNascimento!.month.toString().padLeft(2, '0')}-${_dataNascimento!.day.toString().padLeft(2, '0')}',
      'natural_de': _naturalDeController.text.trim(),
      'estado_civil': _estadoCivilController.text.trim(),
      'profissao': _profissaoController.text.trim(),
      'residencia': _residenciaController.text.trim(),
      'encarregado_nome': _encarregadoNomeController.text.trim(),
      'encarregado_contacto': _encarregadoContactoController.text.trim(),
      'encarregado_parentesco': _encarregadoParentescoController.text.trim(),
      'observacoes': _observacoesController.text.trim(),
      if (_fichaAnoController.text.trim().isNotEmpty) 'ficha_ano': int.tryParse(_fichaAnoController.text.trim()),
      'ficha_numero': _fichaNumeroController.text.trim(),
      if (_pai != null) 'pai_id': _pai!.id,
      if (_mae != null) 'mae_id': _mae!.id,
      'avo_paterno_nome': _avoPaternoController.text.trim(),
      'avo_paterna_nome': _avoPaternaController.text.trim(),
      'avo_materno_nome': _avoMaternoController.text.trim(),
      'avo_materna_nome': _avoMaternaController.text.trim(),
      if (_padrinho != null) 'padrinho_id': _padrinho!.id,
      if (_madrinha != null) 'madrinha_id': _madrinha!.id,
      if (_eleicaoData != null) 'eleicao_data': _isoData(_eleicaoData!),
      if (_escrutinio1Data != null) 'escrutinio_1_data': _isoData(_escrutinio1Data!),
      if (_escrutinio2Data != null) 'escrutinio_2_data': _isoData(_escrutinio2Data!),
      if (_escrutinio3Data != null) 'escrutinio_3_data': _isoData(_escrutinio3Data!),
      'baptismo_local': _baptismoLocalController.text.trim(),
      if (_baptismoData != null) 'baptismo_data': _isoData(_baptismoData!),
      'baptismo_certidao_url': _baptismoCertidaoController.text.trim(),
      'baptismo_arquidiocese': _baptismoArquidioceseController.text.trim(),
      'baptismo_livro': _baptismoLivroController.text.trim(),
      'baptismo_numero_registo': _baptismoNumeroRegistoController.text.trim(),
      'baptismo_pagina': _baptismoPaginaController.text.trim(),
      if (_primeiraComunhaoData != null) 'primeira_comunhao_data': _isoData(_primeiraComunhaoData!),
      'primeira_comunhao_hora': _primeiraComunhaoHoraController.text.trim(),
      'primeira_comunhao_livro': _primeiraComunhaoLivroController.text.trim(),
      'primeira_comunhao_numero_registo': _primeiraComunhaoNumeroRegistoController.text.trim(),
      'primeira_comunhao_pagina': _primeiraComunhaoPaginaController.text.trim(),
      if (_crismaData != null) 'crisma_data': _isoData(_crismaData!),
      'crisma_hora': _crismaHoraController.text.trim(),
      'crisma_livro': _crismaLivroController.text.trim(),
      'crisma_numero_registo': _crismaNumeroRegistoController.text.trim(),
      'crisma_pagina': _crismaPaginaController.text.trim(),
    };

    final auth = context.read<AuthService>();
    final service = CatequisandoService(auth.token);

    try {
      if (_editando) {
        await service.atualizar(widget.catequisando!.id, dados);
      } else {
        await service.criar(dados);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao guardar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _isoData(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar Ficha' : 'Nova Ficha do Catecúmeno')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 640 : double.infinity),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_erro != null) ...[
                        Text(_erro!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                      ],
                      _tituloSeccao('DADOS DO CATEQUISANDO'),
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(labelText: 'Nome completo', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Nome demasiado curto' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Genero?>(
                        value: _genero,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Género (opcional)', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Não informado')),
                          ...Genero.values.map((g) => DropdownMenuItem(value: g, child: Text(g.rotulo))),
                        ],
                        onChanged: (v) => setState(() => _genero = v),
                      ),
                      const SizedBox(height: 16),
                      _campoData('Data de nascimento', _dataNascimento, (d) => setState(() => _dataNascimento = d)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _naturalDeController,
                        decoration: const InputDecoration(labelText: 'Natural de (opcional)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _estadoCivilController,
                        decoration: const InputDecoration(labelText: 'Estado civil (opcional)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _profissaoController,
                        decoration: const InputDecoration(labelText: 'Profissão (opcional)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _residenciaController,
                        decoration: const InputDecoration(labelText: 'Residência (opcional)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _faseId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Fase', border: OutlineInputBorder()),
                        items: widget.fases
                            .map((f) => DropdownMenuItem(value: f.id, child: Text(f.nome, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) => setState(() => _faseId = v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        value: _sectorId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Sector pastoral (opcional)', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Nenhum')),
                          ..._sectoresDisponiveis.map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.nome, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) => setState(() => _sectorId = v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        value: _nucleoId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Núcleo dos pais (opcional)',
                          helperText: 'Ministério da Animação dos Núcleos',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Nenhum')),
                          ..._sectoresDisponiveis.map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.nome, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) => setState(() => _nucleoId = v),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nucleoComunidadeController,
                        decoration: const InputDecoration(
                          labelText: 'Comunidade do núcleo (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fichaAnoController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Ano da ficha (opcional)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _fichaNumeroController,
                              decoration: const InputDecoration(labelText: 'Nº da ficha (opcional)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),

                      _tituloSeccao('ENCARREGADO DE EDUCAÇÃO (contacto rápido)'),
                      TextFormField(
                        controller: _encarregadoNomeController,
                        decoration: const InputDecoration(labelText: 'Nome (opcional)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _encarregadoContactoController,
                        decoration: const InputDecoration(labelText: 'Contacto (opcional)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _encarregadoParentescoController,
                        decoration: const InputDecoration(labelText: 'Parentesco (opcional)', border: OutlineInputBorder()),
                      ),

                      _tituloSeccao('FILIAÇÃO'),
                      const Text(
                        'Se o pai/mãe já estiver registado (ex: por causa de um irmão), pesquisa o nome em vez de criar de novo.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      PessoaPickerField(
                        rotulo: 'Pai',
                        pessoasDisponiveis: _pessoas,
                        valorInicial: _pai,
                        onChanged: (p) => setState(() => _pai = p),
                      ),
                      const SizedBox(height: 16),
                      PessoaPickerField(
                        rotulo: 'Mãe',
                        pessoasDisponiveis: _pessoas,
                        valorInicial: _mae,
                        onChanged: (p) => setState(() => _mae = p),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _avoPaternoController,
                              decoration: const InputDecoration(labelText: 'Avô paterno (opcional)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _avoPaternaController,
                              decoration: const InputDecoration(labelText: 'Avó paterna (opcional)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _avoMaternoController,
                              decoration: const InputDecoration(labelText: 'Avô materno (opcional)', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _avoMaternaController,
                              decoration: const InputDecoration(labelText: 'Avó materna (opcional)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),

                      _tituloSeccao('PADRINHOS'),
                      const Text(
                        'Um padrinho/madrinha pode ter vários afilhados — pesquisa antes de criar novo.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      PessoaPickerField(
                        rotulo: 'Padrinho',
                        pessoasDisponiveis: _pessoas,
                        valorInicial: _padrinho,
                        incluirNaturalDe: false,
                        onChanged: (p) => setState(() => _padrinho = p),
                      ),
                      const SizedBox(height: 16),
                      PessoaPickerField(
                        rotulo: 'Madrinha',
                        pessoasDisponiveis: _pessoas,
                        valorInicial: _madrinha,
                        incluirNaturalDe: false,
                        onChanged: (p) => setState(() => _madrinha = p),
                      ),

                      _tituloSeccao('ELEIÇÃO E ESCRUTÍNIOS (opcional — só para algumas fases)'),
                      _campoData('Data da eleição', _eleicaoData, (d) => setState(() => _eleicaoData = d)),
                      const SizedBox(height: 16),
                      _campoData('1º escrutínio', _escrutinio1Data, (d) => setState(() => _escrutinio1Data = d)),
                      const SizedBox(height: 16),
                      _campoData('2º escrutínio', _escrutinio2Data, (d) => setState(() => _escrutinio2Data = d)),
                      const SizedBox(height: 16),
                      _campoData('3º escrutínio', _escrutinio3Data, (d) => setState(() => _escrutinio3Data = d)),

                      _tituloSeccao('BAPTISMO'),
                      TextFormField(
                        controller: _baptismoLocalController,
                        decoration: const InputDecoration(
                          labelText: 'Paróquia/Igreja (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _baptismoArquidioceseController,
                        decoration: const InputDecoration(labelText: 'Arquidiocese (opcional)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      _campoData('Data do baptismo', _baptismoData, (d) => setState(() => _baptismoData = d)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _baptismoLivroController,
                              decoration: const InputDecoration(labelText: 'Livro', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _baptismoNumeroRegistoController,
                              decoration: const InputDecoration(labelText: 'Nº de registo', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _baptismoPaginaController,
                              decoration: const InputDecoration(labelText: 'Página', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _baptismoCertidaoController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Link da certidão (opcional)',
                          hintText: 'Link do Google Drive',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      _tituloSeccao('PRIMEIRA COMUNHÃO'),
                      _campoData('Data', _primeiraComunhaoData, (d) => setState(() => _primeiraComunhaoData = d)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _primeiraComunhaoHoraController,
                        decoration: const InputDecoration(labelText: 'Hora (opcional)', hintText: 'Ex: 10H00', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _primeiraComunhaoLivroController,
                              decoration: const InputDecoration(labelText: 'Livro', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _primeiraComunhaoNumeroRegistoController,
                              decoration: const InputDecoration(labelText: 'Nº de registo', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _primeiraComunhaoPaginaController,
                              decoration: const InputDecoration(labelText: 'Página', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),

                      _tituloSeccao('CRISMA'),
                      _campoData('Data', _crismaData, (d) => setState(() => _crismaData = d)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _crismaHoraController,
                        decoration: const InputDecoration(labelText: 'Hora (opcional)', hintText: 'Ex: 09H00', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _crismaLivroController,
                              decoration: const InputDecoration(labelText: 'Livro', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _crismaNumeroRegistoController,
                              decoration: const InputDecoration(labelText: 'Nº de registo', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _crismaPaginaController,
                              decoration: const InputDecoration(labelText: 'Página', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),

                      _tituloSeccao('OBSERVAÇÕES'),
                      TextFormField(
                        controller: _observacoesController,
                        maxLines: 3,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),

                      const SizedBox(height: 28),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _submitting ? null : _salvar,
                          child: _submitting
                              ? const SizedBox(
                                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Guardar'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
