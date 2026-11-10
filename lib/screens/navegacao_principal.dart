import 'package:flutter/material.dart';

import 'anotacoes_screen.dart';
import 'configuracoes_screen.dart';
import 'feed_screen.dart';
import 'home_screen.dart';
import 'perfil_screen.dart';
import 'projetos_screen.dart';

// Ordem das abas. Os atalhos das outras telas (ex.: "ver projetos" no Início)
// passam por aqui, então mudar a ordem é só mexer nestes números.
const _abaInicio = 0;
const _abaFeed = 1;
const _abaProjetos = 2;
const _abaAnotacoes = 3;
const _abaPerfil = 4;

class NavegacaoPrincipal extends StatefulWidget {
  const NavegacaoPrincipal({super.key});

  @override
  State<NavegacaoPrincipal> createState() => _NavegacaoPrincipalState();
}

class _NavegacaoPrincipalState extends State<NavegacaoPrincipal> {
  int _abaAtual = _abaInicio;

  // O feed só é montado na primeira visita. O IndexedStack constrói todas as
  // abas de uma vez, e sem isso o app faria chamadas de internet logo ao abrir
  // — mesmo para quem só quer estudar offline.
  bool _feedJaAberto = false;

  // Mesma ideia para o Perfil (carrega perfil público da internet). A "versão"
  // muda a cada vez que a pessoa entra na aba vinda de outra, recriando a tela
  // para mostrar números atuais em vez de ficar com os da visita anterior.
  bool _perfilJaAberto = false;
  int _versaoPerfil = 0;

  void _irPara(int aba) {
    setState(() {
      if (aba == _abaPerfil && _abaAtual != _abaPerfil) _versaoPerfil++;
      _abaAtual = aba;
      if (aba == _abaFeed) _feedJaAberto = true;
      if (aba == _abaPerfil) _perfilJaAberto = true;
    });
  }

  // Configurações é uma tela própria (empilhada), aberta pela engrenagem.
  void _abrirConfiguracoes() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telas = [
      HomeScreen(
        aoTocarProjetos: () => _irPara(_abaProjetos),
        aoTocarAnotacoes: () => _irPara(_abaAnotacoes),
        aoTocarConfiguracoes: _abrirConfiguracoes,
      ),
      _feedJaAberto
          ? FeedScreen(aoTocarConfiguracoes: _abrirConfiguracoes)
          : const SizedBox.shrink(),
      ProjetosScreen(aoTocarConfiguracoes: _abrirConfiguracoes),
      AnotacoesScreen(aoTocarConfiguracoes: _abrirConfiguracoes),
      _perfilJaAberto
          ? PerfilScreen(
              key: ValueKey(_versaoPerfil),
              aoTocarConfiguracoes: _abrirConfiguracoes,
            )
          : const SizedBox.shrink(),
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
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed),
            label: 'Feed',
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
