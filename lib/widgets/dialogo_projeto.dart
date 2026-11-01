import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/projeto.dart';
import '../screens/projeto_detalhe_screen.dart';

const coresDeProjeto = [
  Colors.indigo,
  Colors.teal,
  Colors.deepOrange,
  Colors.purple,
  Colors.green,
  Colors.pink,
];

/// Abre o formulário de criar (ou editar, quando [projetoExistente] é
/// passado) um projeto: nome, cor e o modo de progresso (manual ou
/// por tarefas). Usado tanto na tela de Projetos quanto no atalho
/// "Novo projeto" do Início e no botão de editar do detalhe do
/// projeto — assim o comportamento é sempre o mesmo em todo o app.
Future<void> abrirDialogoProjeto(
  BuildContext context, {
  Projeto? projetoExistente,
}) async {
  final appState = context.read<AppState>();
  final controller = TextEditingController(text: projetoExistente?.nome ?? '');
  var corEscolhida = projetoExistente != null
      ? coresDeProjeto.firstWhere(
          (c) => c.value == projetoExistente.cor,
          orElse: () => coresDeProjeto.first,
        )
      : coresDeProjeto.first;
  var modoEscolhido = projetoExistente?.modoProgresso ?? ModoProgresso.porTarefas;

  final confirmou = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return AlertDialog(
            title: Text(projetoExistente == null ? 'Novo projeto' : 'Editar projeto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Nome do projeto'),
                    onChanged: (_) => setStateDialog(() {}),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: coresDeProjeto.map((cor) {
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
                  const SizedBox(height: 16),
                  const Text('Progresso definido por', style: TextStyle(fontWeight: FontWeight.w600)),
                  RadioListTile<ModoProgresso>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Tarefas concluídas (automático)'),
                    value: ModoProgresso.porTarefas,
                    groupValue: modoEscolhido,
                    onChanged: (valor) => setStateDialog(() => modoEscolhido = valor!),
                  ),
                  RadioListTile<ModoProgresso>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Manual (arrastar a barrinha)'),
                    value: ModoProgresso.manual,
                    groupValue: modoEscolhido,
                    onChanged: (valor) => setStateDialog(() => modoEscolhido = valor!),
                  ),
                ],
              ),
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
                child: Text(projetoExistente == null ? 'Criar' : 'Salvar'),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmou != true || !context.mounted) return;
  final nome = controller.text.trim();
  if (nome.isEmpty) return;

  if (projetoExistente == null) {
    final criado = await appState.criarProjeto(
      nome: nome,
      cor: corEscolhida.value,
      modoProgresso: modoEscolhido,
    );
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProjetoDetalheScreen(projetoId: criado.id!)),
      );
    }
  } else {
    await appState.editarProjeto(
      projetoId: projetoExistente.id!,
      nome: nome,
      cor: corEscolhida.value,
      modoProgresso: modoEscolhido,
    );
  }
}

/// Pede confirmação e exclui o projeto. Devolve `true` se excluiu.
Future<bool> confirmarExclusaoProjeto(BuildContext context, Projeto projeto) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Excluir projeto?'),
      content: Text(
        'Isso vai apagar "${projeto.nome}". As anotações e tarefas dele '
        'deixam de pertencer a um projeto, mas continuam existindo.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );

  if (confirmou != true || !context.mounted) return false;
  await context.read<AppState>().excluirProjeto(projeto.id!);
  return true;
}
