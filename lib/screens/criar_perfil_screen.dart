import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';

/// Primeira tela que o usuário vê, antes de qualquer coisa: criar um
/// perfil local (nome + email) ou seguir sem conta.
///
/// Não existe autenticação de verdade nessa versão — nome e email só
/// ficam salvos no banco local. É a base pra quando a fase de
/// sincronização ligar isso numa conta de verdade.
class CriarPerfilScreen extends StatefulWidget {
  const CriarPerfilScreen({super.key});

  @override
  State<CriarPerfilScreen> createState() => _CriarPerfilScreenState();
}

class _CriarPerfilScreenState extends State<CriarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _criarPerfil() async {
    if (_formKey.currentState?.validate() != true || _salvando) return;
    setState(() => _salvando = true);
    await context.read<AppState>().criarPerfil(
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
        );
    // Depois disso o AppState marca onboardingConcluido = true e
    // quem decide a tela (PortaDeEntrada) troca pra navegação
    // principal sozinho — não precisa de Navigator aqui.
  }

  Future<void> _continuarSemConta() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    await context.read<AppState>().continuarSemConta();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                    'Bem-vindo',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie um perfil pra mais pra frente poder publicar o que '
                    'quiser, ou continue sem conta — seus estudos ficam '
                    'salvos no aparelho de qualquer jeito.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    textInputAction: TextInputAction.next,
                    validator: (valor) => (valor == null || valor.trim().isEmpty)
                        ? 'Informe seu nome'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: (valor) {
                      final texto = valor?.trim() ?? '';
                      if (texto.isEmpty) return 'Informe seu email';
                      if (!texto.contains('@') || !texto.contains('.')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _salvando ? null : _criarPerfil,
                    child: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Criar perfil'),
                  ),
                  const SizedBox(height: 4),
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
    );
  }
}
