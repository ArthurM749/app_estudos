import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/regras_pontos.dart';
import '../widgets/erro_de_carregamento.dart';

/// Tela de Início (dashboard): pontos de hoje x ontem, nível atual
/// e um resumo dos projetos.
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nível ${appState.nivel}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text('${appState.pontosTotais} pontos no total'),
                      const SizedBox(height: 2),
                      Text(
                        'Faltam $faltamParaProximoNivel pontos para o próximo nível',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
              Card(
                child: ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Esta semana'),
                  trailing: Text('${appState.pontosSemana} pts'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('Projetos ativos'),
                  trailing: Text('${appState.projetos.length}'),
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

  const _CartaoPontos({required this.titulo, required this.valor});

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
