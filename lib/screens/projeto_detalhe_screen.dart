import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/database_helper.dart';
import '../models/item.dart';
import '../models/projeto.dart';
import 'anotacao_editor_screen.dart';

const _tiposPorAba = [TipoItem.anotacao, TipoItem.tarefa];

/// Detalhe de um projeto: abas internas de Anotações e Tarefas, mais
/// o controle de progresso (manual ou por tarefas).
class ProjetoDetalheScreen extends StatefulWidget {
  final Projeto projeto;

  const ProjetoDetalheScreen({super.key, required this.projeto});

  @override
  State<ProjetoDetalheScreen> createState() => _ProjetoDetalheScreenState();
}

class _ProjetoDetalheScreenState extends State<ProjetoDetalheScreen> {
  late List<Future<List<Item>>> _futurosPorAba;

  @override
  void initState() {
    super.initState();
    _recarregarTudo();
  }

  void _recarregarTudo() {
    _futurosPorAba = _tiposPorAba
        .map((tipo) => DatabaseHelper.instance
            .listarItens(projetoId: widget.projeto.id, tipo: tipo))
        .toList();
  }

  Future<void> _criarItem(BuildContext context, int indiceAba) async {
    final criou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AnotacaoEditorScreen(
          projetoId: widget.projeto.id,
          tipoInicial: _tiposPorAba[indiceAba],
        ),
      ),
    );
    if (criou == true && mounted) {
      setState(_recarregarTudo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final abaAtual = DefaultTabController.of(context);
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.projeto.nome),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Anotações'),
                  Tab(text: 'Tarefas'),
                ],
              ),
            ),
            body: Column(
              children: [
                _BarraDeProgresso(projeto: widget.projeto),
                Expanded(
                  child: TabBarView(
                    children: List.generate(2, (indice) {
                      return _ListaDeItens(
                        futuro: _futurosPorAba[indice],
                        tipo: _tiposPorAba[indice],
                        aoAlterar: () => setState(_recarregarTudo),
                      );
                    }),
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _criarItem(context, abaAtual.index),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}

class _BarraDeProgresso extends StatelessWidget {
  final Projeto projeto;

  const _BarraDeProgresso({required this.projeto});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final progresso = appState.progressoPorProjeto[projeto.id] ?? 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Progresso', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('$progresso%'),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: progresso / 100, minHeight: 8),
              ),
              if (projeto.modoProgresso == ModoProgresso.manual) ...[
                Slider(
                  value: progresso.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$progresso%',
                  onChanged: (valor) {
                    if (projeto.id != null) {
                      appState.definirProgressoManual(projeto.id!, valor.round());
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ListaDeItens extends StatelessWidget {
  final Future<List<Item>> futuro;
  final TipoItem tipo;
  final VoidCallback aoAlterar;

  const _ListaDeItens({
    required this.futuro,
    required this.tipo,
    required this.aoAlterar,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Item>>(
      future: futuro,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final itens = snapshot.data!;
        if (itens.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Nada aqui ainda. Toque no + para criar.'),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: itens.length,
          itemBuilder: (context, indice) {
            return _ItemTile(item: itens[indice], aoAlterar: aoAlterar);
          },
        );
      },
    );
  }
}

/// Uma linha de anotação ou tarefa, com os botões de editar e
/// excluir. Tarefas também mostram o checkbox de concluída.
class _ItemTile extends StatelessWidget {
  final Item item;
  final VoidCallback aoAlterar;

  const _ItemTile({required this.item, required this.aoAlterar});

  Future<void> _editar(BuildContext context) async {
    final editou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AnotacaoEditorScreen(
          projetoId: item.projetoId,
          tipoInicial: item.tipo,
          itemExistente: item,
        ),
      ),
    );
    if (editou == true) aoAlterar();
  }

  Future<void> _excluir(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir?'),
        content: Text('Isso vai apagar "${item.titulo}" e não pode ser desfeito.'),
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
    if (confirmou == true) {
      await context.read<AppState>().excluirItem(item);
      aoAlterar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ehTarefa = item.tipo == TipoItem.tarefa;

    return ListTile(
      leading: ehTarefa
          ? Checkbox(
              value: item.concluido,
              onChanged: (_) async {
                await context.read<AppState>().alternarConclusao(item);
                aoAlterar();
              },
            )
          : Icon(
              item.visibilidade == Visibilidade.publica
                  ? Icons.public
                  : Icons.lock_outline,
              size: 20,
            ),
      title: Text(
        item.titulo,
        style: (ehTarefa && item.concluido)
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: item.conteudo.isEmpty
          ? null
          : Text(item.conteudo, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _editar(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => _excluir(context),
          ),
        ],
      ),
    );
  }
}
