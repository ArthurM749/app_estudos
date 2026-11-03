import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../widgets/cabecalho_da_aba.dart';
import '../widgets/dialogo_projeto.dart';
import '../widgets/erro_de_carregamento.dart';
import 'projeto_detalhe_screen.dart';

class ProjetosScreen extends StatelessWidget {
  final VoidCallback? aoTocarConfiguracoes;

  const ProjetosScreen({super.key, this.aoTocarConfiguracoes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CabecalhoDaAba(
              titulo: 'Projetos',
              aoTocarConfiguracoes: aoTocarConfiguracoes,
            ),
            Expanded(
              child: Consumer<AppState>(
                builder: (context, appState, _) {
                  if (appState.carregando) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (appState.erro != null) {
                    return ErroDeCarregamento(mensagem: appState.erro!);
                  }
                  if (appState.projetos.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Nenhum projeto ainda. Toque no + para criar o primeiro.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: appState.projetos.length,
                    itemBuilder: (context, indice) {
                      final projeto = appState.projetos[indice];
                      final progresso =
                          appState.progressoPorProjeto[projeto.id] ?? 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading:
                              CircleAvatar(backgroundColor: Color(projeto.cor)),
                          title: Text(projeto.nome),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8, right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progresso / 100,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$progresso%'),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => abrirDialogoProjeto(context,
                                    projetoExistente: projeto),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete_outline, size: 20),
                                onPressed: () =>
                                    confirmarExclusaoProjeto(context, projeto),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProjetoDetalheScreen(
                                    projetoId: projeto.id!),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => abrirDialogoProjeto(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
