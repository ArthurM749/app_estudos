import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/conquista.dart';
import '../widgets/erro_de_carregamento.dart';
import '../widgets/grafico_pontos_semana.dart';

/// Nível, pontos da semana e conquistas desbloqueadas e bloqueadas.
///
/// Gráfico de pontos por dia/semana com fl_chart fica para depois —
/// esta versão já mostra os números reais, só sem o gráfico ainda.
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
              
            ],
          );
        },
      ),
    );
  }
}
