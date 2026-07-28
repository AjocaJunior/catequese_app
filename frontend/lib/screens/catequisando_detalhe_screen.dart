import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/catequisando.dart';
import '../models/pessoa.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/catequisando_service.dart';
import '../utils/partilha_helper.dart';
import '../utils/whatsapp_helper.dart';

class CatequisandoDetalheScreen extends StatefulWidget {
  final Catequisando catequisando;

  const CatequisandoDetalheScreen({super.key, required this.catequisando});

  @override
  State<CatequisandoDetalheScreen> createState() => _CatequisandoDetalheScreenState();
}

class _CatequisandoDetalheScreenState extends State<CatequisandoDetalheScreen> {
  late Catequisando _catequisando;
  List<Map<String, dynamic>> _historico = [];
  bool _carregandoHistorico = true;
  bool _imprimindo = false;
  bool _partilhando = false;

  bool get _isAdmin => context.read<AuthService>().catequista?.isAdmin ?? false;

  @override
  void initState() {
    super.initState();
    _catequisando = widget.catequisando;
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _carregandoHistorico = true);
    final token = context.read<AuthService>().token;
    try {
      final historico = await CatequisandoService(token).historico(_catequisando.id);
      if (!mounted) return;
      setState(() => _historico = historico);
    } catch (_) {
      // histórico é só informativo — falha silenciosamente
    } finally {
      if (mounted) setState(() => _carregandoHistorico = false);
    }
  }

  Future<void> _imprimir() async {
    setState(() => _imprimindo = true);
    final token = context.read<AuthService>().token;
    try {
      final bytes = await CatequisandoService(token).baixarProcessoPdf(_catequisando.id);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao gerar PDF';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  Future<void> _imprimirFichaSacramento(String tipo) async {
    setState(() => _imprimindo = true);
    final token = context.read<AuthService>().token;
    try {
      final bytes = await CatequisandoService(token).baixarFichaSacramentoPdf(_catequisando.id, tipo);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao gerar a ficha';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _imprimindo = false);
    }
  }

  static const _kNomesDocumento = {
    'processo': 'Ficha do Catecúmeno',
    'baptismo': 'Ficha de Baptismo',
    'primeira_comunhao': 'Ficha de 1ª Comunhão',
    'crisma': 'Ficha de Crisma',
    'transferencia': 'Guia de Transferência',
  };

  Future<void> _partilhar(String tipo) async {
    setState(() => _partilhando = true);
    final token = context.read<AuthService>().token;
    try {
      final service = CatequisandoService(token);
      final Uint8List bytes;
      if (tipo == 'processo') {
        bytes = await service.baixarProcessoPdf(_catequisando.id);
      } else if (tipo == 'transferencia') {
        bytes = await service.baixarGuiaTransferenciaPdf(_catequisando.id);
      } else {
        bytes = await service.baixarFichaSacramentoPdf(_catequisando.id, tipo);
      }

      if (!mounted) return;
      await partilharPdf(
        context,
        bytes,
        nomeFicheiro: '${tipo}_${_catequisando.nome.replaceAll(' ', '_')}.pdf',
        legenda: '${_kNomesDocumento[tipo]} — ${_catequisando.nome}',
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao gerar o documento';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _partilhando = false);
    }
  }

  Future<void> _alternarCrismado() async {
    final vaiCrismar = _catequisando.situacao == SituacaoCatequisando.ativo;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vaiCrismar ? 'Marcar como Crismado' : 'Reativar catequisando'),
        content: Text(
          vaiCrismar
              ? '${_catequisando.nome} deixa de aparecer nas presenças e pautas ativas de '
                  '"${_catequisando.faseNome}". O histórico mantém-se, e podes reverter isto depois.'
              : '${_catequisando.nome} volta a aparecer como Ativo em "${_catequisando.faseNome}".',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmar != true) return;

    final token = context.read<AuthService>().token;
    try {
      final atualizado = vaiCrismar
          ? await CatequisandoService(token).crismar(_catequisando.id)
          : await CatequisandoService(token).reativar(_catequisando.id);
      if (!mounted) return;
      setState(() => _catequisando = atualizado);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Ocorreu um erro';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _mostrarFormularioTransferencia() async {
    final c = _catequisando;
    final numeroController = TextEditingController(text: c.transferenciaNumero ?? '');
    final anoGuiaController = TextEditingController(
      text: (c.transferenciaAnoGuia ?? DateTime.now().year).toString(),
    );
    final anoFrequentadoController = TextEditingController(
      text: (c.transferenciaAnoFrequentado ?? DateTime.now().year).toString(),
    );
    final destinoComunidadeController = TextEditingController(text: c.transferenciaDestinoComunidade ?? '');
    final destinoArquidioceseController = TextEditingController(text: c.transferenciaDestinoArquidiocese ?? 'Maputo');
    final observacaoController = TextEditingController(text: c.transferenciaObservacao ?? '');
    DateTime dataImpressao = c.transferenciaData ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Transferir ${c.nome}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Gera a Guia de Transferência e marca o catequisando como Transferido '
                      '(deixa de aparecer nas presenças e pautas ativas).',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: numeroController,
                            decoration: const InputDecoration(labelText: 'Nº da guia', border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: anoGuiaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Ano da guia', border: OutlineInputBorder()),
                            validator: (v) => (int.tryParse(v ?? '') == null) ? 'Ano inválido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: anoFrequentadoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ano em que frequentou nesta paróquia',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (int.tryParse(v ?? '') == null) ? 'Ano inválido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: destinoComunidadeController,
                      decoration: const InputDecoration(
                        labelText: 'Paróquia/Comunidade de destino',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: destinoArquidioceseController,
                      decoration: const InputDecoration(labelText: 'Arquidiocese de destino', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final escolhida = await showDatePicker(
                          context: context,
                          initialDate: dataImpressao,
                          firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (escolhida != null) setStateDialog(() => dataImpressao = escolhida);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data de impressão',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                        ),
                        child: Text(
                          '${dataImpressao.day.toString().padLeft(2, '0')}/${dataImpressao.month.toString().padLeft(2, '0')}/${dataImpressao.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: observacaoController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'NB (observação, opcional)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Transferir'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) return;

    final token = context.read<AuthService>().token;
    try {
      final atualizado = await CatequisandoService(token).transferir(
        c.id,
        numero: numeroController.text.trim(),
        anoGuia: int.parse(anoGuiaController.text.trim()),
        anoFrequentado: int.parse(anoFrequentadoController.text.trim()),
        destinoComunidade: destinoComunidadeController.text.trim(),
        destinoArquidiocese: destinoArquidioceseController.text.trim(),
        observacao: observacaoController.text.trim(),
        dataImpressao: dataImpressao,
      );
      if (!mounted) return;
      setState(() => _catequisando = atualizado);

      final imprimir = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Transferência registada'),
          content: const Text('Queres imprimir a Guia de Transferência agora?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Mais tarde')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Imprimir')),
          ],
        ),
      );
      if (imprimir == true) await _imprimirGuiaTransferencia();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao transferir';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _imprimirGuiaTransferencia() async {
    final token = context.read<AuthService>().token;
    try {
      final bytes = await CatequisandoService(token).baixarGuiaTransferenciaPdf(_catequisando.id);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erro ao gerar a guia';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _abrirLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _linha(String rotulo, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
            children: [
              TextSpan(text: '$rotulo: ', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: valor),
            ],
          ),
        ),
      );

  Widget _cartaoPessoa(String titulo, Pessoa? pessoa) {
    if (pessoa == null) return const SizedBox.shrink();
    final detalhes = [
      pessoa.profissao,
      pessoa.residencia,
      if (pessoa.provincia != null) 'Prov. ${pessoa.provincia}',
      if (pessoa.comunidade != null) pessoa.comunidade,
      if (pessoa.contacto != null) 'Contacto: ${pessoa.contacto}',
    ].where((v) => v != null).join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.person_outline),
        title: Text('$titulo: ${pessoa.nome}'),
        subtitle: detalhes.isNotEmpty ? Text(detalhes) : null,
        trailing: BotaoWhatsApp(
          telefone: pessoa.contacto,
          mensagem: mensagemPadraoCatequista(_catequisando.nome),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _catequisando;
    final isAdmin = _isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.nome),
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(c.situacao == SituacaoCatequisando.crismado ? Icons.undo : Icons.workspace_premium_outlined),
              tooltip: c.situacao == SituacaoCatequisando.crismado ? 'Reativar' : 'Marcar como Crismado',
              onPressed: _alternarCrismado,
            ),
          if (isAdmin)
            IconButton(
              icon: Icon(c.situacao == SituacaoCatequisando.transferido ? Icons.print_outlined : Icons.moving_outlined),
              tooltip: c.situacao == SituacaoCatequisando.transferido
                  ? 'Imprimir Guia de Transferência'
                  : 'Transferir',
              onPressed: c.situacao == SituacaoCatequisando.transferido
                  ? _imprimirGuiaTransferencia
                  : _mostrarFormularioTransferencia,
            ),
          _imprimindo
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.print_outlined),
                  tooltip: 'Imprimir',
                  onSelected: (valor) {
                    if (valor == 'processo') {
                      _imprimir();
                    } else if (valor == 'transferencia') {
                      _imprimirGuiaTransferencia();
                    } else {
                      _imprimirFichaSacramento(valor);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'processo', child: Text('Ficha do Catecúmeno')),
                    const PopupMenuItem(value: 'baptismo', child: Text('Ficha de Baptismo')),
                    const PopupMenuItem(value: 'primeira_comunhao', child: Text('Ficha de 1ª Comunhão')),
                    const PopupMenuItem(value: 'crisma', child: Text('Ficha de Crisma')),
                    if (c.situacao == SituacaoCatequisando.transferido)
                      const PopupMenuItem(value: 'transferencia', child: Text('Guia de Transferência')),
                  ],
                ),
          _partilhando
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Partilhar',
                  onSelected: _partilhar,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'processo', child: Text('Ficha do Catecúmeno')),
                    const PopupMenuItem(value: 'baptismo', child: Text('Ficha de Baptismo')),
                    const PopupMenuItem(value: 'primeira_comunhao', child: Text('Ficha de 1ª Comunhão')),
                    const PopupMenuItem(value: 'crisma', child: Text('Ficha de Crisma')),
                    if (c.situacao == SituacaoCatequisando.transferido)
                      const PopupMenuItem(value: 'transferencia', child: Text('Guia de Transferência')),
                  ],
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _linha('Fase', c.faseNome),
                  if (c.situacao == SituacaoCatequisando.crismado) _linha('Situação', 'Crismado'),
                  if (c.situacao == SituacaoCatequisando.transferido) _linha('Situação', 'Transferido'),
                  if (c.genero != null) _linha('Género', c.genero!.rotulo),
                  if (c.dataNascimento != null) _linha('Data de nascimento', _formatarData(c.dataNascimento!)),
                  if (c.naturalDe != null && c.naturalDe!.isNotEmpty) _linha('Natural de', c.naturalDe!),
                  if (c.estadoCivil != null && c.estadoCivil!.isNotEmpty) _linha('Estado civil', c.estadoCivil!),
                  if (c.profissao != null && c.profissao!.isNotEmpty) _linha('Profissão', c.profissao!),
                  if (c.residencia != null && c.residencia!.isNotEmpty) _linha('Residência', c.residencia!),
                  if (c.sectorNome != null) _linha('Sector pastoral', c.sectorNome!),
                  if (c.fichaAno != null || c.fichaNumero != null)
                    _linha('Ficha', 'Ano ${c.fichaAno ?? "—"} · Nº ${c.fichaNumero ?? "—"}'),
                  if (c.encarregadoNome != null && c.encarregadoNome!.isNotEmpty)
                    _linha('Encarregado de educação', c.encarregadoNome!),
                  if (c.encarregadoContacto != null && c.encarregadoContacto!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(child: _linha('Contacto do encarregado', c.encarregadoContacto!)),
                          BotaoWhatsApp(
                            telefone: c.encarregadoContacto,
                            mensagem: mensagemPadraoCatequista(c.nome),
                          ),
                        ],
                      ),
                    ),
                  if (c.observacoes != null && c.observacoes!.isNotEmpty) _linha('Observações', c.observacoes!),
                ],
              ),
            ),
          ),

          if (c.pai != null || c.mae != null || c.avoPaternoNome != null || c.avoMaternoNome != null || c.nucleoNome != null) ...[
            const SizedBox(height: 16),
            const Text('Filiação', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _cartaoPessoa('Pai', c.pai),
            _cartaoPessoa('Mãe', c.mae),
            if (c.avoPaternoNome != null || c.avoPaternaNome != null)
              Text('Avós paternos: ${c.avoPaternoNome ?? "—"} e ${c.avoPaternaNome ?? "—"}'),
            if (c.avoMaternoNome != null || c.avoMaternaNome != null)
              Text('Avós maternos: ${c.avoMaternoNome ?? "—"} e ${c.avoMaternaNome ?? "—"}'),
            if (c.nucleoNome != null)
              Text('Núcleo: ${c.nucleoNome}${c.nucleoComunidade != null ? " · ${c.nucleoComunidade}" : ""}'),
          ],

          if (c.padrinho != null || c.madrinha != null) ...[
            const SizedBox(height: 16),
            const Text('Padrinhos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _cartaoPessoa('Padrinho', c.padrinho),
            _cartaoPessoa('Madrinha', c.madrinha),
          ],

          if (c.baptismoLocal != null || c.baptismoData != null || c.baptismoCertidaoUrl != null) ...[
            const SizedBox(height: 16),
            const Text('Baptismo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (c.baptismoLocal != null) _linha('Paróquia/Igreja', c.baptismoLocal!),
            if (c.baptismoArquidiocese != null) _linha('Arquidiocese', c.baptismoArquidiocese!),
            if (c.baptismoData != null) _linha('Data', _formatarData(c.baptismoData!)),
            if (c.baptismoLivro != null || c.baptismoNumeroRegisto != null || c.baptismoPagina != null)
              _linha('Registo', 'Livro ${c.baptismoLivro ?? "—"} · Nº ${c.baptismoNumeroRegisto ?? "—"} · Pág. ${c.baptismoPagina ?? "—"}'),
            if (c.baptismoCertidaoUrl != null)
              TextButton.icon(
                onPressed: () => _abrirLink(c.baptismoCertidaoUrl!),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Ver certidão'),
              ),
          ],

          if (c.primeiraComunhaoData != null) ...[
            const SizedBox(height: 16),
            const Text('Primeira Comunhão', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _linha('Data', _formatarData(c.primeiraComunhaoData!) + (c.primeiraComunhaoHora != null ? ' às ${c.primeiraComunhaoHora}' : '')),
            if (c.primeiraComunhaoLivro != null || c.primeiraComunhaoNumeroRegisto != null || c.primeiraComunhaoPagina != null)
              _linha('Registo',
                  'Livro ${c.primeiraComunhaoLivro ?? "—"} · Nº ${c.primeiraComunhaoNumeroRegisto ?? "—"} · Pág. ${c.primeiraComunhaoPagina ?? "—"}'),
          ],

          if (c.crismaData != null) ...[
            const SizedBox(height: 16),
            const Text('Crisma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _linha('Data', _formatarData(c.crismaData!) + (c.crismaHora != null ? ' às ${c.crismaHora}' : '')),
            if (c.crismaLivro != null || c.crismaNumeroRegisto != null || c.crismaPagina != null)
              _linha('Registo', 'Livro ${c.crismaLivro ?? "—"} · Nº ${c.crismaNumeroRegisto ?? "—"} · Pág. ${c.crismaPagina ?? "—"}'),
          ],

          if (c.situacao == SituacaoCatequisando.transferido) ...[
            const SizedBox(height: 16),
            const Text('Transferência', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _linha('Guia nº', '${c.transferenciaNumero ?? "—"}/${c.transferenciaAnoGuia ?? "—"}'),
            _linha('Destino', c.transferenciaDestinoComunidade ?? '—'),
            _linha('Arquidiocese', c.transferenciaDestinoArquidiocese ?? '—'),
            if (c.transferenciaData != null) _linha('Data de emissão', _formatarData(c.transferenciaData!)),
            if (c.transferenciaObservacao != null && c.transferenciaObservacao!.isNotEmpty)
              _linha('NB', c.transferenciaObservacao!),
            TextButton.icon(
              onPressed: _imprimirGuiaTransferencia,
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('Imprimir Guia de Transferência'),
            ),
          ],

          const SizedBox(height: 20),
          const Text('Inscrições e Renovações por Ano', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_carregandoHistorico)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
          else if (_historico.isEmpty)
            const Text('Ainda não há inscrição ou renovação registada.')
          else
            ..._historico.map((h) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${h['ano_letivo'] ?? '—'}', style: const TextStyle(fontSize: 12))),
                  title: Text(h['fase_nome'] as String? ?? '—'),
                  subtitle: Text('${h['categoria']} · ${h['data']}'),
                )),
        ],
      ),
    );
  }
}
