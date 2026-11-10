import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../models/perfil_social.dart';
import '../models/publicacao.dart';
import 'app_state.dart';
import 'database_helper.dart';
import 'social_service.dart';

enum AbaFeed { seguindo, descobrir }

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
  };

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

    lista.carregando = true;
    lista.erro = null;
    notifyListeners();

    try {
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
        limite: _tamanhoPagina,
      );
      lista.itens = maisAntigas ? [...lista.itens, ...novas] : novas;
      lista.temMais = novas.length == _tamanhoPagina;
      lista.jaCarregou = true;
    } catch (e) {
      lista.erro = SocialService.traduzirErro(e);
    }

    lista.carregando = false;
    notifyListeners();
  }

  Future<void> publicar({
    required String conteudo,
    TipoPublicacao tipo = TipoPublicacao.texto,
    Map<String, dynamic> meta = const {},
  }) async {
    await _servico.publicar(conteudo: conteudo, tipo: tipo, meta: meta);
    await Future.wait([
      carregarFeed(AbaFeed.descobrir),
      carregarFeed(AbaFeed.seguindo),
    ]);
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
    for (final lista in _feeds.values) {
      lista.itens = lista.itens.where((p) => p.id != id).toList();
    }
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

  Future<void> salvarMeuPerfil({
    required PerfilEditavel perfil,
    required Set<int> projetosEscolhidos,
    required AppState app,
  }) async {
    await _servico.salvarMeuPerfil(perfil);

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
