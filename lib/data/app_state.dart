import 'package:flutter/material.dart';

import '../models/conquista.dart';
import '../models/evento_pontos.dart';
import '../models/item.dart';
import '../models/projeto.dart';
import 'database_helper.dart';
import 'regras_pontos.dart';
import 'auth_service.dart';

class AppState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Projeto> projetos = [];

  Map<int, int> progressoPorProjeto = {};

  int pontosHoje = 0;
  int pontosOntem = 0;
  int pontosSemana = 0;
  int pontosTotais = 0;
  int nivel = 1;

  int sequenciaDias = 0;

  Set<String> conquistasDesbloqueadas = {};

  List<int> pontosPorDia = List.filled(7, 0);

  bool onboardingConcluido = false;
  String? nomeUsuario;
  String? emailUsuario;
  DateTime? perfilCriadoEm;

  ThemeMode tema = ThemeMode.light;

  bool carregando = true;

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
        tema = _textoParaTema(perfil['tema'] as String?);
        final criadoEmTexto = perfil['criado_em'] as String?;
        perfilCriadoEm =
            criadoEmTexto != null ? DateTime.parse(criadoEmTexto) : null;
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

  Future<void> criarPerfil(
      {required String nome, required String email}) async {
    await _db.salvarPerfil(nome: nome, email: email, pulou: false);
    await _db.atualizarTema(_temaParaTexto(tema));
    nomeUsuario = nome;
    emailUsuario = email;
    perfilCriadoEm = DateTime.now();
    onboardingConcluido = true;
    notifyListeners();
  }

  /// Chamado quando o nome é editado no perfil público, para o app todo
  /// (saudação do Início, modo offline) usar o mesmo nome.
  Future<void> atualizarNome(String nome) async {
    if (nome == nomeUsuario) return;
    await _db.atualizarNome(nome);
    nomeUsuario = nome;
    notifyListeners();
  }

  Future<void> continuarSemConta() async {
    await _db.salvarPerfil(pulou: true);
    await _db.atualizarTema(_temaParaTexto(tema));
    perfilCriadoEm = DateTime.now();
    onboardingConcluido = true;
    notifyListeners();
  }

  Future<void> sair() async {
    try {
      await AuthService.instance.sair();
    } catch (_) {}
    await _db.apagarPerfil();
    nomeUsuario = null;
    emailUsuario = null;
    perfilCriadoEm = null;
    onboardingConcluido = false;
    notifyListeners();
  }

  Future<void> definirTema(ThemeMode modo) async {
    tema = modo;
    notifyListeners();
    try {
      await _db.atualizarTema(_temaParaTexto(modo));
    } catch (e) {
      debugPrint('Erro ao salvar tema: $e');
    }
  }

  String _temaParaTexto(ThemeMode modo) {
    switch (modo) {
      case ThemeMode.light:
        return 'claro';
      case ThemeMode.dark:
        return 'escuro';
      case ThemeMode.system:
        return 'sistema';
    }
  }

  ThemeMode _textoParaTema(String? texto) {
    switch (texto) {
      case 'escuro':
        return ThemeMode.dark;
      case 'sistema':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  /// Soma ao total deste aparelho os pontos que a conta já tinha na nuvem
  /// (ganhos em outro celular). Só sobe: nunca diminui o que já existe aqui.
  Future<void> aplicarPontosDaNuvem(int totalDaNuvem) async {
    final atual = await _db.pontosTotais();
    if (totalDaNuvem <= atual) return;
    await _db.registrarAjusteDaNuvem(totalDaNuvem - atual);
    await _recarregarPontosEConquistas();
    notifyListeners();
  }

  Future<void> apagarTudo() async {
    try {
      await AuthService.instance.sair();
    } catch (_) {}
    await _db.apagarTudo();
    projetos = [];
    progressoPorProjeto = {};
    pontosHoje = 0;
    pontosOntem = 0;
    pontosSemana = 0;
    pontosTotais = 0;
    nivel = 1;
    sequenciaDias = 0;
    pontosPorDia = List.filled(7, 0);
    conquistasDesbloqueadas = {};
    onboardingConcluido = false;
    nomeUsuario = null;
    emailUsuario = null;
    perfilCriadoEm = null;
    tema = ThemeMode.light;
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

    final segunda = inicioHoje.subtract(Duration(days: agora.weekday - 1));
    pontosPorDia = await _db.pontosPorDiaDaSemana(segunda);

    sequenciaDias = await _calcularSequenciaDias(inicioHoje);

    final desbloqueadas = await _db.listarConquistasDesbloqueadas();
    conquistasDesbloqueadas = desbloqueadas.map((c) => c.conquistaId).toSet();

    await _verificarConquistasGerais();
  }

  Future<int> _calcularSequenciaDias(DateTime hojeSemHora) async {
    final dias = await _db.diasComPontosDistintos();
    if (dias.isEmpty) return 0;

    var cursor = dias.first == hojeSemHora
        ? hojeSemHora
        : hojeSemHora.subtract(const Duration(days: 1));

    var sequencia = 0;
    for (final dia in dias) {
      if (dia == cursor) {
        sequencia++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (dia.isBefore(cursor)) {
        break;
      }
    }
    return sequencia;
  }

  Future<void> _desbloquear(String conquistaId) async {
    if (conquistasDesbloqueadas.contains(conquistaId)) return;
    await _db.desbloquearConquista(conquistaId);
    conquistasDesbloqueadas.add(conquistaId);
  }

  Future<void> _verificarConquistasGerais() async {
    if (pontosTotais >= 100) await _desbloquear('centenario');
    if (pontosTotais >= 500) await _desbloquear('estudioso');
    if (nivel >= 5) await _desbloquear('nivel_5');
    if (nivel >= 10) await _desbloquear('nivel_10');
    if (sequenciaDias >= 3) await _desbloquear('aquecendo');
    if (sequenciaDias >= 7) await _desbloquear('semana_perfeita');

    final totalAnotacoes = await _db.contarItens(tipo: TipoItem.anotacao);
    if (totalAnotacoes >= 1) await _desbloquear('primeira_anotacao');
    if (totalAnotacoes >= 10) await _desbloquear('biblioteca');

    final tarefasConcluidas =
        await _db.contarItens(tipo: TipoItem.tarefa, concluido: true);
    if (tarefasConcluidas >= 1) await _desbloquear('maos_a_obra');
  }

  Future<void> _registrarPontos(TipoAcao tipo, {String? referencia}) async {
    final pontos = RegrasDePontos.pontosPorAcao[tipo] ?? 0;
    await _db.registrarPontos(
      EventoDePontos(
        tipo: tipo,
        pontos: pontos,
        data: DateTime.now(),
        referencia: referencia,
      ),
    );
  }

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

    await _registrarPontos(TipoAcao.criarProjeto);
    await _desbloquear('arquiteto');
    await _recarregarPontosEConquistas();

    notifyListeners();
    return criado;
  }

  Future<void> editarProjeto({
    required int projetoId,
    required String nome,
    required int cor,
    required ModoProgresso modoProgresso,
  }) async {
    final indice = projetos.indexWhere((p) => p.id == projetoId);
    if (indice == -1) return;

    final atual = projetos[indice];
    final atualizado =
        atual.copyWith(nome: nome, cor: cor, modoProgresso: modoProgresso);
    await _db.atualizarProjeto(atualizado);
    projetos[indice] = atualizado;

    progressoPorProjeto[projetoId] = await _progressoAtualDe(atualizado);
    notifyListeners();
  }

  Future<void> excluirProjeto(int projetoId) async {
    await _db.excluirProjeto(projetoId);
    projetos.removeWhere((p) => p.id == projetoId);
    progressoPorProjeto.remove(projetoId);
    notifyListeners();
  }

  Future<void> definirProgressoManual(int projetoId, int valor) async {
    final indice = projetos.indexWhere((p) => p.id == projetoId);
    if (indice == -1) return;

    final atualizado = projetos[indice].copyWith(progressoManual: valor);
    await _db.atualizarProjeto(atualizado);
    projetos[indice] = atualizado;

    await _aplicarNovoProgresso(atualizado, valor);
    notifyListeners();
  }

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
      await _registrarPontos(TipoAcao.concluirProjeto,
          referencia: 'projeto:${projeto.id}');
      await _desbloquear('dedicado');
    }
    await _recarregarPontosEConquistas();
  }

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

  Future<void> alternarConclusao(Item item) async {
    final atualizado = item.copyWith(concluido: !item.concluido);
    await _db.atualizarItem(atualizado);

    if (atualizado.concluido) {
      // Referência = id do item: desmarcar e marcar de novo não dá pontos.
      await _registrarPontos(TipoAcao.concluirTarefa,
          referencia: 'item:${item.id}');
    }

    await _recarregarPontosEConquistas();
    if (item.projetoId != null) {
      await _recalcularProgressoPorTarefas(item.projetoId!);
    }
    notifyListeners();
  }
}
