import 'package:flutter/material.dart';

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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Estudos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
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
                    ProjetosScreen(
                      aoTocarConfiguracoes: aoTocarConfiguracoes,
                    ),
                    AnotacoesScreen(
                      aoTocarConfiguracoes: aoTocarConfiguracoes,
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
