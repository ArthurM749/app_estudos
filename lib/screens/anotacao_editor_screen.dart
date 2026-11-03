import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/regras_pontos.dart';
import '../models/evento_pontos.dart';
import '../models/item.dart';

class AnotacaoEditorScreen extends StatefulWidget {
  final int? projetoIdInicial;
  final Item? itemExistente;

  const AnotacaoEditorScreen({
    super.key,
    this.projetoIdInicial,
    this.itemExistente,
  });

  @override
  State<AnotacaoEditorScreen> createState() => _AnotacaoEditorScreenState();
}

class _AnotacaoEditorScreenState extends State<AnotacaoEditorScreen> {
  late Visibilidade _visibilidade =
      widget.itemExistente?.visibilidade ?? Visibilidade.privada;
  late int? _projetoIdSelecionado =
      widget.itemExistente?.projetoId ?? widget.projetoIdInicial;
  late final _tituloController =
      TextEditingController(text: widget.itemExistente?.titulo ?? '');
  late final _conteudoController =
      TextEditingController(text: widget.itemExistente?.conteudo ?? '');
  bool _salvando = false;
  bool _excluindo = false;

  bool get _editando => widget.itemExistente != null;

  @override
  void dispose() {
    _tituloController.dispose();
    _conteudoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty || _salvando || _excluindo) return;

    setState(() => _salvando = true);
    final appState = context.read<AppState>();

    if (_editando) {
      final atual = widget.itemExistente!;

      final atualizado = Item(
        id: atual.id,
        projetoId: _projetoIdSelecionado,
        tipo: atual.tipo,
        titulo: titulo,
        conteudo: _conteudoController.text.trim(),
        concluido: atual.concluido,
        visibilidade: _visibilidade,
        criadoEm: atual.criadoEm,
      );
      await appState.atualizarItem(atualizado);
    } else {
      await appState.criarItem(
        projetoId: _projetoIdSelecionado,
        tipo: TipoItem.anotacao,
        titulo: titulo,
        conteudo: _conteudoController.text.trim(),
        visibilidade: _visibilidade,
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _excluir() async {
    if (_salvando || _excluindo) return;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir anotação?'),
        content: const Text('Isso não pode ser desfeito.'),
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
    if (confirmou != true || !mounted) return;

    setState(() => _excluindo = true);
    await context.read<AppState>().excluirItem(widget.itemExistente!);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final projetos = context.watch<AppState>().projetos;
    final pontosAnotacao =
        RegrasDePontos.pontosPorAcao[TipoAcao.criarAnotacao] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar anotação' : 'Nova anotação'),
        actions: [
          if (_editando)
            IconButton(
              icon: _excluindo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: (_salvando || _excluindo) ? null : _excluir,
            ),
          IconButton(
            icon: _salvando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: (_salvando || _excluindo) ? null : _salvar,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              autofocus: !_editando,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            if (projetos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Projeto',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Sem projeto'),
                    selected: _projetoIdSelecionado == null,
                    onSelected: (_) =>
                        setState(() => _projetoIdSelecionado = null),
                  ),
                  ...projetos.map((projeto) {
                    return ChoiceChip(
                      avatar: CircleAvatar(
                        backgroundColor: Color(projeto.cor),
                        radius: 7,
                      ),
                      label: Text(projeto.nome),
                      selected: _projetoIdSelecionado == projeto.id,
                      onSelected: (_) =>
                          setState(() => _projetoIdSelecionado = projeto.id),
                    );
                  }),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _conteudoController,
                decoration: const InputDecoration(
                  labelText: 'Conteúdo',
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Anotação pública'),
              subtitle: const Text(
                'No futuro, anotações públicas poderão ser vistas e '
                'curtidas no feed.',
              ),
              value: _visibilidade == Visibilidade.publica,
              onChanged: (ativo) {
                setState(() {
                  _visibilidade =
                      ativo ? Visibilidade.publica : Visibilidade.privada;
                });
              },
            ),
            if (!_editando)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Você ganha $pontosAnotacao pontos ao criar uma anotação.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
