import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/projeto.dart';
import '../widgets/erro_de_carregamento.dart';
import 'projeto_detalhe_screen.dart';

class ProjetosScreen extends StatelessWidget {
  const ProjetosScreen({super.key});

  Future<void> _abrirCriacaoDeProjeto(BuildContext context) async {
    final appState = context.read<AppState>();
    final controller = TextEditingController();
    final cores = [
      Colors.indigo,
      Colors.teal,
      Colors.deepOrange,
      Colors.purple,
      Colors.green,
    ];
    var corEscolhida = cores.first;

    final criado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: const Text('Novo projeto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Nome do projeto'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: cores.map((cor) {
                      final selecionada = cor.value == corEscolhida.value;
                      return GestureDetector(
                        onTap: () => setStateDialog(() => corEscolhida = cor),
                        child: CircleAvatar(
                          backgroundColor: cor,
                          radius: selecionada ? 18 : 14,
                          child: selecionada
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: controller.text.trim().isEmpty
                      ? null
                      : () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Criar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (criado != true || !context.mounted) return;

    final nome = controller.text.trim();
    if (nome.isEmpty) return;

    final projeto = await appState.criarProjeto(
      nome: nome,
      cor: corEscolhida.value,
    );

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProjetoDetalheScreen(projeto: projeto)),
    );
  }

  Future<void> _editarProjeto(BuildContext context, Projeto projeto) async {
    final appState = context.read<AppState>();
    final controller = TextEditingController(text: projeto.nome);
    final cores = [
      Colors.indigo,
      Colors.teal,
      Colors.deepOrange,
      Colors.purple,
      Colors.green,
    ];
    var corEscolhida = Color(projeto.cor);

    final salvou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar projeto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Nome do projeto'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: cores.map((cor) {
                      final selecionada = cor.value == corEscolhida.value;
                      return GestureDetector(
                        onTap: () => setStateDialog(() => corEscolhida = cor),
                        child: CircleAvatar(
                          backgroundColor: cor,
                          radius: selecionada ? 18 : 14,
                          child: selecionada
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: controller.text.trim().isEmpty
                      ? null
                      : () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (salvou != true || !context.mounted) return;

    final nome = controller.text.trim();
    if (nome.isEmpty) return;

    final atualizado = projeto.copyWith(
      nome: nome,
      cor: corEscolhida.value,
    );

    await appState.atualizarProjeto(atualizado);
  }

  Future<void> _confirmarExclusao(BuildContext context, Projeto projeto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir projeto'),
        content: Text('Tem certeza que deseja excluir "${projeto.nome}"?\nEssa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await context.read<AppState>().excluirProjeto(projeto.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projetos')),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.carregando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (appState.erro != null) {
            return ErroDeCarregamento(mensagem: appState.erro!);
          }
          if (appState.projetos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum projeto ainda. Toque no + para criar o primeiro.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appState.projetos.length,
            itemBuilder: (context, indice) {
              final projeto = appState.projetos[indice];
              final progresso = appState.progressoPorProjeto[projeto.id] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Color(projeto.cor)),
                  title: Text(projeto.nome),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
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
                      PopupMenuButton<String>(
                        onSelected: (valor) {
                          if (valor == 'editar') {
                            _editarProjeto(context, projeto);
                          } else if (valor == 'excluir') {
                            _confirmarExclusao(context, projeto);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'editar',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'excluir',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Excluir', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProjetoDetalheScreen(projeto: projeto),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirCriacaoDeProjeto(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}