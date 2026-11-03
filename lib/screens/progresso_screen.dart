import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/conquista.dart';
import '../widgets/erro_de_carregamento.dart';
import '../widgets/grafico_pontos_semana.dart';

class ProgressoScreen extends StatelessWidget {
  const ProgressoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progresso')),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.carregando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (appState.erro != null) {
            return ErroDeCarregamento(mensagem: appState.erro!);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Pontos na semana',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GraficoPontosSemana(
                pontosPorDia: appState.pontosPorDia,
                indiceHoje: DateTime.now().weekday - 1,
              ),
              const SizedBox(height: 24),
              Text(
                'Conquistas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...conquistasDisponiveis.map((conquista) {
                final desbloqueada =
                    appState.conquistasDesbloqueadas.contains(conquista.id);
                return Card(
                  child: ListTile(
                    leading: Icon(
                      desbloqueada
                          ? Icons.emoji_events
                          : Icons.emoji_events_outlined,
                      color: desbloqueada ? Colors.amber[700] : Colors.grey,
                    ),
                    title: Text(conquista.nome),
                    subtitle: Text(conquista.descricao),
                    trailing: desbloqueada
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.lock_outline, color: Colors.grey),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
