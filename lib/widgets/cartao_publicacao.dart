import 'package:flutter/material.dart';

import '../models/publicacao.dart';
import '../theme/app_cores.dart';
import '../utils/formatadores.dart';
import '../utils/icones_conquistas.dart';
import 'avatar_usuario.dart';

/// Cartão de uma publicação (feed, perfil e detalhe). Só desenha: quem decide o
/// que acontece ao tocar é a tela que o usa, via callbacks.
class CartaoPublicacao extends StatelessWidget {
  final Publicacao publicacao;
  final VoidCallback? aoCurtir;
  final VoidCallback? aoAbrir;
  final VoidCallback? aoAbrirPerfil;

  /// Se não for nulo, mostra o menu "Excluir" (só para o autor).
  final VoidCallback? aoExcluir;

  const CartaoPublicacao({
    super.key,
    required this.publicacao,
    this.aoCurtir,
    this.aoAbrir,
    this.aoAbrirPerfil,
    this.aoExcluir,
  });

  IconData _iconeDoTipo() {
    switch (publicacao.tipo) {
      case TipoPublicacao.projetoConcluido:
        return Icons.task_alt;
      case TipoPublicacao.conquista:
        return iconeDaConquista(publicacao.metaConquistaId);
      case TipoPublicacao.sequencia:
        return Icons.local_fire_department;
      case TipoPublicacao.evolucao:
        return Icons.trending_up;
      case TipoPublicacao.texto:
        return Icons.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    final tema = Theme.of(context).textTheme;
    final autor = publicacao.autor;
    final subtitulo = [
      if (autor.usuario != null) '@${autor.usuario}',
      formatarDataHora(publicacao.criadoEm),
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoAbrir,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    AvatarUsuario(
                      nome: autor.nome,
                      cor: autor.avatarCor,
                      aoTocar: aoAbrirPerfil,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: aoAbrirPerfil,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              autor.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tema.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              subtitulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tema.bodySmall
                                  ?.copyWith(color: tokens.textoSecundario),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (aoExcluir != null)
                      PopupMenuButton<String>(
                        tooltip: 'Mais opções',
                        icon: Icon(Icons.more_vert, color: tokens.iconeSuave),
                        onSelected: (_) => aoExcluir!(),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'excluir',
                            child: Text('Excluir publicação'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (publicacao.tipo != TipoPublicacao.texto) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.emblemaFundo,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(_iconeDoTipo(),
                            color: tokens.emblemaIcone, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (publicacao.metaTitulo != null)
                                Text(
                                  publicacao.metaTitulo!,
                                  style: tema.titleSmall?.copyWith(
                                    color: tokens.emblemaTexto,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (publicacao.metaDetalhe != null)
                                Text(
                                  publicacao.metaDetalhe!,
                                  style: tema.bodySmall
                                      ?.copyWith(color: tokens.emblemaTexto),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(publicacao.conteudo, style: tema.bodyLarge),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _Acao(
                    icone: publicacao.curtidaPorMim
                        ? Icons.favorite
                        : Icons.favorite_border,
                    cor: publicacao.curtidaPorMim
                        ? tokens.curtida
                        : tokens.iconeSuave,
                    rotulo: '${publicacao.curtidas}',
                    dica: publicacao.curtidaPorMim ? 'Descurtir' : 'Curtir',
                    aoTocar: aoCurtir,
                  ),
                  const SizedBox(width: 8),
                  _Acao(
                    icone: Icons.chat_bubble_outline,
                    cor: tokens.iconeSuave,
                    rotulo: '${publicacao.comentarios}',
                    dica: 'Comentários',
                    aoTocar: aoAbrir,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Acao extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String rotulo;
  final String dica;
  final VoidCallback? aoTocar;

  const _Acao({
    required this.icone,
    required this.cor,
    required this.rotulo,
    required this.dica,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: aoTocar,
      style: TextButton.styleFrom(
        foregroundColor: cor,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(48, 40),
      ),
      icon: Icon(icone, size: 20, semanticLabel: dica),
      label: Text(rotulo),
    );
  }
}
