import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/social_service.dart';
import '../data/social_state.dart';
import '../models/publicacao.dart';
import '../theme/app_cores.dart';
import '../utils/mensagens.dart';
import '../widgets/aviso_precisa_conta.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/cabecalho_da_aba.dart';
import '../widgets/cartao_publicacao.dart';
import 'criar_publicacao_screen.dart';
import 'perfil_publico_screen.dart';
import 'publicacao_detalhe_screen.dart';

class FeedScreen extends StatefulWidget {
  final VoidCallback? aoTocarConfiguracoes;

  const FeedScreen({super.key, this.aoTocarConfiguracoes});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _abas = TabController(length: 2, vsync: this);

  // Pesquisa de publicações por título: troca as abas por um campo + resultados.
  final _buscaController = TextEditingController();
  Timer? _espera;
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    // Só começa a conversar com a internet quando a pessoa abre o feed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final social = context.read<SocialState>();
      if (!social.logado) return;
      social.sincronizar(context.read<AppState>());
      social.carregarFeed(AbaFeed.seguindo);
      social.carregarFeed(AbaFeed.descobrir);
    });
  }

  @override
  void dispose() {
    _espera?.cancel();
    _buscaController.dispose();
    _abas.dispose();
    super.dispose();
  }

  Future<void> _novaPublicacao() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CriarPublicacaoScreen()),
    );
  }

  void _abrirBusca() => setState(() => _buscando = true);

  void _fecharBusca() {
    _espera?.cancel();
    _buscaController.clear();
    context.read<SocialState>().limparBusca();
    setState(() => _buscando = false);
  }

  /// Espera a pessoa parar de digitar um instante antes de consultar a internet.
  void _aoDigitar(String texto) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 450), () {
      if (mounted) context.read<SocialState>().buscarPublicacoes(texto);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    final logado = context.select<SocialState, bool>((s) => s.logado);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (logado && _buscando)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Fechar pesquisa',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _fecharBusca,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _buscaController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (t) {
                          setState(() {}); // atualiza o botão de limpar
                          _aoDigitar(t);
                        },
                        onSubmitted: (t) =>
                            context.read<SocialState>().buscarPublicacoes(t),
                        decoration: InputDecoration(
                          hintText: 'Título da publicação ou @usuário',
                          isDense: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          suffixIcon: _buscaController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _buscaController.clear();
                                    _aoDigitar('');
                                    setState(() {});
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              CabecalhoDaAba(
                titulo: 'Feed',
                subtitulo: 'O que a turma está estudando',
                aoTocarConfiguracoes: widget.aoTocarConfiguracoes,
                acoes: [
                  if (logado)
                    IconButton(
                      tooltip: 'Pesquisar publicações',
                      icon: const Icon(Icons.search),
                      onPressed: _abrirBusca,
                    ),
                ],
              ),
            if (!logado)
              const Expanded(child: AvisoPrecisaConta())
            else if (_buscando)
              const Expanded(child: _ListaDoFeed(aba: AbaFeed.busca))
            else ...[
              TabBar(
                controller: _abas,
                labelColor: tokens.abaAtiva,
                unselectedLabelColor: tokens.abaInativa,
                indicatorColor: tokens.abaIndicador,
                dividerColor: tokens.divisor,
                tabs: const [
                  Tab(text: 'Seguindo'),
                  Tab(text: 'Descobrir'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _abas,
                  children: [
                    _ListaDoFeed(
                      aba: AbaFeed.seguindo,
                      aoIrParaDescobrir: () => _abas.animateTo(1),
                    ),
                    const _ListaDoFeed(aba: AbaFeed.descobrir),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: logado
          ? FloatingActionButton.extended(
              onPressed: _novaPublicacao,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Publicar'),
            )
          : null,
    );
  }
}

class _ListaDoFeed extends StatelessWidget {
  final AbaFeed aba;
  final VoidCallback? aoIrParaDescobrir;

  const _ListaDoFeed({required this.aba, this.aoIrParaDescobrir});

  Future<void> _curtir(
      BuildContext context, SocialState social, Publicacao p) async {
    try {
      await social.alternarCurtida(p);
    } catch (e) {
      mostrarMensagem(context, SocialService.traduzirErro(e));
    }
  }

  Future<void> _excluir(
      BuildContext context, SocialState social, Publicacao p) async {
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
    if (confirmou != true || !context.mounted) return;
    try {
      await social.excluirPublicacao(p.id);
    } catch (e) {
      mostrarMensagem(context, SocialService.traduzirErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialState>(
      builder: (context, social, _) {
        final itens = social.itens(aba);

        if (!social.jaCarregou(aba) && social.carregando(aba)) {
          return const Center(child: CircularProgressIndicator());
        }
        if (social.erro(aba) != null && itens.isEmpty) {
          return _Mensagem(
            icone: Icons.cloud_off_outlined,
            texto: social.erro(aba)!,
            rotuloBotao: 'Tentar de novo',
            aoTocarBotao: () => social.carregarFeed(aba),
          );
        }

        // Pesquisa começando com "@": mostra pessoas em vez de publicações.
        if (aba == AbaFeed.busca && social.buscandoPessoas) {
          if (social.pessoasBusca.isEmpty) {
            return _Mensagem(
              icone: Icons.person_search_outlined,
              texto: social.termoBusca.replaceAll('@', '').isEmpty
                  ? 'Digite o @ de quem você procura.'
                  : 'Ninguém encontrado com "${social.termoBusca}".',
            );
          }
          return ListView.separated(
            itemCount: social.pessoasBusca.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, indice) {
              final pessoa = social.pessoasBusca[indice];
              return ListTile(
                leading: AvatarUsuario(
                  nome: pessoa.nome,
                  cor: pessoa.avatarCor,
                  imagemUrl: pessoa.avatarUrl,
                ),
                title: Text(pessoa.nome),
                subtitle:
                    pessoa.usuario != null ? Text('@${pessoa.usuario}') : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PerfilPublicoScreen(usuarioId: pessoa.id),
                  ),
                ),
              );
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () => social.carregarFeed(aba),
          child: itens.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 360,
                      child: _vazio(context),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: itens.length + 1,
                  itemBuilder: (context, indice) {
                    if (indice == itens.length) {
                      return _RodapeDaLista(
                        carregando: social.carregando(aba),
                        temMais: social.temMais(aba),
                        aoCarregarMais: () =>
                            social.carregarFeed(aba, maisAntigas: true),
                      );
                    }
                    final p = itens[indice];
                    final ehMinha = p.autor.id == social.meuId;
                    return CartaoPublicacao(
                      publicacao: p,
                      resumido: true,
                      aoCurtir: () => _curtir(context, social, p),
                      aoAbrir: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PublicacaoDetalheScreen(publicacao: p),
                        ),
                      ),
                      aoAbrirPerfil: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PerfilPublicoScreen(usuarioId: p.autor.id),
                        ),
                      ),
                      aoExcluir:
                          ehMinha ? () => _excluir(context, social, p) : null,
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _vazio(BuildContext context) {
    if (aba == AbaFeed.busca) {
      final termo = context.read<SocialState>().termoBusca;
      return _Mensagem(
        icone: Icons.search,
        texto: termo.isEmpty
            ? 'Digite parte do título para encontrar anotações e outras '
                'publicações da comunidade.'
            : 'Nenhuma publicação com "$termo" no título.',
      );
    }
    if (aba == AbaFeed.seguindo) {
      return _Mensagem(
        icone: Icons.people_outline,
        texto: 'Nada por aqui ainda. Siga colegas para ver o que eles '
            'compartilham — as suas publicações também aparecem aqui.',
        rotuloBotao: 'Descobrir pessoas',
        aoTocarBotao: aoIrParaDescobrir,
      );
    }
    return const _Mensagem(
      icone: Icons.auto_stories_outlined,
      texto: 'Ainda não há publicações. Que tal escrever a primeira?',
    );
  }
}

class _RodapeDaLista extends StatelessWidget {
  final bool carregando;
  final bool temMais;
  final VoidCallback aoCarregarMais;

  const _RodapeDaLista({
    required this.carregando,
    required this.temMais,
    required this.aoCarregarMais,
  });

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!temMais) return const SizedBox(height: 8);
    return Center(
      child: TextButton(
        onPressed: aoCarregarMais,
        child: const Text('Carregar mais'),
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  final IconData icone;
  final String texto;
  final String? rotuloBotao;
  final VoidCallback? aoTocarBotao;

  const _Mensagem({
    required this.icone,
    required this.texto,
    this.rotuloBotao,
    this.aoTocarBotao,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 44, color: tokens.iconeSuave),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: tokens.textoSecundario),
            ),
            if (rotuloBotao != null && aoTocarBotao != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: aoTocarBotao,
                child: Text(rotuloBotao!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
