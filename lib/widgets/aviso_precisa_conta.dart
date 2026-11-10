import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../theme/app_cores.dart';

/// Mostrado no lugar da parte social quando a pessoa está no modo "sem conta".
/// O botão leva de volta à tela de entrada (mesmo caminho do "Entrar ou criar
/// conta" do Perfil); os dados locais não são apagados.
class AvisoPrecisaConta extends StatelessWidget {
  const AvisoPrecisaConta({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined,
                size: 48, color: context.coresApp.iconeDestaque),
            const SizedBox(height: 12),
            Text(
              'A comunidade precisa de uma conta',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Você continua estudando normalmente sem conta. Para ver o feed, '
              'seguir colegas e ter um perfil público, entre ou crie uma conta.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.coresApp.textoSecundario,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<AppState>().sair(),
              child: const Text('Entrar ou criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
