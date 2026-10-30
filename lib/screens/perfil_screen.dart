import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/conquista.dart';
import '../widgets/erro_de_carregamento.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.carregando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (appState.erro != null) {
            return ErroDeCarregamento(mensagem: appState.erro!);
          }

          final iniciais = (appState.nomeUsuario?.isNotEmpty == true
                  ? appState.nomeUsuario![0]
                  : 'E')
              .toUpperCase();

          final nome = appState.nomeUsuario ?? 'Estudante';
          final modo = appState.emailUsuario != null
              ? appState.emailUsuario!
              : 'Modo convidado · sem conta';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ===== CARD DO USUÁRIO =====
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          iniciais,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              modo,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Estudando desde outubro de 2026',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ===== ESTATÍSTICAS =====
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      valor: '${appState.pontosTotais}',
                      label: 'pontos',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      valor: '${appState.diasSequencia}',
                      label: 'dias seguidos',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      valor: '${appState.nivel}',
                      label: 'nível',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ===== CONQUISTAS =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Conquistas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${appState.conquistasDesbloqueadas.length}/${conquistasDisponiveis.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: conquistasDisponiveis.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final conquista = conquistasDisponiveis[index];
                      final desbloqueada = appState.conquistasDesbloqueadas
                          .contains(conquista.id);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: desbloqueada
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.15)
                                : Colors.grey.withOpacity(0.2),
                            child: Icon(
                              desbloqueada
                                  ? Icons.emoji_events
                                  : Icons.lock_outline,
                              color: desbloqueada
                                  ? Colors.amber.shade600
                                  : Colors.grey,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            conquista.nome,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: desbloqueada ? null : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            conquista.descricao,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ===== APARÊNCIA (TEMA) =====
              Text(
                'Aparência',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      _TemaBotao(
                        texto: 'Sistema',
                        selecionado: appState.tema == ThemeMode.system,
                        onTap: () => appState.alterarTema(ThemeMode.system),
                      ),
                      _TemaBotao(
                        texto: 'Claro',
                        selecionado: appState.tema == ThemeMode.light,
                        onTap: () => appState.alterarTema(ThemeMode.light),
                      ),
                      _TemaBotao(
                        texto: 'Escuro',
                        selecionado: appState.tema == ThemeMode.dark,
                        onTap: () => appState.alterarTema(ThemeMode.dark),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===== FEED =====
              Card(
                child: ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Feed e publicações'),
                  subtitle: const Text(
                      'Curta, comente e siga amigos em uma próxima versão.'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Em breve',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ===== SEUS DADOS =====
              Text(
                'Seus dados',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.phone_android, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tudo é salvo apenas neste dispositivo, offline.\nDepois você poderá sincronizar com a internet se quiser.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Funcionalidade em breve')),
                            );
                          },
                          child: const Text(
                            'Apagar todos os dados',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String valor;
  final String label;

  const _StatCard({required this.valor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              valor,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TemaBotao extends StatelessWidget {
  final String texto;
  final bool selecionado;
  final VoidCallback onTap;

  const _TemaBotao({
    required this.texto,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selecionado
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              texto,
              style: TextStyle(
                color: selecionado ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}