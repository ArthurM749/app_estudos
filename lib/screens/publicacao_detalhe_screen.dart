import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/social_service.dart';
import '../data/social_state.dart';
import '../models/publicacao.dart';
import '../theme/app_cores.dart';
import '../utils/formatadores.dart';
import '../utils/mensagens.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/cartao_publicacao.dart';
import '../widgets/titulo_secao.dart';
import 'perfil_publico_screen.dart';

/// Publicação aberta, com a lista de comentários e o campo para comentar.
class PublicacaoDetalheScreen extends StatefulWidget {
  final Publicacao publicacao;

  const PublicacaoDetalheScreen({super.key, required this.publicacao});

  @override
  State<PublicacaoDetalheScreen> createState() =>
      _PublicacaoDetalheScreenState();
}

class _PublicacaoDetalheScreenState extends State<PublicacaoDetalheScreen> {
  late Publicacao _post = widget.publicacao;
  final _comentarioController = TextEditingController();

  List<Comentario> _comentarios = [];
  bool _carregando = true;
  String? _erro;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _carregarComentarios();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _carregarComentarios() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista =
          await SocialService.instance.listarComentarios(_post.id);
      if (!mounted) return;
      setState(() {
        _comentarios = lista;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = SocialService.traduzirErro(e);
        _carregando = false;
      });
    }
  }

  Future<void> _curtir() async {
    try {
      final atualizada =
          await context.read<SocialState>().alternarCurtida(_post);
      if (!mounted) return;
      setState(() => _post = atualizada);
    } catch (e) {
      mostrarMensagem(context, SocialService.traduzirErro(e));
    }
  }

  Future<void> _comentar() async {
    final texto = _comentarioController.text.trim();
    if (texto.isEmpty || _enviando) return;
    final social = context.read<SocialState>();

    setState(() => _enviando = true);
    try {
      await SocialService.instance.comentar(_post.id, texto);
      _comentarioController.clear();
      social.ajustarComentarios(_post.id, 1);
      final lista =
          await SocialService.instance.listarComentarios(_post.id);
      if (!mounted) return;
      setState(() {
        _comentarios = lista;
        _post = _post.copyWith(comentarios: lista.length);
        _enviando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarMensagem(context, SocialService.traduzirErro(e));
    }
  }

  Future<void> _excluirComentario(Comentario comentario) async {
    final social = context.read<SocialState>();
    try {
      await SocialService.instance.excluirComentario(comentario.id);
      social.ajustarComentarios(_post.id, -1);
      if (!mounted) return;
      setState(() {
        _comentarios = _comentarios.where((c) => c.id != comentario.id).toList();
        _post = _post.copyWith(comentarios: _comentarios.length);
      });
    } catch (e) {
      mostrarMensagem(context, SocialService.traduzirErro(e));
    }
  }

  void _abrirPerfil(String usuarioId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PerfilPublicoScreen(usuarioId: usuarioId),
      ),
    );
  }

  Future<void> _excluirPublicacao() async {
    final social = context.read<SocialState>();
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir publicação?'),
        content: const Text(
            'Ela some do feed para todo mundo. Não dá para desfazer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: dialogContext.coresApp.estiloBotaoPerigo,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      await social.excluirPublicacao(_post.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      mostrarMensagem(context, SocialService.traduzirErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    final meuId = SocialService.instance.meuId;
    final souAutor = _post.autor.id == meuId;

    return Scaffold(
      appBar: AppBar(title: const Text('Publicação')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CartaoPublicacao(
                  publicacao: _post,
                  aoCurtir: _curtir,
                  aoAbrirPerfil: () => _abrirPerfil(_post.autor.id),
                  aoExcluir: souAutor ? _excluirPublicacao : null,
                ),
                const SizedBox(height: 8),
                const TituloSecao('Comentários'),
                const SizedBox(height: 12),
                if (_carregando)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_erro != null)
                  Column(
                    children: [
                      Text(_erro!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: tokens.perigo)),
                      TextButton(
                        onPressed: _carregarComentarios,
                        child: const Text('Tentar de novo'),
                      ),
                    ],
                  )
                else if (_comentarios.isEmpty)
                  Text(
                    'Nenhum comentário ainda.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: tokens.textoSecundario),
                  )
                else
                  for (final comentario in _comentarios)
                    _LinhaComentario(
                      comentario: comentario,
                      podeExcluir: comentario.autor.id == meuId || souAutor,
                      aoAbrirPerfil: () => _abrirPerfil(comentario.autor.id),
                      aoExcluir: () => _excluirComentario(comentario),
                    ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _comentarioController,
                      maxLength: 500,
                      maxLines: 3,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Escreva um comentário...',
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Enviar comentário',
                    onPressed: _enviando ? null : _comentar,
                    icon: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaComentario extends StatelessWidget {
  final Comentario comentario;
  final bool podeExcluir;
  final VoidCallback aoAbrirPerfil;
  final VoidCallback aoExcluir;

  const _LinhaComentario({
    required this.comentario,
    required this.podeExcluir,
    required this.aoAbrirPerfil,
    required this.aoExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    final tema = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarUsuario(
            nome: comentario.autor.nome,
            cor: comentario.autor.avatarCor,
            raio: 15,
            aoTocar: aoAbrirPerfil,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: aoAbrirPerfil,
                  child: Text(
                    comentario.autor.nome,
                    style:
                        tema.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  formatarDataHora(comentario.criadoEm),
                  style: tema.bodySmall?.copyWith(color: tokens.textoSecundario),
                ),
                const SizedBox(height: 4),
                Text(comentario.conteudo, style: tema.bodyMedium),
              ],
            ),
          ),
          if (podeExcluir)
            IconButton(
              tooltip: 'Excluir comentário',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete_outline,
                  size: 20, color: tokens.iconeSuave),
              onPressed: aoExcluir,
            ),
        ],
      ),
    );
  }
}
