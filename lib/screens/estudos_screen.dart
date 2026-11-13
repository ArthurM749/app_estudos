import 'package:flutter/material.dart';

import '../widgets/cabecalho_da_aba.dart';
import 'anotacoes_screen.dart';
import 'projetos_screen.dart';

class EstudosScreen extends StatelessWidget {
  final int abaInicial;
  final VoidCallback? aoTocarConfiguracoes;

  const EstudosScreen({
    super.key,
    this.abaInicial = 0,
    this.aoTocarConfiguracoes,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: abaInicial == 1 ? 1 : 0,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              CabecalhoDaAba(
                titulo: 'Estudos',
                aoTocarConfiguracoes: aoTocarConfiguracoes,
              ),
              TabBar(
                tabs: const [
                  Tab(text: 'Projetos', icon: Icon(Icons.folder_outlined)),
                  Tab(
                    text: 'Anotações',
                    icon: Icon(Icons.edit_note_outlined),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Cabeçalho e botão de criar já são da seção Estudos e do +
                    // central; as telas existentes são reaproveitadas como estão.
                    ProjetosScreen(
                      mostrarCabecalho: false,
                      mostrarBotaoCriar: false,
                    ),
                    AnotacoesScreen(
                      mostrarCabecalho: false,
                      mostrarBotaoCriar: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
