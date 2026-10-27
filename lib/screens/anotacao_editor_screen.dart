import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/item.dart';

/// Editor de anotação/tarefa/ideia: título, conteúdo, seletor de
/// tipo e a chave público/privado.
///
/// [projetoId] vem preenchido quando a tela é aberta de dentro de um
/// projeto; fica nulo quando o item é criado solto. Devolve `true`
/// via [Navigator.pop] quando algo foi salvo, pra quem chamou saber
/// que precisa recarregar a lista.
class AnotacaoEditorScreen extends StatefulWidget {
  final int? projetoId;
  final TipoItem tipoInicial;

  const AnotacaoEditorScreen({
    super.key,
    this.projetoId,
    this.tipoInicial = TipoItem.anotacao,
  });

  @override
  State<AnotacaoEditorScreen> createState() => _AnotacaoEditorScreenState();
}

class _AnotacaoEditorScreenState extends State<AnotacaoEditorScreen> {
  late TipoItem _tipo = widget.tipoInicial;
  Visibilidade _visibilidade = Visibilidade.privada;
  final _tituloController = TextEditingController();
  final _conteudoController = TextEditingController();
  bool _salvando = false;

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

    await context.read<AppState>().criarItem(
          projetoId: widget.projetoId,
          tipo: _tipo,
          titulo: titulo,
          conteudo: _conteudoController.text.trim(),
          visibilidade: _visibilidade,
        );

    if (mounted) Navigator.of(context).pop(true);
  }

  String get _tituloDaTela {
    switch (_tipo) {
      case TipoItem.anotacao:
        return 'Nova anotação';
      case TipoItem.tarefa:
        return 'Nova tarefa';
      case TipoItem.ideia:
        return 'Nova ideia';
    }
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
            SegmentedButton<TipoItem>(
              segments: const [
                ButtonSegment(value: TipoItem.anotacao, label: Text('Anotação')),
                ButtonSegment(value: TipoItem.tarefa, label: Text('Tarefa')),
                ButtonSegment(value: TipoItem.ideia, label: Text('Ideia')),
              ],
              selected: {_tipo},
              onSelectionChanged: (selecionado) {
                setState(() => _tipo = selecionado.first);
              },
            ),
            const SizedBox(height: 16),
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
