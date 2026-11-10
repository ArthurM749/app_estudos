import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/social_service.dart';
import '../data/social_state.dart';
import '../models/conquista.dart';
import '../models/perfil_social.dart';
import '../models/publicacao.dart';
import '../theme/app_cores.dart';
import '../utils/formatadores.dart';
import '../utils/icones_conquistas.dart';
import '../utils/mensagens.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/cabecalho_da_aba.dart';
import '../widgets/cartao_publicacao.dart';
import '../widgets/titulo_secao.dart';
import 'editar_perfil_publico_screen.dart';
import 'lista_pessoas_screen.dart';
import 'publicacao_detalhe_screen.dart';

/// Perfil público de alguém. Quando o id é o da própria pessoa, vira o "meu
/// perfil": mostra exatamente o que os outros enxergam (a função do banco não
/// abre exceção para o dono) e oferece o botão de editar.
///
/// No próprio perfil, o que está desligado na privacidade continua aparecendo
/// para o dono, marcado com um cadeado ("só você vê").
///
/// Com [embutido] a tela é usada como aba (sem AppBar, com o cabeçalho padrão
/// das abas e a engrenagem de configurações).
class PerfilPublicoScreen extends StatefulWidget {
  final String usuarioId;
  final bool embutido;
  final VoidCallback? aoTocarConfiguracoes;

  const PerfilPublicoScreen({
    super.key,
    required this.usuarioId,
    this.embutido = false,
    this.aoTocarConfiguracoes,
  });

  @override
  State<PerfilPublicoScreen> createState() => _PerfilPublicoScreenState();
}

class _PerfilPublicoScreenState extends State<PerfilPublicoScreen> {
  PerfilPublico? _perfil;
  List<ProjetoPublico> _projetos = [];
  List<Publicacao> _publicacoes = [];
  bool _carregando = true;
  bool _alternandoSeguir = false;
  String? _erro;

  bool get _ehMeu => widget.usuarioId == SocialService.instance.meuId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final servico = SocialService.instance;
    try {
      if (_ehMeu) {
        // Envia os números atuais antes de ler, para o que os outros veem não
        // ficar defasado. A própria sincronização limita a frequência (2 min).
        final social = context.read<SocialState>();
        await social.sincronizar(context.read<AppState>());
        await social.carregarMeuPerfil();
        if (!mounted) return;
      }
      final resultados = await Future.wait([
        servico.perfilPublico(widget.usuarioId),
        servico.projetosPublicosDe(widget.usuarioId),
        servico.listarPublicacoes(autorId: widget.usuarioId, limite: 10),
      ]);
      if (!mounted) return;
      setState(() {
        _perfil = resultados[0] as PerfilPublico?;
        _projetos = resultados[1] as List<ProjetoPublico>;
        _publicacoes = resultados[2] as List<Publicacao>;
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

  Future<void> _alternarSeguir() async {
    final perfil = _perfil;
    if (perfil == null || _alternandoSeguir) return;
    final social = context.read<SocialState>();
    final servico = SocialService.instance;
    final vaiSeguir = !perfil.euSigo;

    setState(() {
      _alternandoSeguir = true;
      _perfil = perfil.copyWith(
        euSigo: vaiSeguir,
        seguidores: perfil.seguidores + (vaiSeguir ? 1 : -1),
      );
    });
    try {
      if (vaiSeguir) {
        await servico.seguir(perfil.id);
      } else {
        await servico.deixarDeSeguir(perfil.id);
      }
      // A aba "Seguindo" do feed passa a refletir a mudança.
      social.carregarFeed(AbaFeed.seguindo);
    } catch (e) {
      if (!mounted) return;
      setState(() => _perfil = perfil);
      mostrarMensagem(context, SocialService.traduzirErro(e));
    }
    if (mounted) setState(() => _alternandoSeguir = false);
  }

  Future<void> _curtir(Publicacao publicacao) async {
    try {
      final atualizada =
          await context.read<SocialState>().alternarCurtida(publicacao);
      if (!mounted) return;
      setState(() {
        _publicacoes = [
          for (final p in _publicacoes) p.id == atualizada.id ? atualizada : p,
        ];
      });
    } catch (e) {
      mostrarMensagem(context, SocialService.traduzirErro(e));
    }
  }

  Future<void> _editar() async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditarPerfilPublicoScreen()),
    );
    if (salvou == true && mounted) _carregar();
  }

  void _abrirLista(ModoLista modo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ListaPessoasScreen(modo: modo, usuarioId: widget.usuarioId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfil = _perfil;
    final conteudo = _carregando
        ? const Center(child: CircularProgressIndicator())
        : _erro != null
            ? _Falha(mensagem: _erro!, aoTentarDeNovo: _carregar)
            : perfil == null
                ? const _Falha(mensagem: 'Perfil não encontrado.')
                : RefreshIndicator(
                    onRefresh: _carregar,
                    child: _corpo(context, perfil),
                  );

    if (widget.embutido) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              CabecalhoDaAba(
                titulo: 'Perfil',
                aoTocarConfiguracoes: widget.aoTocarConfiguracoes,
              ),
              Expanded(child: conteudo),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: conteudo,
    );
  }

  Widget _corpo(BuildContext context, PerfilPublico perfil) {
    final tokens = context.coresApp;
    final tema = Theme.of(context).textTheme;
    final social = context.watch<SocialState>();
    final app = context.watch<AppState>();

    // No próprio perfil, os números vêm do aparelho (sempre atuais) e o que
    // está desligado aparece com cadeado. Nos perfis dos outros, só o que o
    // banco devolveu.
    final meu = _ehMeu ? social.meuPerfil : null;
    final sobrepor = meu != null;
    final pontos = sobrepor ? app.pontosTotais : perfil.pontosTotais;
    final nivel = sobrepor ? app.nivel : perfil.nivel;
    final sequencia = sobrepor ? app.sequenciaDias : perfil.sequenciaDias;
    final anotacoes = sobrepor ? social.totalAnotacoes : perfil.totalAnotacoes;
    final tarefas =
        sobrepor ? social.totalTarefasConcluidas : perfil.totalTarefasConcluidas;
    final projetosConcluidos = sobrepor
        ? social.totalProjetosConcluidos
        : perfil.totalProjetosConcluidos;
    final idsConquistas = meu != null ? meu.conquistasDestaque : perfil.conquistas;
    final conquistasMostradas = conquistasDisponiveis
        .where((c) => idsConquistas.contains(c.id))
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: Column(
            children: [
              AvatarUsuario(
                nome: perfil.resumo.nome,
                cor: perfil.resumo.avatarCor,
                raio: 40,
              ),
              const SizedBox(height: 12),
              Text(
                perfil.resumo.nome,
                textAlign: TextAlign.center,
                style:
                    tema.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (perfil.resumo.usuario != null)
                Text(
                  '@${perfil.resumo.usuario}',
                  style: tema.bodyMedium
                      ?.copyWith(color: tokens.textoSecundario),
                ),
              if (perfil.bio.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(perfil.bio,
                    textAlign: TextAlign.center, style: tema.bodyMedium),
              ],
              if (perfil.criadoEm != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Na comunidade desde ${formatarMesAno(perfil.criadoEm!.toLocal())}',
                  style:
                      tema.bodySmall?.copyWith(color: tokens.textoSecundario),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _abrirLista(ModoLista.seguidores),
                    child: Text('${perfil.seguidores} seguidores'),
                  ),
                  TextButton(
                    onPressed: () => _abrirLista(ModoLista.seguindo),
                    child: Text('${perfil.seguindo} seguindo'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (_ehMeu)
                OutlinedButton.icon(
                  onPressed: _editar,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar perfil e privacidade'),
                )
              else if (perfil.euSigo)
                OutlinedButton.icon(
                  onPressed: _alternandoSeguir ? null : _alternarSeguir,
                  icon: const Icon(Icons.check),
                  label: const Text('Seguindo'),
                )
              else
                FilledButton.icon(
                  onPressed: _alternandoSeguir ? null : _alternarSeguir,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Seguir'),
                ),
            ],
          ),
        ),
        if (sobrepor)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Itens com cadeado só você vê. Para mostrar aos outros, use '
              '"Editar perfil e privacidade".',
              textAlign: TextAlign.center,
              style: tema.bodySmall?.copyWith(color: tokens.textoSecundario),
            ),
          ),
        ..._numeros(
          context,
          pontos: pontos,
          nivel: nivel,
          sequencia: sequencia,
          pontosPrivado: meu != null && !meu.mostrarPontos,
          sequenciaPrivada: meu != null && !meu.mostrarSequencia,
        ),
        ..._estatisticas(
          context,
          anotacoes: anotacoes,
          tarefas: tarefas,
          projetosConcluidos: projetosConcluidos,
          privado: meu != null && !meu.mostrarEstatisticas,
        ),
        ..._conquistas(
          context,
          conquistasMostradas,
          privado: meu != null && !meu.mostrarConquistas,
        ),
        ..._projetosPublicos(
          context,
          privado: meu != null && !meu.mostrarProjetos,
        ),
        const SizedBox(height: 24),
        const _TituloComCadeado('Publicações recentes'),
        const SizedBox(height: 12),
        if (_publicacoes.isEmpty)
          Text(
            'Nenhuma publicação ainda.',
            style: tema.bodyMedium?.copyWith(color: tokens.textoSecundario),
          )
        else
          for (final p in _publicacoes)
            CartaoPublicacao(
              publicacao: p,
              aoCurtir: () => _curtir(p),
              aoAbrir: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PublicacaoDetalheScreen(publicacao: p),
                ),
              ),
              aoExcluir: p.autor.id == social.meuId
                  ? () => _excluirPublicacao(p)
                  : null,
            ),
      ],
    );
  }

  Future<void> _excluirPublicacao(Publicacao p) async {
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
      await social.excluirPublicacao(p.id);
      if (!mounted) return;
      setState(() => _publicacoes = _publicacoes.where((x) => x.id != p.id).toList());
    } catch (e) {
      mostrarMensagem(context, SocialService.traduzirErro(e));
    }
  }

  List<Widget> _numeros(
    BuildContext context, {
    required int? pontos,
    required int? nivel,
    required int? sequencia,
    required bool pontosPrivado,
    required bool sequenciaPrivada,
  }) {
    final itens = <Widget>[
      if (pontos != null)
        _Numero(valor: '$pontos', rotulo: 'pontos', privado: pontosPrivado),
      if (sequencia != null)
        _Numero(
            valor: '$sequencia', rotulo: 'sequência', privado: sequenciaPrivada),
      if (nivel != null)
        _Numero(valor: '$nivel', rotulo: 'nível', privado: pontosPrivado),
    ];
    if (itens.isEmpty) return [];
    return [
      const SizedBox(height: 24),
      Row(children: [for (final i in itens) Expanded(child: i)]),
    ];
  }

  List<Widget> _estatisticas(
    BuildContext context, {
    required int? anotacoes,
    required int? tarefas,
    required int? projetosConcluidos,
    required bool privado,
  }) {
    if (anotacoes == null && tarefas == null && projetosConcluidos == null) {
      return [];
    }
    return [
      const SizedBox(height: 24),
      _TituloComCadeado('Estatísticas de estudo', privado: privado),
      const SizedBox(height: 8),
      Card(
        child: Column(
          children: [
            if (anotacoes != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.edit_note),
                title: const Text('Anotações criadas'),
                trailing: Text('$anotacoes'),
              ),
            if (tarefas != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Tarefas concluídas'),
                trailing: Text('$tarefas'),
              ),
            if (projetosConcluidos != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.task_alt),
                title: const Text('Projetos concluídos'),
                trailing: Text('$projetosConcluidos'),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _conquistas(
    BuildContext context,
    List<Conquista> conquistas, {
    required bool privado,
  }) {
    if (conquistas.isEmpty) return [];
    final tokens = context.coresApp;
    return [
      const SizedBox(height: 24),
      _TituloComCadeado('Conquistas em destaque', privado: privado),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in conquistas)
            Tooltip(
              message: c.descricao,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: tokens.conquistaFundo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconeDaConquista(c.id),
                        size: 18, color: tokens.conquistaIcone),
                    const SizedBox(width: 6),
                    Text(
                      c.nome,
                      style: TextStyle(
                        color: tokens.conquistaTexto,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ];
  }

  List<Widget> _projetosPublicos(BuildContext context, {required bool privado}) {
    if (_projetos.isEmpty) return [];
    return [
      const SizedBox(height: 24),
      _TituloComCadeado('Projetos', privado: privado),
      const SizedBox(height: 8),
      for (final projeto in _projetos)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: Color(projeto.cor),
            ),
            title: Text(projeto.nome),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: projeto.progresso / 100,
                  minHeight: 6,
                ),
              ),
            ),
            trailing: Text('${projeto.progresso}%'),
          ),
        ),
    ];
  }
}

/// Título de seção; com [privado] mostra um cadeado "só você vê" ao lado.
class _TituloComCadeado extends StatelessWidget {
  final String texto;
  final bool privado;

  const _TituloComCadeado(this.texto, {this.privado = false});

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TituloSecao(texto),
        if (privado) ...[
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 14, color: tokens.textoSuave),
                const SizedBox(width: 3),
                Text(
                  'só você vê',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: tokens.textoSuave),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Numero extends StatelessWidget {
  final String valor;
  final String rotulo;
  final bool privado;

  const _Numero({
    required this.valor,
    required this.rotulo,
    this.privado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (privado) ...[
              Icon(Icons.lock_outline,
                  size: 12, color: context.coresApp.textoSuave),
              const SizedBox(width: 2),
            ],
            Text(
              rotulo,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.coresApp.textoSecundario),
            ),
          ],
        ),
      ],
    );
  }
}

class _Falha extends StatelessWidget {
  final String mensagem;
  final VoidCallback? aoTentarDeNovo;

  const _Falha({required this.mensagem, this.aoTentarDeNovo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mensagem, textAlign: TextAlign.center),
            if (aoTentarDeNovo != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: aoTentarDeNovo,
                child: const Text('Tentar de novo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
