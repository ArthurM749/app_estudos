import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/conquista.dart';
import '../models/evento_pontos.dart';
import '../models/item.dart';
import '../models/projeto.dart';
import 'database_helper.dart';
import 'regras_pontos.dart';

class AppState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Projeto> projetos = [];
  Map<int, int> progressoPorProjeto = {};

  int diasSequencia = 0;
  int pontosHoje = 0;
  int pontosOntem = 0;
  int pontosSemana = 0;
  int pontosTotais = 0;
  int nivel = 1;

  Set<String> conquistasDesbloqueadas = {};
  List<int> pontosPorDia = List.filled(7, 0);

  bool onboardingConcluido = false;
  String? nomeUsuario;
  String? emailUsuario;

  bool carregando = true;
  String? erro;

  // Tema padrão = Claro (branco)
  ThemeMode tema = ThemeMode.light;

  Future<void> carregar() async {
    await carregarTema();
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
  // Tema
  // ---------------------------------------------------------------

  Future<void> carregarTema() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString('tema') ?? 'light';

    tema = switch (valor) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    notifyListeners();
  }

  Future<void> alterarTema(ThemeMode novoTema) async {
    tema = novoTema;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final valor = switch (novoTema) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      _ => 'light',
    };
    await prefs.setString('tema', valor);
  }

  // ---------------------------------------------------------------
  // Perfil
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

  // ---------------------------------------------------------------
  // Pontos + Sequência
  // ---------------------------------------------------------------

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

    diasSequencia = await _calcularSequencia();

    final segunda = inicioHoje.subtract(Duration(days: agora.weekday - 1));
    pontosPorDia = await _db.pontosPorDiaDaSemana(segunda);

    final desbloqueadas = await _db.listarConquistasDesbloqueadas();
    conquistasDesbloqueadas = desbloqueadas.map((c) => c.conquistaId).toSet();

    if (pontosTotais >= 500 && !conquistasDesbloqueadas.contains('estudioso')) {
      await _db.desbloquearConquista('estudioso');
      conquistasDesbloqueadas.add('estudioso');
    }
  }

  Future<int> _calcularSequencia() async {
    int sequencia = 0;
    DateTime dia = DateTime.now();

    while (true) {
      final inicioDia = DateTime(dia.year, dia.month, dia.day);
      final fimDia = inicioDia
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      final pontosDoDia = await _db.somaPontosEntre(inicioDia, fimDia);

      if (pontosDoDia > 0) {
        sequencia++;
        dia = dia.subtract(const Duration(days: 1));
      } else {
        break;
      }

      if (sequencia > 365) break;
    }

    return sequencia;
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

  Future<void> atualizarProjeto(Projeto projeto) async {
    await _db.atualizarProjeto(projeto);
    final indice = projetos.indexWhere((p) => p.id == projeto.id);
    if (indice != -1) {
      projetos[indice] = projeto;
      notifyListeners();
    }
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
      await _registrarPontos(TipoAcao.concluirProjeto);
      if (!conquistasDesbloqueadas.contains('finalizador')) {
        await _db.desbloquearConquista('finalizador');
        conquistasDesbloqueadas.add('finalizador');
      }
    }
    await _recarregarPontosEConquistas();
  }

  // ---------------------------------------------------------------
  // Itens
  // ---------------------------------------------------------------

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
      await _registrarPontos(TipoAcao.concluirTarefa);
    }

    await _recarregarPontosEConquistas();
    if (item.projetoId != null) {
      await _recalcularProgressoPorTarefas(item.projetoId!);
    }
    notifyListeners();
  }
}