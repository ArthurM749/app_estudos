import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/auth_service.dart';
import '../data/database_helper.dart';
import '../data/regras_pontos.dart';
import '../data/social_state.dart';
import '../models/evento_pontos.dart';
import '../models/item.dart';
import '../theme/app_cores.dart';

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
  /// A anotação já gravada no aparelho. Fica nula só até o primeiro "salvar" de
  /// uma anotação nova; depois disso, salvar de novo atualiza em vez de criar
  /// outra (importante quando publicar falha e a pessoa tenta de novo).
  late Item? _item = widget.itemExistente;

  late int? _projetoIdSelecionado =
      widget.itemExistente?.projetoId ?? widget.projetoIdInicial;
  late final _tituloController =
      TextEditingController(text: widget.itemExistente?.titulo ?? '');
  late final _conteudoController =
      TextEditingController(text: widget.itemExistente?.conteudo ?? '');
  bool _salvando = false;
  bool _excluindo = false;

  bool get _editando => _item != null;

  /// O que a pessoa escolheu (público ou privado). O envio para a nuvem pode
  /// ainda estar na fila — ver [_aguardandoEnvio].
  bool get _publicada => _item?.querPublicada ?? false;
  bool get _aguardandoEnvio => _item?.aguardandoEnvio ?? false;
  bool get _ocupado => _salvando || _excluindo;

  @override
  void dispose() {
    _tituloController.dispose();
    _conteudoController.dispose();
    super.dispose();
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Salva no aparelho (sempre, mesmo sem internet) e registra o que a pessoa
  /// quer: `true` publicar, `false` tornar privada, `null` manter como está.
  /// O envio para a nuvem é feito em seguida; se não houver internet, fica na
  /// fila e o app reenvia sozinho quando a conexão voltar.
  Future<void> _salvar({bool? publicar}) async {
    final titulo = _tituloController.text.trim();
    final conteudo = _conteudoController.text.trim();
    if (_ocupado) return;
    if (titulo.isEmpty) {
      _aviso('Dê um título para a anotação.');
      return;
    }
    final alvoPublicada = publicar ?? _publicada;
    if (alvoPublicada && conteudo.isEmpty) {
      _aviso('Escreva o conteúdo antes de publicar.');
      return;
    }
    if (publicar == true && AuthService.instance.usuarioAtual == null) {
      _aviso('Entre em uma conta para publicar anotações.');
      return;
    }

    setState(() => _salvando = true);
    final appState = context.read<AppState>();
    final social = context.read<SocialState>();
    final messenger = ScaffoldMessenger.of(context);

    // 1) Aparelho: grava o texto e a intenção. Nada depende de internet.
    final atual = _item;
    final novo = Item(
      id: atual?.id,
      projetoId: _projetoIdSelecionado,
      tipo: TipoItem.anotacao,
      titulo: titulo,
      conteudo: conteudo,
      concluido: atual?.concluido ?? false,
      visibilidade:
          alvoPublicada ? Visibilidade.publica : Visibilidade.privada,
      criadoEm: atual?.criadoEm ?? DateTime.now(),
      publicacaoId: atual?.publicacaoId,
      // Texto de uma anotação já publicada mudou: precisa ser reenviado.
      syncPendente: alvoPublicada && atual?.publicacaoId != null,
    );
    if (atual != null) {
      await appState.atualizarItem(novo);
      _item = novo;
    } else {
      final criado = await appState.criarItem(
        projetoId: novo.projetoId,
        tipo: TipoItem.anotacao,
        titulo: titulo,
        conteudo: conteudo,
        visibilidade: novo.visibilidade,
      );
      _item = criado;
    }

    // 2) Nuvem: tenta agora; o que não der fica na fila.
    final precisaEnviar = _item!.aguardandoEnvio;
    String? mensagemFinal;
    if (precisaEnviar) {
      final resultado = await social.processarFila();
      final restante = await DatabaseHelper.instance
          .listarAnotacoesPendentes()
          .then((l) => l.any((i) => i.id == _item!.id));
      if (resultado.erro != null) {
        if (!mounted) return;
        setState(() => _salvando = false);
        _aviso('Salvo no aparelho, mas a comunidade recusou: ${resultado.erro}');
        return;
      }
      if (restante) {
        mensagemFinal = AuthService.instance.usuarioAtual == null
            ? 'Salvo no aparelho. Será enviado quando você entrar na conta.'
            : 'Salvo no aparelho. Será enviado quando houver internet.';
      } else {
        mensagemFinal =
            alvoPublicada ? 'Anotação publicada.' : 'Anotação agora é privada.';
      }
    }

    if (mensagemFinal != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(mensagemFinal)));
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _confirmarPublicar() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publicar anotação?'),
        content: const Text(
          'Ela vai aparecer no feed e no seu perfil, e qualquer pessoa do '
          'app poderá ler, curtir e comentar. Você pode torná-la privada de '
          'novo quando quiser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
    if (confirmou == true) await _salvar(publicar: true);
  }

  Future<void> _confirmarTornarPrivada() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tornar privada?'),
        content: const Text(
          'A publicação sai do feed e do seu perfil (junto com as curtidas e '
          'comentários dela). A anotação continua salva no seu aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Tornar privada'),
          ),
        ],
      ),
    );
    if (confirmou == true) await _salvar(publicar: false);
  }

  Future<void> _excluir() async {
    if (_ocupado) return;
    final publicada = _publicada;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir anotação?'),
        content: Text(
          publicada
              ? 'Isso apaga a anotação do aparelho e também a publicação no '
                  'feed (se estiver sem internet, a publicação sai quando '
                  'voltar). Não pode ser desfeito.'
              : 'Isso não pode ser desfeito.',
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
    if (confirmou != true || !mounted) return;

    setState(() => _excluindo = true);
    // A anotação some do aparelho na hora; se estava publicada, a retirada da
    // nuvem acontece agora ou assim que houver internet.
    await context.read<SocialState>().excluirAnotacao(
          _item!,
          context.read<AppState>(),
        );
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
              tooltip: 'Excluir',
              icon: _excluindo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: _ocupado ? null : _excluir,
            ),
          IconButton(
            tooltip: 'Salvar',
            icon: _salvando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _ocupado ? null : () => _salvar(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BarraDePublicacao(
              publicada: _publicada,
              aguardandoEnvio: _aguardandoEnvio,
              ocupado: _ocupado,
              aoPublicar: _confirmarPublicar,
              aoTornarPrivada: _confirmarTornarPrivada,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 8),
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


/// Faixa no topo do editor: mostra se a anotação é privada ou publicada e
/// oferece o botão para mudar (sempre com confirmação).
class _BarraDePublicacao extends StatelessWidget {
  final bool publicada;
  final bool aguardandoEnvio;
  final bool ocupado;
  final VoidCallback aoPublicar;
  final VoidCallback aoTornarPrivada;

  const _BarraDePublicacao({
    required this.publicada,
    required this.aguardandoEnvio,
    required this.ocupado,
    required this.aoPublicar,
    required this.aoTornarPrivada,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    final tema = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: tokens.cartao,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.cartaoBorda),
      ),
      child: Row(
        children: [
          Icon(
            aguardandoEnvio
                ? Icons.cloud_upload_outlined
                : (publicada ? Icons.public : Icons.lock_outline),
            size: 20,
            color: publicada ? tokens.iconeDestaque : tokens.iconeSuave,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  publicada ? 'Publicada' : 'Privada',
                  style: tema.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  publicada
                      ? (aguardandoEnvio
                          ? 'Aguardando internet para aparecer no feed.'
                          : 'Aparece no feed e no seu perfil.')
                      : (aguardandoEnvio
                          ? 'Aguardando internet para sair do feed.'
                          : 'Só você vê esta anotação.'),
                  style:
                      tema.bodySmall?.copyWith(color: tokens.textoSecundario),
                ),
              ],
            ),
          ),
          if (publicada)
            TextButton(
              onPressed: ocupado ? null : aoTornarPrivada,
              child: const Text('Tornar privada'),
            )
          else
            FilledButton.tonalIcon(
              onPressed: ocupado ? null : aoPublicar,
              icon: const Icon(Icons.public, size: 18),
              label: const Text('Publicar'),
            ),
        ],
      ),
    );
  }
}
