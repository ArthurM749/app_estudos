import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';

class ErroDeCarregamento extends StatelessWidget {
  final String mensagem;

  const ErroDeCarregamento({super.key, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('Não deu pra carregar os dados.'),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<AppState>().carregar(),
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
