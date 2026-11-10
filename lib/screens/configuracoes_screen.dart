import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/conquista.dart';
import '../theme/app_cores.dart';
import '../widgets/titulo_secao.dart';
import 'conquistas_screen.dart';

/// Configurações do app: conquistas, aparência, conta e dados locais.
/// É aberta como tela separada pela engrenagem de qualquer aba.
class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final temConta = appState.nomeUsuario != null;
    final tokens = context.coresApp;
    final tema = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Conquistas'),
              subtitle: Text(
                '${appState.conquistasDesbloqueadas.length}/${conquistasDisponiveis.length} desbloqueadas',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConquistasScreen()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const TituloSecao('Aparência'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Sistema'),
                  value: ThemeMode.system,
                  groupValue: appState.tema,
                  onChanged: (modo) => appState.definirTema(modo!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Claro'),
                  value: ThemeMode.light,
                  groupValue: appState.tema,
                  onChanged: (modo) => appState.definirTema(modo!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Escuro'),
                  value: ThemeMode.dark,
                  groupValue: appState.tema,
                  onChanged: (modo) => appState.definirTema(modo!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const TituloSecao('Conta'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(appState.nomeUsuario ?? 'Modo convidado'),
              subtitle: Text(
                temConta
                    ? (appState.emailUsuario ?? '')
                    : 'Sem conta: o feed e o perfil público ficam desligados.',
              ),
            ),
          ),
          const SizedBox(height: 24),
          const TituloSecao('Seus dados'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.phone_iphone, color: tokens.textoSecundario),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Projetos, tarefas, anotações e pontos ficam salvos só neste '
                      'aparelho. Só vai para a internet o que você escolher '
                      'publicar: posts, perfil público e projetos marcados como '
                      'visíveis.',
                      style: tema.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _sair(context),
              icon: const Icon(Icons.logout),
              label: Text(temConta ? 'Sair da conta' : 'Entrar ou criar conta'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: tokens.estiloBotaoPerigoSuave,
              onPressed: () => _confirmarApagarTudo(context),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Apagar todos os dados'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sair(BuildContext context) async {
    final appState = context.read<AppState>();
    // Esta tela foi empilhada sobre a navegação principal. Sem fechar antes, ao
    // voltar para a porta de entrada ela continuaria na frente.
    Navigator.of(context).popUntil((rota) => rota.isFirst);
    await appState.sair();
  }

  Future<void> _confirmarApagarTudo(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar todos os dados?'),
        content: const Text(
          'Isso remove todos os projetos, anotações, tarefas, pontos e '
          'conquistas deste aparelho e sai da sua conta. Publicações e perfil '
          'público já enviados continuam na comunidade. Não pode ser desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: dialogContext.coresApp.estiloBotaoPerigo,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;
    final appState = context.read<AppState>();
    Navigator.of(context).popUntil((rota) => rota.isFirst);
    await appState.apagarTudo();
  }
}
