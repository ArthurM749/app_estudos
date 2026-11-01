import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/conquista.dart';
import '../utils/formatadores.dart';

/// Ícone de cada conquista. Fica aqui (e não no model) pra manter
/// `Conquista` livre de dependência do Flutter.
const Map<String, IconData> _iconesConquistas = {
  'primeira_anotacao': Icons.edit_note,
  'arquiteto': Icons.architecture,
  'maos_a_obra': Icons.handyman,
  'biblioteca': Icons.menu_book,
  'nivel_5': Icons.military_tech,
  'nivel_10': Icons.workspace_premium,
  'aquecendo': Icons.local_fire_department,
  'semana_perfeita': Icons.event_available,
  'centenario': Icons.star,
  'estudioso': Icons.school,
  'dedicado': Icons.emoji_events,
};

/// Perfil: avatar e dados do usuário (ou "modo convidado"),
/// estatísticas, grade de conquistas, aparência (tema) e a opção de
/// apagar todos os dados do aparelho.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, appState, _) {
            final temConta = appState.nomeUsuario != null;
            final nome = appState.nomeUsuario ?? 'Estudante';
            final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';
            final desde = appState.perfilCriadoEm;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        child: Text(
                          inicial,
                          style:
                              const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nome,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        temConta
                            ? (appState.emailUsuario ?? '')
                            : 'Modo convidado · sem conta',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (desde != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Estudando desde ${formatarMesAno(desde)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _Estatistica(valor: '${appState.pontosTotais}', rotulo: 'pontos'),
                    ),
                    Expanded(
                      child: _Estatistica(
                        valor: '${appState.sequenciaDias}',
                        rotulo: 'sequência',
                      ),
                    ),
                    Expanded(
                      child: _Estatistica(valor: '${appState.nivel}', rotulo: 'nível'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Conquistas',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${appState.conquistasDesbloqueadas.length}/${conquistasDisponiveis.length} desbloqueadas',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.85,
                  children: conquistasDisponiveis.map((conquista) {
                    final desbloqueada =
                        appState.conquistasDesbloqueadas.contains(conquista.id);
                    return _CartaoConquista(
                      conquista: conquista,
                      desbloqueada: desbloqueada,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Aparência',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
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
                Text(
                  'Feed e publicações',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.dynamic_feed_outlined),
                    title: const Text('Publicar anotações para outras pessoas'),
                    subtitle: const Text(
                      'Vai funcionar quando o app sincronizar com a internet, '
                      'numa fase seguinte do projeto.',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Em breve',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Seus dados',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.phone_iphone, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tudo o que você vê aqui fica salvo só neste aparelho '
                            '— nada é enviado pra internet nessa versão.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    onPressed: () => _confirmarApagarTudo(context),
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Apagar todos os dados'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmarApagarTudo(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apagar todos os dados?'),
        content: const Text(
          'Isso remove todos os projetos, anotações, tarefas, pontos e '
          'conquistas deste aparelho. Não pode ser desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );
    if (confirmou == true) {
      await context.read<AppState>().apagarTudo();
    }
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _CartaoConquista extends StatelessWidget {
  final Conquista conquista;
  final bool desbloqueada;

  const _CartaoConquista({required this.conquista, required this.desbloqueada});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final icone = _iconesConquistas[conquista.id] ?? Icons.emoji_events_outlined;

    return Tooltip(
      message: '${conquista.nome}\n${conquista.descricao}',
      child: Container(
        decoration: BoxDecoration(
          color: desbloqueada ? cores.primaryContainer : cores.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 26,
              color: desbloqueada
                  ? cores.onPrimaryContainer
                  : cores.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 6),
            Text(
              conquista.nome,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: desbloqueada
                    ? cores.onPrimaryContainer
                    : cores.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
