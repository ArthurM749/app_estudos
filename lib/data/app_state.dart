import 'package:flutter/foundation.dart';

import '../models/conquista.dart';
import '../models/evento_pontos.dart';
import '../models/item.dart';
import '../models/projeto.dart';
import 'database_helper.dart';
import 'regras_pontos.dart';

/// Estado global do app: projetos, pontos, nível e conquistas.
///
/// Os itens (anotações/tarefas) de cada projeto NÃO ficam
/// cacheados aqui — a tela de detalhe do projeto carrega direto do
/// banco (são poucos registros, não compensa duplicar estado). Este
/// estado cuida só do que é usado em várias telas ao mesmo tempo:
/// lista de projetos, pontuação e conquistas.
class AppState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Projeto> projetos = [];

  /// projetoId -> progresso de 0 a 100 (já resolvido, seja manual ou
  /// calculado por tarefas).
  Map<int, int> progressoPorProjeto = {};

  int pontosHoje = 0;
  int pontosOntem = 0;
  int pontosSemana = 0;
  int pontosTotais = 0;
  int nivel = 1;

  Set<String> conquistasDesbloqueadas = {};

  /// Pontos ganhos em cada dia da semana atual, segunda (índice 0) a
  /// domingo (índice 6). Alimenta o gráfico de colunas da tela de
  /// Progresso.
  List<int> pontosPorDia = List.filled(7, 0);

  /// `true` assim que a pessoa já decidiu entre criar perfil ou
  /// continuar sem conta (nessa sessão ou numa anterior). Enquanto
  /// for `false`, o app mostra a tela de criar perfil antes de tudo.
  bool onboardingConcluido = false;
  String? nomeUsuario;
  String? emailUsuario;

  bool carregando = true;

  /// Mensagem de erro, se o carregamento falhou. A tela mostra isso
  /// em vez de ficar girando pra sempre quando algo dá errado (ex.:
  /// problema ao abrir o banco local).
  String? erro;

  Future<void> carregar() async {
    carregando = true;
    erro = null;
    notifyListeners();

    try {
      final perfil = await _db.obterPerfil();
      if (perfil != null) {
        onboardingConcluido = true;
        nomeUsuario = perfil['nome'] as String?;
        emailUsuario = perfil['email'] as String?;
      }

      projetos = await _db.listarProjetos();
      for (final projeto in projetos) {
        if (projeto.id == null) continue;
        progressoPorProjeto[projeto.id!] = await _progressoAtualDe(projeto);
      }
      await _recarregarPontosEConquistas();
    } catch (e) {
      erro = e.toString();
    }

    carregando = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // Perfil local (opcional)
  // ---------------------------------------------------------------

  Future<void> criarPerfil({required String nome, required String email}) async {
    await _db.salvarPerfil(nome: nome, email: email, pulou: false);
    nomeUsuario = nome;
    emailUsuario = email;
    onboardingConcluido = true;
    notifyListeners();
  }

  Future<void> continuarSemConta() async {
    await _db.salvarPerfil(pulou: true);
    onboardingConcluido = true;
    notifyListeners();
  }

  Future<int> _progressoAtualDe(Projeto projeto) async {
    if (projeto.modoProgresso == ModoProgresso.manual) {
      return projeto.progressoManual;
    }
    return _db.progressoPorTarefas(projeto.id!);
  }

  Future<void> _recarregarPontosEConquistas() async {
    final agora = DateTime.now();
    final inicioHoje = DateTime(agora.year, agora.month, agora.day);
    final fimHoje = inicioHoje
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    final inicioOntem = inicioHoje.subtract(const Duration(days: 1));
    final fimOntem = inicioHoje.subtract(const Duration(milliseconds: 1));
    final inicioSemana = inicioHoje.subtract(const Duration(days: 6));

    pontosHoje = await _db.somaPontosEntre(inicioHoje, fimHoje);
    pontosOntem = await _db.somaPontosEntre(inicioOntem, fimOntem);
    pontosSemana = await _db.somaPontosEntre(inicioSemana, fimHoje);
    pontosTotais = await _db.pontosTotais();
    nivel = RegrasDePontos.nivelPara(pontosTotais);

    // weekday: segunda = 1 ... domingo = 7 → índice 0 = segunda.
    final segunda = inicioHoje.subtract(Duration(days: agora.weekday - 1));
    pontosPorDia = await _db.pontosPorDiaDaSemana(segunda);

    final desbloqueadas = await _db.listarConquistasDesbloqueadas();
    conquistasDesbloqueadas = desbloqueadas.map((c) => c.conquistaId).toSet();

    if (pontosTotais >= 500 &&
        !conquistasDesbloqueadas.contains('estudioso')) {
      await _db.desbloquearConquista('estudioso');
      conquistasDesbloqueadas.add('estudioso');
    }
  }

  Future<void> _registrarPontos(TipoAcao tipo) async {
    final pontos = RegrasDePontos.pontosPorAcao[tipo] ?? 0;
    await _db.registrarPontos(
      EventoDePontos(tipo: tipo, pontos: pontos, data: DateTime.now()),
    );
  }

  // ---------------------------------------------------------------
  // Projetos
  // ---------------------------------------------------------------

  Future<Projeto> criarProjeto({
    required String nome,
    required int cor,
    ModoProgresso modoProgresso = ModoProgresso.porTarefas,
  }) async {
    final novo = Projeto(
      nome: nome,
      cor: cor,
      modoProgresso: modoProgresso,
      criadoEm: DateTime.now(),
    );
    final id = await _db.inserirProjeto(novo);
    final criado = novo.copyWith(id: id);

    projetos.insert(0, criado);
    progressoPorProjeto[id] = 0;

    if (!conquistasDesbloqueadas.contains('descobrimento')) {
      await _db.desbloquearConquista('descobrimento');
      conquistasDesbloqueadas.add('descobrimento');
    }

    notifyListeners();
    return criado;
  }

  /// Usado quando o projeto está no modo de progresso manual: o
  /// usuário arrasta a barrinha e define a porcentagem na mão.
  Future<void> definirProgressoManual(int projetoId, int valor) async {
    final indice = projetos.indexWhere((p) => p.id == projetoId);
    if (indice == -1) return;

    final atualizado = projetos[indice].copyWith(progressoManual: valor);
    await _db.atualizarProjeto(atualizado);
    projetos[indice] = atualizado;

    await _aplicarNovoProgresso(atualizado, valor);
    notifyListeners();
  }

  /// Chamado depois de criar/concluir um item de um projeto no modo
  /// "por tarefas", pra recalcular a % e checar se o projeto bateu
  /// 100%.
  Future<void> _recalcularProgressoPorTarefas(int projetoId) async {
    final indice = projetos.indexWhere((p) => p.id == projetoId);
    if (indice == -1) return;
    final projeto = projetos[indice];
    if (projeto.modoProgresso != ModoProgresso.porTarefas) return;

    final progresso = await _db.progressoPorTarefas(projetoId);
    await _aplicarNovoProgresso(projeto, progresso);
  }

  Future<void> _aplicarNovoProgresso(Projeto projeto, int progresso) async {
    final anterior = progressoPorProjeto[projeto.id] ?? 0;
    progressoPorProjeto[projeto.id!] = progresso;

    if (progresso >= 100 && anterior < 100) {
      await _registrarPontos(TipoAcao.concluirProjeto);
      if (!conquistasDesbloqueadas.contains('finalizador')) {
        await _db.desbloquearConquista('finalizador');
        conquistasDesbloqueadas.add('finalizador');
      }
    }
    await _recarregarPontosEConquistas();
  }

  // ---------------------------------------------------------------
  // Itens (anotações, tarefas)
  // ---------------------------------------------------------------

  /// Cria um item e já registra os pontos da ação, quando aplicável.
  /// Tarefa não pontua ao ser criada — pontua ao ser concluída (ver
  /// [alternarConclusao]).
  Future<Item> criarItem({
    int? projetoId,
    required TipoItem tipo,
    required String titulo,
    String conteudo = '',
    Visibilidade visibilidade = Visibilidade.privada,
  }) async {
    final item = Item(
      projetoId: projetoId,
      tipo: tipo,
      titulo: titulo,
      conteudo: conteudo,
      visibilidade: visibilidade,
      criadoEm: DateTime.now(),
    );
    final id = await _db.inserirItem(item);
    final criado = item.copyWith(id: id);

    if (tipo == TipoItem.anotacao) {
      await _registrarPontos(TipoAcao.criarAnotacao);
    }

    await _recarregarPontosEConquistas();
    if (projetoId != null) {
      await _recalcularProgressoPorTarefas(projetoId);
    }
    notifyListeners();
    return criado;
  }

  /// Atualiza título/conteúdo/visibilidade de um item já existente.
  /// O tipo (anotação ou tarefa) não muda numa edição — é definido
  /// só na criação — então isso nunca precisa recalcular pontos ou
  /// progresso.
  Future<void> atualizarItem(Item item) async {
    await _db.atualizarItem(item);
    notifyListeners();
  }

  Future<void> excluirItem(Item item) async {
    if (item.id == null) return;
    await _db.excluirItem(item.id!);

    if (item.projetoId != null) {
      await _recalcularProgressoPorTarefas(item.projetoId!);
    }
    notifyListeners();
  }

  /// Marca/desmarca uma tarefa como concluída. Pontua só ao marcar
  /// como concluída (nunca ao desmarcar).
  Future<void> alternarConclusao(Item item) async {
    final atualizado = item.copyWith(concluido: !item.concluido);
    await _db.atualizarItem(atualizado);

    if (atualizado.concluido) {
      await _registrarPontos(TipoAcao.concluirTarefa);
    }

    await _recarregarPontosEConquistas();
    if (item.projetoId != null) {
      await _recalcularProgressoPorTarefas(item.projetoId!);
    }
    notifyListeners();
  }
}
