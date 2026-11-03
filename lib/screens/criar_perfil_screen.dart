import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/auth_service.dart';

class CriarPerfilScreen extends StatefulWidget {
  const CriarPerfilScreen({super.key});

  @override
  State<CriarPerfilScreen> createState() => _CriarPerfilScreenState();
}

class _CriarPerfilScreenState extends State<CriarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _salvando = false;
  bool _modoCadastro = false;
  bool _ocultarSenha = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _enviar() async {
    if (_formKey.currentState?.validate() != true || _salvando) return;
    setState(() => _salvando = true);

    final appState = context.read<AppState>();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    try {
      if (_modoCadastro) {
        final nome = _nomeController.text.trim();
        final resposta = await AuthService.instance
            .cadastrar(nome: nome, email: email, senha: senha);

        if (resposta.session == null) {
          if (!mounted) return;
          setState(() {
            _salvando = false;
            _modoCadastro = false;
          });
          _mostrarMensagem('Conta criada! Confirme seu email e depois entre.');
          return;
        }
        await appState.criarPerfil(nome: nome, email: email);
      } else {
        final resposta =
            await AuthService.instance.entrar(email: email, senha: senha);
        final nomeSalvo = resposta.user?.userMetadata?['nome'] as String?;
        final nome = (nomeSalvo != null && nomeSalvo.isNotEmpty)
            ? nomeSalvo
            : email.split('@').first;
        await appState.criarPerfil(nome: nome, email: email);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _mostrarMensagem(AuthService.traduzirErro(e));
    }
  }

  Future<void> _continuarSemConta() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      await context.read<AppState>().continuarSemConta();
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _mostrarMensagem('Não foi possível salvar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _modoCadastro ? 'Criar conta' : 'Bem-vindo de volta',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Com uma conta você poderá publicar o que quiser mais '
                      'pra frente. Ou continue sem conta — seus estudos '
                      'ficam salvos no aparelho de qualquer jeito.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    if (_modoCadastro) ...[
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        textInputAction: TextInputAction.next,
                        validator: (valor) =>
                            (valor == null || valor.trim().isEmpty)
                                ? 'Informe seu nome'
                                : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (valor) {
                        final texto = valor?.trim() ?? '';
                        if (texto.isEmpty) return 'Informe seu email';
                        if (!texto.contains('@') || !texto.contains('.')) {
                          return 'Email inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _senhaController,
                      obscureText: _ocultarSenha,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        suffixIcon: IconButton(
                          icon: Icon(_ocultarSenha
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _enviar(),
                      validator: (valor) {
                        if (valor == null || valor.isEmpty) {
                          return 'Informe sua senha';
                        }
                        if (_modoCadastro && valor.length < 6) {
                          return 'Mínimo de 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _salvando ? null : _enviar,
                      child: _salvando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_modoCadastro ? 'Criar conta' : 'Entrar'),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _salvando
                          ? null
                          : () =>
                              setState(() => _modoCadastro = !_modoCadastro),
                      child: Text(_modoCadastro
                          ? 'Já tenho conta — entrar'
                          : 'Não tenho conta — criar uma'),
                    ),
                    TextButton(
                      onPressed: _salvando ? null : _continuarSemConta,
                      child: const Text('ou continuar sem conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
