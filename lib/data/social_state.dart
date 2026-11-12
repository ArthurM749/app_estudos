import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../models/perfil_social.dart';
import '../models/publicacao.dart';
import 'app_state.dart';
import 'database_helper.dart';
import 'social_service.dart';

/// Resultado de uma rodada da fila de saída.
class ResultadoFila {
  /// Algo foi enviado nesta rodada.
  final bool enviouAlgo;

  /// A rodada parou por falta de internet (o resto continua na fila).
  final bool semInternet;

  /// Erro que NÃO é de conexão (ex.: servidor recusou). Mostrar para a pessoa.
  final String? erro;

  const ResultadoFila({
    this.enviouAlgo = false,
    this.semInternet = false,
    this.erro,
  });
}

/// `busca` não é uma aba na tela: guarda o resultado da pesquisa por título.
enum AbaFeed { seguindo, descobrir, busca }

class _ListaDoFeed {
  List<Publicacao> itens = [];
  bool carregando = false;
  bool jaCarregou = false;
  bool temMais = true;
  String? erro;
}

/// Estado da parte social (feed, perfil público, sincronização).
///
/// Fica SEPARADO do AppState de propósito: o AppState cuida do que funciona
/// offline e não depende de internet; aqui tudo pode falhar por falta de rede
/// sem derrubar nada do resto do app. A única ligação é de leitura: a
/// sincronização recebe o AppState para ler pontos, sequência e projetos.
class SocialState extends ChangeNotifier {
  static const _tamanhoPagina = 20;

  final SocialService _servico = SocialService.instance;

  final Map<AbaFeed, _ListaDoFeed> _feeds = {
    AbaFeed.seguindo: _ListaDoFeed(),
    AbaFeed.descobrir: _ListaDoFeed(),
    AbaFeed.busca: _ListaDoFeed(),
  };

  /// Termo da pesquisa atual e um contador para descartar respostas de
  /// pesquisas antigas (quem digita rápido dispara várias seguidas).
  String termoBusca = '';
  int _sequenciaBusca = 0;

  /// Pessoas encontradas quando a pesquisa começa com "@".
  List<PerfilResumo> pessoasBusca = [];
  bool get buscandoPessoas => termoBusca.startsWith('@');

  bool _processandoFila = false;

  /// Conta para a qual os dados em memória foram carregados. Se a conta mudar
  /// (sair e entrar com outra), tudo é descartado em vez de misturar contas.
  String? _usuarioId;

  DateTime? _ultimaSincronizacao;
  bool sincronizando = false;
  String? erroSincronizacao;

  PerfilEditavel? meuPerfil;

  /// Ids locais (SQLite) dos projetos que a pessoa escolheu mostrar.
  Set<int> projetosPublicados = {};

  /// Totais calculados na última sincronização. O próprio perfil mostra esses
  /// números mesmo quando estão ocultos para os outros (com um cadeado).
  int? totalAnotacoes;
  int? totalTarefasConcluidas;
  int? totalProjetosConcluidos;

  String? get meuId => _servico.meuId;
  bool get logado => meuId != null;

  List<Publicacao> itens(AbaFeed aba) => _feeds[aba]!.itens;
  bool carregando(AbaFeed aba) => _feeds[aba]!.carregando;
  bool jaCarregou(AbaFeed aba) => _feeds[aba]!.jaCarregou;
  bool temMais(AbaFeed aba) => _feeds[aba]!.temMais;
  String? erro(AbaFeed aba) => _feeds[aba]!.erro;

  void _verificarUsuario() {
    final atual = meuId;
    if (atual == _usuarioId) return;
    _usuarioId = atual;
    for (final lista in _feeds.values) {
      lista
        ..itens = []
        ..carregando = false
        ..jaCarregou = false
        ..temMais = true
        ..erro = null;
    }
    meuPerfil = null;
    termoBusca = '';
    pessoasBusca = [];
    projetosPublicados = {};
    totalAnotacoes = null;
    totalTarefasConcluidas = null;
    totalProjetosConcluidos = null;
    _ultimaSincronizacao = null;
    erroSincronizacao = null;
  }

  // -------------------------------------------------------------------- feed

  Future<void> carregarFeed(AbaFeed aba, {bool maisAntigas = false}) async {
    _verificarUsuario();
    if (!logado) return;

    final lista = _feeds[aba]!;
    if (lista.carregando) return;
    if (maisAntigas && !lista.temMais) return;
    if (aba == AbaFeed.busca && termoBusca.isEmpty) return;

    final sequencia = _sequenciaBusca;
    final buscaDePessoas = aba == AbaFeed.busca && buscandoPessoas;
    lista.carregando = true;
    lista.erro = null;
    notifyListeners();

    try {
      if (buscaDePessoas) {
        // "@maria": procura pessoas pelo @usuário em vez de publicações.
        final pessoas = await _servico.buscarPessoasPorUsuario(termoBusca);
        if (sequencia != _sequenciaBusca) return;
        pessoasBusca = pessoas;
        lista.itens = [];
        lista.temMais = false;
        lista.jaCarregou = true;
        lista.carregando = false;
        notifyListeners();
        return;
      }
      List<String>? autores;
      if (aba == AbaFeed.seguindo) {
        // Inclui a própria pessoa para ela ver o que publicou.
        autores = [...await _servico.idsSeguidosPorMim(), meuId!];
      }
      final antesDe =
          maisAntigas && lista.itens.isNotEmpty ? lista.itens.last.criadoEmBruto : null;

      final novas = await _servico.listarPublicacoes(
        autores: autores,
        antesDe: antesDe,
        tituloContem: aba == AbaFeed.busca ? termoBusca : null,
        limite: _tamanhoPagina,
      );
      // Uma pesquisa mais nova assumiu: este resultado já não vale.
      if (aba == AbaFeed.busca && sequencia != _sequenciaBusca) return;
      lista.itens = maisAntigas ? [...lista.itens, ...novas] : novas;
      lista.temMais = novas.length == _tamanhoPagina;
      lista.jaCarregou = true;
    } catch (e) {
      if (aba == AbaFeed.busca && sequencia != _sequenciaBusca) return;
      lista.erro = SocialService.traduzirErro(e);
    }

    lista.carregando = false;
    notifyListeners();
  }

  /// Pesquisa publicações pelo título. Termo vazio limpa o resultado.
  Future<void> buscarPublicacoes(String termo) async {
    _verificarUsuario();
    _sequenciaBusca++;
    termoBusca = termo.trim();
    pessoasBusca = [];
    _feeds[AbaFeed.busca]!
      ..itens = []
      ..carregando = false
      ..jaCarregou = false
      ..temMais = true
      ..erro = null;
    if (termoBusca.isEmpty) {
      notifyListeners();
      return;
    }
    await carregarFeed(AbaFeed.busca);
  }

  void limparBusca() {
    _sequenciaBusca++;
    termoBusca = '';
    pessoasBusca = [];
    _feeds[AbaFeed.busca]!
      ..itens = []
      ..carregando = false
      ..jaCarregou = false
      ..temMais = true
      ..erro = null;
    notifyListeners();
  }

  Future<void> _recarregarFeeds() => Future.wait([
        carregarFeed(AbaFeed.descobrir),
        carregarFeed(AbaFeed.seguindo),
      ]);

  /// Compartilhamento de atividade (conquista, projeto, sequência, evolução).
  /// Devolve true se já foi para a nuvem e false se ficou na fila (sem
  /// internet): nesse caso é enviada sozinha quando a conexão voltar.
  Future<bool> publicar({
    String? titulo,
    required String conteudo,
    TipoPublicacao tipo = TipoPublicacao.texto,
    Map<String, dynamic> meta = const {},
  }) async {
    try {
      await _servico.publicar(
          titulo: titulo, conteudo: conteudo, tipo: tipo, meta: meta);
    } catch (e) {
      if (!SocialService.ehErroDeRede(e)) rethrow;
      await DatabaseHelper.instance.adicionarPublicacaoPendente(
        contaId: meuId,
        titulo: titulo,
        conteudo: conteudo,
        tipo: tipo.valorBanco,
        metaJson: jsonEncode(meta),
      );
      return false;
    }
    await _recarregarFeeds();
    return true;
  }

  // ------------------------------------------------- fila de saída (offline)

  /// Envia para a nuvem tudo o que ficou esperando: anotações publicadas,
  /// editadas ou retiradas, atividades compartilhadas e remoções. Seguro de
  /// chamar a qualquer momento (não faz nada sem conta ou sem pendências).
  Future<ResultadoFila> processarFila() async {
    _verificarUsuario();
    final conta = meuId;
    if (conta == null || _processandoFila) return const ResultadoFila();
    _processandoFila = true;

    final banco = DatabaseHelper.instance;
    var enviou = false;
    try {
      // 1) Anotações apagadas que estavam publicadas.
      for (final id in await banco.listarRemocoesPendentes(conta)) {
        await _servico.excluirPublicacao(id);
        await banco.removerRemocaoPendente(id);
        _removerDasListas(id);
        enviou = true;
      }

      // 2) Atividades compartilhadas sem internet.
      for (final linha in await banco.listarPublicacoesPendentes(conta)) {
        await _servico.publicar(
          titulo: linha['titulo'] as String?,
          conteudo: linha['conteudo'] as String,
          tipo: TipoPublicacao.deBanco(linha['tipo'] as String),
          meta: Map<String, dynamic>.from(
              jsonDecode(linha['meta'] as String) as Map),
        );
        await banco.removerPublicacaoPendente(linha['id'] as int);
        enviou = true;
      }

      // 3) Anotações: publicar, atualizar o texto ou retirar do feed.
      for (final item in await banco.listarAnotacoesPendentes()) {
        if (item.querPublicada) {
          if (item.publicacaoId == null) {
            final id = await _servico.publicar(
              titulo: item.titulo,
              conteudo: item.conteudo,
              tipo: TipoPublicacao.texto,
            );
            await banco.definirEnvioDoItem(item.id!,
                publicacaoId: id, pendente: false);
          } else {
            final existe = await _servico.atualizarPublicacao(
              id: item.publicacaoId!,
              titulo: item.titulo,
              conteudo: item.conteudo,
            );
            if (existe) {
              await banco.definirEnvioDoItem(item.id!,
                  publicacaoId: item.publicacaoId, pendente: false);
            } else {
              // Apagada pelo feed ou em outro aparelho: volta a ser privada.
              await banco.tornarAnotacaoPrivada(item.id!);
            }
          }
        } else {
          await _servico.excluirPublicacao(item.publicacaoId!);
          await banco.definirEnvioDoItem(item.id!,
              publicacaoId: null, pendente: false);
          _removerDasListas(item.publicacaoId!);
        }
        enviou = true;
      }
    } catch (e) {
      _processandoFila = false;
      if (enviou) {
        _recarregarFeeds();
        notifyListeners();
      }
      if (SocialService.ehErroDeRede(e)) {
        return ResultadoFila(enviouAlgo: enviou, semInternet: true);
      }
      return ResultadoFila(
          enviouAlgo: enviou, erro: SocialService.traduzirErro(e));
    }

    _processandoFila = false;
    if (enviou) {
      _recarregarFeeds();
      notifyListeners();
    }
    return ResultadoFila(enviouAlgo: enviou);
  }

  /// Apaga a anotação do aparelho. Se estava publicada, a publicação é
  /// retirada da nuvem agora ou assim que houver internet.
  Future<void> excluirAnotacao(Item anotacao, AppState app) async {
    final publicacaoId = anotacao.publicacaoId;
    if (publicacaoId != null) {
      await DatabaseHelper.instance
          .adicionarRemocaoPendente(publicacaoId, meuId);
    }
    await app.excluirItem(anotacao);
    if (publicacaoId != null) await processarFila();
  }

  void _removerDasListas(String id) {
    for (final lista in _feeds.values) {
      lista.itens = lista.itens.where((p) => p.id != id).toList();
    }
  }

  /// Curtida otimista: a tela muda na hora e volta atrás se o servidor recusar.
  /// Devolve a publicação atualizada para quem chamou (telas com cópia local).
  Future<Publicacao> alternarCurtida(Publicacao publicacao) async {
    final atualizada = publicacao.copyWith(
      curtidaPorMim: !publicacao.curtidaPorMim,
      curtidas: publicacao.curtidas + (publicacao.curtidaPorMim ? -1 : 1),
    );
    _substituir(atualizada);
    notifyListeners();
    try {
      if (atualizada.curtidaPorMim) {
        await _servico.curtir(publicacao.id);
      } else {
        await _servico.descurtir(publicacao.id);
      }
      return atualizada;
    } catch (_) {
      _substituir(publicacao);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> excluirPublicacao(String id) async {
    await _servico.excluirPublicacao(id);
    _removerDasListas(id);
    // Se era uma anotação, ela volta a ser privada no aparelho.
    try {
      await DatabaseHelper.instance.marcarAnotacaoPrivada(id);
    } catch (_) {}
    notifyListeners();
  }

  /// Mantém o contador dos cartões do feed em dia quando alguém comenta ou
  /// apaga um comentário na tela de detalhe.
  void ajustarComentarios(String publicacaoId, int variacao) {
    for (final lista in _feeds.values) {
      lista.itens = [
        for (final p in lista.itens)
          p.id == publicacaoId
              ? p.copyWith(comentarios: _naoNegativo(p.comentarios + variacao))
              : p,
      ];
    }
    notifyListeners();
  }

  int _naoNegativo(int valor) => valor < 0 ? 0 : valor;

  void _substituir(Publicacao nova) {
    for (final lista in _feeds.values) {
      lista.itens = [
        for (final p in lista.itens) p.id == nova.id ? nova : p,
      ];
    }
  }

  // ------------------------------------------------------------ sincronização

  /// Envia para o Supabase os números do app (pontos, sequência, totais) e
  /// atualiza o cartão dos projetos que a pessoa decidiu mostrar. O app local
  /// continua sendo a fonte da verdade: nada é lido de volta para o SQLite.
  Future<void> sincronizar(AppState app, {bool forcar = false}) async {
    _verificarUsuario();
    if (!logado || sincronizando) return;

    final ultima = _ultimaSincronizacao;
    if (!forcar &&
        ultima != null &&
        DateTime.now().difference(ultima) < const Duration(minutes: 2)) {
      return;
    }

    sincronizando = true;
    erroSincronizacao = null;
    notifyListeners();

    try {
      await _servico.garantirPerfil(nome: app.nomeUsuario ?? 'Estudante');

      final banco = DatabaseHelper.instance;
      final anotacoes = await banco.contarItens(tipo: TipoItem.anotacao);
      final tarefas =
          await banco.contarItens(tipo: TipoItem.tarefa, concluido: true);
      final projetosConcluidos =
          app.progressoPorProjeto.values.where((p) => p >= 100).length;

      totalAnotacoes = anotacoes;
      totalTarefasConcluidas = tarefas;
      totalProjetosConcluidos = projetosConcluidos;

      await _servico.atualizarEstatisticas(
        pontosTotais: app.pontosTotais,
        nivel: app.nivel,
        sequenciaDias: app.sequenciaDias,
        totalAnotacoes: anotacoes,
        totalTarefasConcluidas: tarefas,
        totalProjetosConcluidos: projetosConcluidos,
      );
      await _sincronizarProjetosPublicados(app);
      _ultimaSincronizacao = DateTime.now();
    } catch (e) {
      erroSincronizacao = SocialService.traduzirErro(e);
    }

    sincronizando = false;
    notifyListeners();
  }

  Future<void> _sincronizarProjetosPublicados(AppState app) async {
    final publicados = await _servico.idsProjetosPublicadosPorMim();
    final locais = {
      for (final projeto in app.projetos)
        if (projeto.id != null) projeto.id!: projeto,
    };

    // Projeto apagado no aparelho some também do perfil público: não pode
    // continuar visível um projeto que a pessoa já excluiu.
    final apagados = publicados.where((id) => !locais.containsKey(id));
    await _servico.removerProjetosPublicos(apagados);

    final vigentes = publicados.where(locais.containsKey).toSet();
    await _servico.publicarProjetos(
      [for (final id in vigentes) locais[id]!],
      app.progressoPorProjeto,
    );
    projetosPublicados = vigentes;
  }

  // ------------------------------------------------------------- meu perfil

  Future<void> carregarMeuPerfil() async {
    _verificarUsuario();
    if (!logado) return;
    meuPerfil = await _servico.obterMeuPerfil();
    projetosPublicados = await _servico.idsProjetosPublicadosPorMim();
    notifyListeners();
  }

  /// [novaFoto]/[extensaoFoto] enviam uma foto nova; [removerFoto] tira a
  /// atual. Sem nenhum dos dois, a foto que já estava em [perfil] é mantida.
  Future<void> salvarMeuPerfil({
    required PerfilEditavel perfil,
    required Set<int> projetosEscolhidos,
    required AppState app,
    Uint8List? novaFoto,
    String extensaoFoto = 'jpg',
    bool removerFoto = false,
  }) async {
    final fotoAnterior = perfil.avatarUrl;
    if (novaFoto != null) {
      final url = await _servico.enviarAvatar(novaFoto, extensaoFoto);
      perfil = perfil.comAvatarUrl(url);
    } else if (removerFoto) {
      perfil = perfil.comAvatarUrl(null);
    }

    await _servico.salvarMeuPerfil(perfil);
    // Só depois de gravar o perfil com a foto nova é seguro apagar a antiga.
    if (novaFoto != null || removerFoto) {
      await _servico.removerAvatarAntigo(fotoAnterior);
    }

    final retirados = projetosPublicados.difference(projetosEscolhidos);
    await _servico.removerProjetosPublicos(retirados);
    await _servico.publicarProjetos(
      app.projetos
          .where((p) => p.id != null && projetosEscolhidos.contains(p.id))
          .toList(),
      app.progressoPorProjeto,
    );

    meuPerfil = perfil;
    projetosPublicados = projetosEscolhidos;
    notifyListeners();
  }
}
