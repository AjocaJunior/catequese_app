import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _auth = AuthService();

  final _formKeyPasso1 = GlobalKey<FormState>();
  final _formKeyPasso2 = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _codigoPedido = false;
  bool _submitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _novaSenhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _pedirCodigo() async {
    if (!_formKeyPasso1.currentState!.validate()) return;
    setState(() => _submitting = true);

    final erro = await _auth.esqueciSenha(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _submitting = false);

    if (erro == null) {
      setState(() => _codigoPedido = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se o email existir, foi enviado um código. Verifica a tua caixa de entrada.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    }
  }

  Future<void> _redefinir() async {
    if (!_formKeyPasso2.currentState!.validate()) return;
    setState(() => _submitting = true);

    final erro = await _auth.redefinirSenha(
      _emailController.text.trim(),
      _codigoController.text.trim(),
      _novaSenhaController.text,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (erro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Palavra-passe redefinida. Já podes entrar.')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar palavra-passe')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 420 : double.infinity),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _codigoPedido ? _passo2() : _passo1(),
          ),
        ),
      ),
    );
  }

  Widget _passo1() {
    return Form(
      key: _formKeyPasso1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Introduz o teu email. Se existir uma conta associada, enviamos um código de confirmação de 6 dígitos.',
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            validator: (v) => (v == null || !v.contains('@')) ? 'Introduz um email válido' : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _submitting ? null : _pedirCodigo,
              child: _submitting
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enviar código'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passo2() {
    return Form(
      key: _formKeyPasso2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Código enviado para ${_emailController.text.trim()}.'),
          const SizedBox(height: 20),
          TextFormField(
            controller: _codigoController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'Código de 6 dígitos', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().length != 6) ? 'O código tem 6 dígitos' : null,
          ),
          TextFormField(
            controller: _novaSenhaController,
            obscureText: _obscure,
            decoration: const InputDecoration(labelText: 'Nova palavra-passe', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmarController,
            obscureText: _obscure,
            decoration: const InputDecoration(labelText: 'Confirmar nova palavra-passe', border: OutlineInputBorder()),
            validator: (v) => (v != _novaSenhaController.text) ? 'As palavras-passe não coincidem' : null,
          ),
          CheckboxListTile(
            value: !_obscure,
            onChanged: (v) => setState(() => _obscure = !(v ?? false)),
            title: const Text('Mostrar palavra-passe'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _submitting ? null : _redefinir,
              child: _submitting
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Redefinir palavra-passe'),
            ),
          ),
          TextButton(
            onPressed: _submitting ? null : () => setState(() => _codigoPedido = false),
            child: const Text('Não recebi / usar outro email'),
          ),
        ],
      ),
    );
  }
}
