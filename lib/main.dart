import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/progresso_screen.dart';
import 'screens/projetos_screen.dart';

void main() {
  runApp(const AppEstudos());
}

/// Raiz do app. Nome provisório — o grupo ainda não bateu o martelo
/// no nome final (ver "Riscos e decisões em aberto" no documento).
class AppEstudos extends StatelessWidget {
  const AppEstudos({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..carregar(),
      child: MaterialApp(
        title: 'App de Estudos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const NavegacaoPrincipal(),
      ),
    );
  }
}

/// Navegação por abas da versão teste: Início, Projetos e Progresso.
///
/// Feed e Perfil ficam de fora de propósito — a parte social só
/// entra numa fase seguinte, quando o app sincronizar com a internet.
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
