import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/item.dart';

/// Editor de anotação/tarefa: título, conteúdo e a chave
/// público/privado. Serve tanto para criar quanto para editar — quem
/// chamar passando [itemExistente] entra no modo edição.
///
/// Devolve `true` via [Navigator.pop] quando algo foi salvo, pra quem
/// chamou saber que precisa recarregar a lista.
class AnotacaoEditorScreen extends StatefulWidget {
  final int? projetoId;
  final TipoItem tipoInicial;
  final Item? itemExistente;

  const AnotacaoEditorScreen({
    super.key,
    this.projetoId,
    this.tipoInicial = TipoItem.anotacao,
    this.itemExistente,
  });

  @override
  State<AnotacaoEditorScreen> createState() => _AnotacaoEditorScreenState();
}

class _AnotacaoEditorScreenState extends State<AnotacaoEditorScreen> {
  late TipoItem _tipo = widget.itemExistente?.tipo ?? widget.tipoInicial;
  late Visibilidade _visibilidade =
      widget.itemExistente?.visibilidade ?? Visibilidade.privada;
  late final _tituloController =
      TextEditingController(text: widget.itemExistente?.titulo ?? '');
  late final _conteudoController =
      TextEditingController(text: widget.itemExistente?.conteudo ?? '');
  bool _salvando = false;

  bool get _editando => widget.itemExistente != null;

  @override
  void dispose() {
    _tituloController.dispose();
    _conteudoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty || _salvando) return;

    setState(() => _salvando = true);
    final appState = context.read<AppState>();

    if (_editando) {
      final atualizado = widget.itemExistente!.copyWith(
        titulo: titulo,
        conteudo: _conteudoController.text.trim(),
        visibilidade: _visibilidade,
      );
      await appState.atualizarItem(atualizado);
    } else {
      await appState.criarItem(
        projetoId: widget.projetoId,
        tipo: _tipo,
        titulo: titulo,
        conteudo: _conteudoController.text.trim(),
        visibilidade: _visibilidade,
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  String get _tituloDaTela {
    if (_editando) {
      return _tipo == TipoItem.tarefa ? 'Editar tarefa' : 'Editar anotação';
    }
    return _tipo == TipoItem.tarefa ? 'Nova tarefa' : 'Nova anotação';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tituloDaTela),
        actions: [
          IconButton(
            icon: _salvando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _salvando ? null : _salvar,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // O tipo só é escolhido na criação — editar não troca
            // anotação por tarefa, pra não complicar o cálculo de
            // progresso do projeto.
            if (!_editando)
              SegmentedButton<TipoItem>(
                segments: const [
                  ButtonSegment(value: TipoItem.anotacao, label: Text('Anotação')),
                  ButtonSegment(value: TipoItem.tarefa, label: Text('Tarefa')),
                ],
                selected: {_tipo},
                onSelectionChanged: (selecionado) {
                  setState(() => _tipo = selecionado.first);
                },
              ),
            if (!_editando) const SizedBox(height: 16),
            TextField(
              controller: _tituloController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
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
              title: const Text('Pública'),
              subtitle: const Text(
                'Na versão teste isso é só um campo salvo no '
                'dispositivo — ainda não existe feed nem publicação.',
              ),
              value: _visibilidade == Visibilidade.publica,
              onChanged: (ativo) {
                setState(() {
                  _visibilidade =
                      ativo ? Visibilidade.publica : Visibilidade.privada;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
