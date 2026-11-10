import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/auth_service.dart';
import '../theme/app_cores.dart';
import '../utils/formatadores.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/cabecalho_da_aba.dart';
import 'perfil_publico_screen.dart';

/// Aba "Perfil": é o PRÓPRIO perfil público (o mesmo que os outros veem, com
/// cadeados no que está privado). Conquistas, tema e dados ficam em
/// Configurações. Sem conta (modo convidado) não existe perfil público, então
/// aparece uma versão local simples com o convite para criar conta.
class PerfilScreen extends StatelessWidget {
  final VoidCallback? aoTocarConfiguracoes;

  const PerfilScreen({super.key, this.aoTocarConfiguracoes});

  @override
  Widget build(BuildContext context) {
    // Observa o AppState só para reconstruir quando entrar/sair da conta.
    context.watch<AppState>();
    final meuId = AuthService.instance.usuarioAtual?.id;

    if (meuId != null) {
      return PerfilPublicoScreen(
        // Chave por usuário: trocar de conta recria a tela e recarrega tudo.
        key: ValueKey(meuId),
        usuarioId: meuId,
        embutido: true,
        aoTocarConfiguracoes: aoTocarConfiguracoes,
      );
    }
    return _PerfilConvidado(aoTocarConfiguracoes: aoTocarConfiguracoes);
  }
}

class _PerfilConvidado extends StatelessWidget {
  final VoidCallback? aoTocarConfiguracoes;

  const _PerfilConvidado({this.aoTocarConfiguracoes});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tokens = context.coresApp;
    final tema = Theme.of(context).textTheme;
    final nome = app.nomeUsuario ?? 'Estudante';
    final desde = app.perfilCriadoEm;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CabecalhoDaAba(
              titulo: 'Perfil',
              aoTocarConfiguracoes: aoTocarConfiguracoes,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Center(
                    child: Column(
                      children: [
                        AvatarUsuario(nome: nome, raio: 40),
                        const SizedBox(height: 12),
                        Text(
                          nome,
                          style: tema.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Modo convidado · sem conta',
                          style: tema.bodySmall
                              ?.copyWith(color: tokens.textoSecundario),
                        ),
                        if (desde != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Estudando desde ${formatarMesAno(desde)}',
                            style: tema.bodySmall
                                ?.copyWith(color: tokens.textoSecundario),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _Estatistica(
                            valor: '${app.pontosTotais}', rotulo: 'pontos'),
                      ),
                      Expanded(
                        child: _Estatistica(
                            valor: '${app.sequenciaDias}', rotulo: 'sequência'),
                      ),
                      Expanded(
                        child: _Estatistica(
                            valor: '${app.nivel}', rotulo: 'nível'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perfil público',
                            style: tema.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Entre ou crie uma conta para ter um perfil público, '
                            'publicar no feed e seguir colegas. Seus dados '
                            'atuais continuam aqui no aparelho.',
                            style: tema.bodyMedium
                                ?.copyWith(color: tokens.textoSecundario),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => context.read<AppState>().sair(),
                            child: const Text('Entrar ou criar conta'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Estatistica extends StatelessWidget {
  final String valor;
  final String rotulo;

  const _Estatistica({required this.valor, required this.rotulo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          rotulo,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: context.coresApp.textoSecundario),
        ),
      ],
    );
  }
}
