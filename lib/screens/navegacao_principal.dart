import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'progresso_screen.dart';
import 'projetos_screen.dart';

/// Navegação por abas da versão teste: Início, Projetos e Progresso.
///
/// Feed e perfil completo ficam de fora de propósito — a parte social
/// só entra numa fase seguinte, quando o app sincronizar com a
/// internet.
class NavegacaoPrincipal extends StatefulWidget {
  const NavegacaoPrincipal({super.key});

  @override
  State<NavegacaoPrincipal> createState() => _NavegacaoPrincipalState();
}

class _NavegacaoPrincipalState extends State<NavegacaoPrincipal> {
  int _abaAtual = 0;

  static const _telas = [
    HomeScreen(),
    ProjetosScreen(),
    ProgressoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _abaAtual, children: _telas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,
        onDestinationSelected: (indice) => setState(() => _abaAtual = indice),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Projetos'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Progresso'),
        ],
      ),
    );
  }
}
