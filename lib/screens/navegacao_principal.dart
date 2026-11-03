import 'package:flutter/material.dart';

import 'anotacoes_screen.dart';
import 'home_screen.dart';
import 'perfil_screen.dart';
import 'projetos_screen.dart';

class NavegacaoPrincipal extends StatefulWidget {
  const NavegacaoPrincipal({super.key});

  @override
  State<NavegacaoPrincipal> createState() => _NavegacaoPrincipalState();
}

class _NavegacaoPrincipalState extends State<NavegacaoPrincipal> {
  int _abaAtual = 0;

  void _irPara(int aba) => setState(() => _abaAtual = aba);
  void _abrirConfiguracoes() => setState(() => _abaAtual = 3);

  @override
  Widget build(BuildContext context) {
    final telas = [
      HomeScreen(
        aoTocarProjetos: () => _irPara(1),
        aoTocarAnotacoes: () => _irPara(2),
        aoTocarConfiguracoes: _abrirConfiguracoes,
      ),
      ProjetosScreen(aoTocarConfiguracoes: _abrirConfiguracoes),
      AnotacoesScreen(aoTocarConfiguracoes: _abrirConfiguracoes),
      const PerfilScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _abaAtual, children: telas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,
        onDestinationSelected: _irPara,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Projetos',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Anotações',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
