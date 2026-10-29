import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../widgets/erro_de_carregamento.dart';
import 'criar_perfil_screen.dart';
import 'navegacao_principal.dart';

/// Decide o que mostrar assim que o app abre: enquanto carrega, um
/// spinner; se a pessoa nunca decidiu sobre conta, a tela de criar
/// perfil; daí em diante, direto pra navegação principal.
class PortaDeEntrada extends StatelessWidget {
  const PortaDeEntrada({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.carregando) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (appState.erro != null) {
          return Scaffold(body: ErroDeCarregamento(mensagem: appState.erro!));
        }
        if (!appState.onboardingConcluido) {
          return const CriarPerfilScreen();
        }
        return const NavegacaoPrincipal();
      },
    );
  }
}
