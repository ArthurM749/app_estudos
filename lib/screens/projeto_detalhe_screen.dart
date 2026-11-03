import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/database_helper.dart';
import '../models/item.dart';
import '../models/projeto.dart';
import '../widgets/dialogo_projeto.dart';
import 'anotacao_editor_screen.dart';

class ProjetoDetalheScreen extends StatefulWidget {
  final int projetoId;

  const ProjetoDetalheScreen({super.key, required this.projetoId});

  @override
  State<ProjetoDetalheScreen> createState() => _ProjetoDetalheScreenState();
}

class _ProjetoDetalheScreenState extends State<ProjetoDetalheScreen> {
  final _novaTarefaController = TextEditingController();
  late Future<List<Item>> _futuroTarefas;
  late Future<List<Item>> _futuroAnotacoes;

  @override
  void initState() {
    super.initState();
    _recarregarItens();
  }

  @override
  void dispose() {
    _novaTarefaController.dispose();
    super.dispose();
  }

  void _recarregarItens() {
    _futuroTarefas = DatabaseHelper.instance
        .listarItens(projetoId: widget.projetoId, tipo: TipoItem.tarefa);
    _futuroAnotacoes = DatabaseHelper.instance
        .listarItens(projetoId: widget.projetoId, tipo: TipoItem.anotacao);
  }

  Future<void> _adicionarTarefa() async {
    final titulo = _novaTarefaController.text.trim();
    if (titulo.isEmpty) return;
    _novaTarefaController.clear();
    await context.read<AppState>().criarItem(
          projetoId: widget.projetoId,
          tipo: TipoItem.tarefa,
          titulo: titulo,
        );
    if (mounted) setState(_recarregarItens);
  }

  Future<void> _alternarTarefa(Item tarefa) async {
    await context.read<AppState>().alternarConclusao(tarefa);
    if (mounted) setState(_recarregarItens);
  }

  Future<void> _excluirTarefa(Item tarefa) async {
    await context.read<AppState>().excluirItem(tarefa);
    if (mounted) setState(_recarregarItens);
  }

  Future<void> _novaAnotacao() async {
    final criou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AnotacaoEditorScreen(projetoIdInicial: widget.projetoId),
      ),
    );
    if (criou == true && mounted) setState(_recarregarItens);
  }

  Future<void> _editarAnotacao(Item anotacao) async {
    final editou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AnotacaoEditorScreen(itemExistente: anotacao),
      ),
    );
    if (editou == true && mounted) setState(_recarregarItens);
  }

  Future<void> _excluirProjeto(Projeto projeto) async {
    final excluiu = await confirmarExclusaoProjeto(context, projeto);
    if (excluiu && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final indice =
            appState.projetos.indexWhere((p) => p.id == widget.projetoId);

        if (indice == -1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final projeto = appState.projetos[indice];
        final progresso = appState.progressoPorProjeto[projeto.id] ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(projeto.nome),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    abrirDialogoProjeto(context, projetoExistente: projeto),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _excluirProjeto(projeto),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CartaoProgresso(projeto: projeto, progresso: progresso),
              const SizedBox(height: 24),
              Text(
                'Tarefas',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _novaTarefaController,
                      decoration: const InputDecoration(
                        hintText: 'Adicionar tarefa...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _adicionarTarefa(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    onPressed: _adicionarTarefa,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FutureBuilder<List<Item>>(
                future: _futuroTarefas,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final tarefas = snapshot.data!;
                  if (tarefas.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Nenhuma tarefa ainda.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return Column(
                    children: tarefas.map((tarefa) {
                      return _LinhaDeTarefa(
                        tarefa: tarefa,
                        aoAlternar: () => _alternarTarefa(tarefa),
                        aoExcluir: () => _excluirTarefa(tarefa),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Anotações do projeto',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Item>>(
                future: _futuroAnotacoes,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final anotacoes = snapshot.data!;
                  if (anotacoes.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Nenhuma anotação neste projeto ainda.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: anotacoes.map((anotacao) {
                        return ListTile(
                          leading: Icon(
                            anotacao.visibilidade == Visibilidade.publica
                                ? Icons.public
                                : Icons.lock_outline,
                            size: 20,
                          ),
                          title: Text(anotacao.titulo),
                          subtitle: anotacao.conteudo.isEmpty
                              ? null
                              : Text(
                                  anotacao.conteudo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _editarAnotacao(anotacao),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _novaAnotacao,
                icon: const Icon(Icons.add),
                label: const Text('Nova anotação'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartaoProgresso extends StatelessWidget {
  final Projeto projeto;
  final int progresso;

  const _CartaoProgresso({required this.projeto, required this.progresso});

  @override
  Widget build(BuildContext context) {
    final automatico = projeto.modoProgresso == ModoProgresso.porTarefas;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progresso',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '$progresso%',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child:
                  LinearProgressIndicator(value: progresso / 100, minHeight: 8),
            ),
            const SizedBox(height: 6),
            Text(
              automatico
                  ? 'Calculado automaticamente pelas tarefas concluídas.'
                  : 'Progresso definido manualmente — arraste a barra abaixo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (!automatico)
              Slider(
                value: progresso.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$progresso%',
                onChanged: (valor) {
                  if (projeto.id != null) {
                    context
                        .read<AppState>()
                        .definirProgressoManual(projeto.id!, valor.round());
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LinhaDeTarefa extends StatelessWidget {
  final Item tarefa;
  final VoidCallback aoAlternar;
  final VoidCallback aoExcluir;

  const _LinhaDeTarefa({
    required this.tarefa,
    required this.aoAlternar,
    required this.aoExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Row(
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: aoAlternar,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              tarefa.concluido ? Icons.check_circle : Icons.circle_outlined,
              color: tarefa.concluido ? cores.primary : cores.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            tarefa.titulo,
            style: tarefa.concluido
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: cores.onSurfaceVariant,
                  )
                : null,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: aoExcluir,
        ),
      ],
    );
  }
}
