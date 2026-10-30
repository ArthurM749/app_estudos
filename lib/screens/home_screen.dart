import 'package:app_estudos/screens/progresso_screen.dart';
import 'package:app_estudos/screens/projetos_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/regras_pontos.dart';
import '../widgets/erro_de_carregamento.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.carregando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (appState.erro != null) {
            return ErroDeCarregamento(mensagem: appState.erro!);
          }

          final faltamParaProximoNivel =
              RegrasDePontos.pontosParaProximoNivel(appState.nivel);
          final variacao = appState.pontosHoje - appState.pontosOntem;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (appState.nomeUsuario != null) ...[
                Text(
                  'Olá, ${appState.nomeUsuario}!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
              ],

              // ===== CARD DE SEQUÊNCIA + NÍVEL =====
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Lado esquerdo - Sequência
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sequência',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${appState.diasSequencia} dias',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Divisor
                      Container(
                        height: 45,
                        width: 1,
                        color: Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),

                      // Lado direito - Nível
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nível ${appState.nivel}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text('${appState.pontosTotais} pontos totais'),
                            
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ===== HOJE / ONTEM =====
              Row(
                children: [
                  Expanded(
                    child: _CartaoPontos(
                      titulo: 'Hoje',
                      valor: appState.pontosHoje,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CartaoPontos(
                      titulo: 'Ontem',
                      valor: appState.pontosOntem,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Variação
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    variacao >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: variacao >= 0 ? Colors.green : Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    variacao == 0
                        ? 'Igual a ontem'
                        : '${variacao > 0 ? '+' : ''}$variacao em relação a ontem',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ===== ESTA SEMANA =====
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProgressoScreen(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 231, 235, 243),
                    border: Border.all(
                      color: const Color.fromARGB(255, 75, 73, 133),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.date_range),
                    title: Text(
                      'Esta semana',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      // Você pode colocar o valor aqui se quiser
                      '',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              // Correção do trailing (pontos da semana)
              // Melhor forma:
              // trailing: Text('${appState.pontosSemana} pts', ...)

              const SizedBox(height: 12),

              // ===== PROJETOS ATIVOS =====
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProjetosScreen(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 224, 198),
                    border: Border.all(
                      color: const Color(0xFFC56F29),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text(
                      'Projetos ativos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '${appState.projetos.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartaoPontos extends StatelessWidget {
  final String titulo;
  final int valor;

  const _CartaoPontos({
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(titulo, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '$valor',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
