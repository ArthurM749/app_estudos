import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/conquista.dart';
import '../theme/app_cores.dart';
import '../utils/icones_conquistas.dart';

/// Todas as conquistas do app, desbloqueadas ou não. Fica dentro das
/// Configurações; no perfil público só aparecem as que a pessoa destacar.
class ConquistasScreen extends StatelessWidget {
  const ConquistasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tokens = context.coresApp;

    return Scaffold(
      appBar: AppBar(title: const Text('Conquistas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '${appState.conquistasDesbloqueadas.length}/${conquistasDisponiveis.length} desbloqueadas',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: tokens.textoSecundario),
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
        ],
      ),
    );
  }
}

class _CartaoConquista extends StatelessWidget {
  final Conquista conquista;
  final bool desbloqueada;

  const _CartaoConquista({required this.conquista, required this.desbloqueada});

  @override
  Widget build(BuildContext context) {
    final cores = context.coresApp;

    return Tooltip(
      message: '${conquista.nome}\n${conquista.descricao}',
      child: Container(
        decoration: BoxDecoration(
          color: desbloqueada
              ? cores.conquistaFundo
              : cores.conquistaBloqueadaFundo,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconeDaConquista(conquista.id),
              size: 26,
              color: desbloqueada
                  ? cores.conquistaIcone
                  : cores.conquistaBloqueadaIcone,
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
                    ? cores.conquistaTexto
                    : cores.conquistaBloqueadaTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
