import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart' as ffi;
import 'package:path/path.dart';

import '../models/conquista.dart';
import '../models/evento_pontos.dart';
import '../models/item.dart';
import '../models/projeto.dart';

/// Acesso ao banco local (sqflite/SQLite) do aplicativo.
///
/// Decisão do grupo: na versão teste TUDO fica salvo no dispositivo,
/// sem login e sem internet — por isso não existe uma tabela de
/// "usuários" por enquanto; o app assume um usuário local único.
/// Login, sincronização e nuvem (Firebase) só entram numa fase
/// seguinte do projeto.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final created = await _initDatabase();
    _database = created;
    return created;
  }

  Future<Database> _initDatabase() async {
    // sqflite "puro" só funciona em Android/iOS/macOS. Rodando no
    // Windows ou Linux (ex.: alguém testando direto no notebook, sem
    // celular conectado), troca para a implementação de desktop
    // (sqflite_common_ffi) antes de abrir o banco.
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
    }

    final path = join(await getDatabasesPath(), 'app_estudos.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      // O SQLite não aplica "ON DELETE SET NULL" (usado na tabela de
      // itens) a menos que isso seja ligado explicitamente em cada
      // conexão — sem essa linha, excluir um projeto deixaria os
      // itens dele com um projeto_id "fantasma".
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projetos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cor INTEGER NOT NULL,
        modo_progresso TEXT NOT NULL,
        progresso_manual INTEGER NOT NULL DEFAULT 0,
        arquivado INTEGER NOT NULL DEFAULT 0,
        criado_em TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE itens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projeto_id INTEGER,
        tipo TEXT NOT NULL,
        titulo TEXT NOT NULL,
        conteudo TEXT NOT NULL DEFAULT '',
        concluido INTEGER NOT NULL DEFAULT 0,
        visibilidade TEXT NOT NULL DEFAULT 'privada',
        criado_em TEXT NOT NULL,
        FOREIGN KEY (projeto_id) REFERENCES projetos (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE eventos_pontos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        pontos INTEGER NOT NULL,
        data TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE conquistas_desbloqueadas (
        conquista_id TEXT PRIMARY KEY,
        desbloqueada_em TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_itens_projeto ON itens (projeto_id)');

    // Linha única (id sempre 1): guarda se a pessoa criou um perfil
    // local (nome + email) ou escolheu continuar sem conta. Não é
    // autenticação de verdade — isso só existe pra já deixar pronto
    // pra quando a fase de sincronização ligar de fato numa conta.
    await db.execute('''
      CREATE TABLE perfil (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        nome TEXT,
        email TEXT,
        pulou INTEGER NOT NULL DEFAULT 0,
        tema TEXT NOT NULL DEFAULT 'claro',
        criado_em TEXT
      )
    ''');
  }

  // ---------------------------------------------------------------
  // Projetos
  // ---------------------------------------------------------------

  Future<int> inserirProjeto(Projeto projeto) async {
    final db = await database;
    return db.insert('projetos', projeto.toMap()
      ..remove('id'));
  }

  Future<List<Projeto>> listarProjetos({bool incluirArquivados = false}) async {
    final db = await database;
    final where = incluirArquivados ? null : 'arquivado = 0';
    final maps = await db.query(
      'projetos',
      where: where,
      orderBy: 'criado_em DESC',
    );
    return maps.map(Projeto.fromMap).toList();
  }

  Future<int> atualizarProjeto(Projeto projeto) async {
    final db = await database;
    return db.update(
      'projetos',
      projeto.toMap(),
      where: 'id = ?',
      whereArgs: [projeto.id],
    );
  }

  Future<int> excluirProjeto(int id) async {
    final db = await database;
    return db.delete('projetos', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------
  // Itens (anotações, tarefas)
  // ---------------------------------------------------------------

  Future<int> inserirItem(Item item) async {
    final db = await database;
    return db.insert('itens', item.toMap()..remove('id'));
  }

  Future<List<Item>> listarItens({int? projetoId, TipoItem? tipo}) async {
    final db = await database;
    final condicoes = <String>[];
    final args = <Object?>[];

    if (projetoId != null) {
      condicoes.add('projeto_id = ?');
      args.add(projetoId);
    }
    if (tipo != null) {
      condicoes.add('tipo = ?');
      args.add(tipo.name);
    }

    final maps = await db.query(
      'itens',
      where: condicoes.isEmpty ? null : condicoes.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'criado_em DESC',
    );
    return maps.map(Item.fromMap).toList();
  }

  Future<int> atualizarItem(Item item) async {
    final db = await database;
    return db.update(
      'itens',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> excluirItem(int id) async {
    final db = await database;
    return db.delete('itens', where: 'id = ?', whereArgs: [id]);
  }

  /// Lista global de anotações (não restrita a um projeto), com
  /// busca por texto e filtro por projeto — usada na aba Anotações.
  Future<List<Item>> listarAnotacoes({
    bool apenasSemProjeto = false,
    int? projetoId,
    String? busca,
  }) async {
    final db = await database;
    final condicoes = <String>["tipo = 'anotacao'"];
    final args = <Object?>[];

    if (apenasSemProjeto) {
      condicoes.add('projeto_id IS NULL');
    } else if (projetoId != null) {
      condicoes.add('projeto_id = ?');
      args.add(projetoId);
    }

    final termoBusca = busca?.trim() ?? '';
    if (termoBusca.isNotEmpty) {
      condicoes.add('(titulo LIKE ? OR conteudo LIKE ?)');
      args.add('%$termoBusca%');
      args.add('%$termoBusca%');
    }

    final maps = await db.query(
      'itens',
      where: condicoes.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'criado_em DESC',
    );
    return maps.map(Item.fromMap).toList();
  }

  Future<List<Item>> listarAnotacoesRecentes({int limite = 3}) async {
    final db = await database;
    final maps = await db.query(
      'itens',
      where: "tipo = 'anotacao'",
      orderBy: 'criado_em DESC',
      limit: limite,
    );
    return maps.map(Item.fromMap).toList();
  }

  /// Quantos itens de um [tipo] existem (opcionalmente filtrando por
  /// concluído). Usado pelas conquistas que dependem de contagem
  /// ("Biblioteca": 10 anotações, "Mãos à obra": 1ª tarefa feita).
  Future<int> contarItens({required TipoItem tipo, bool? concluido}) async {
    final db = await database;
    final condicoes = <String>['tipo = ?'];
    final args = <Object?>[tipo.name];
    if (concluido != null) {
      condicoes.add('concluido = ?');
      args.add(concluido ? 1 : 0);
    }
    final resultado = await db.rawQuery(
      'SELECT COUNT(*) as c FROM itens WHERE ${condicoes.join(' AND ')}',
      args,
    );
    return Sqflite.firstIntValue(resultado) ?? 0;
  }

  /// Progresso de 0 a 100 de um projeto no modo "por tarefas":
  /// razão entre tarefas concluídas e tarefas totais do projeto.
  Future<int> progressoPorTarefas(int projetoId) async {
    final db = await database;
    final total = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM itens WHERE projeto_id = ? AND tipo = 'tarefa'",
      [projetoId],
    )) ?? 0;
    if (total == 0) return 0;

    final concluidas = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM itens WHERE projeto_id = ? AND tipo = 'tarefa' AND concluido = 1",
      [projetoId],
    )) ?? 0;

    return ((concluidas / total) * 100).round();
  }

  // ---------------------------------------------------------------
  // Perfil local (opcional)
  // ---------------------------------------------------------------

  Future<void> salvarPerfil({
    String? nome,
    String? email,
    required bool pulou,
  }) async {
    final db = await database;
    await db.insert(
      'perfil',
      {
        'id': 1,
        'nome': nome,
        'email': email,
        'pulou': pulou ? 1 : 0,
        'criado_em': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// `null` quando a pessoa ainda não decidiu (nunca viu a tela de
  /// criar perfil / continuar sem conta).
  Future<Map<String, Object?>?> obterPerfil() async {
    final db = await database;
    final resultados = await db.query('perfil', where: 'id = 1', limit: 1);
    return resultados.isEmpty ? null : resultados.first;
  }

  /// Só troca o tema — ao contrário de [salvarPerfil], não substitui
  /// a linha inteira (preserva nome/email/criado_em já salvos).
  Future<void> atualizarTema(String tema) async {
    final db = await database;
    await db.update('perfil', {'tema': tema}, where: 'id = 1');
  }

  /// Apaga TUDO: projetos, itens, pontos, conquistas e perfil. Usado
  /// pelo botão "Apagar todos os dados" — depois disso o app volta a
  /// mostrar a tela de criar perfil, como se fosse a primeira vez.
  Future<void> apagarTudo() async {
    final db = await database;
    await db.delete('itens');
    await db.delete('projetos');
    await db.delete('eventos_pontos');
    await db.delete('conquistas_desbloqueadas');
    await db.delete('perfil');
  }

  // ---------------------------------------------------------------
  // Pontos
  // ---------------------------------------------------------------

  Future<int> registrarPontos(EventoDePontos evento) async {
    final db = await database;
    return db.insert('eventos_pontos', evento.toMap()..remove('id'));
  }

  /// Soma de pontos entre duas datas (inclusivo), usada para "hoje",
  /// "ontem" e totais de semana/mês no dashboard.
  Future<int> somaPontosEntre(DateTime inicio, DateTime fim) async {
    final db = await database;
    final resultado = await db.rawQuery(
      'SELECT SUM(pontos) as total FROM eventos_pontos WHERE data BETWEEN ? AND ?',
      [inicio.toIso8601String(), fim.toIso8601String()],
    );
    final total = resultado.first['total'];
    return (total as int?) ?? 0;
  }

  Future<int> pontosTotais() async {
    final db = await database;
    final resultado =
        await db.rawQuery('SELECT SUM(pontos) as total FROM eventos_pontos');
    final total = resultado.first['total'];
    return (total as int?) ?? 0;
  }

  /// Todo dia (sem hora) em que o usuário ganhou pelo menos 1 ponto,
  /// do mais recente pro mais antigo. Usado pra calcular a sequência
  /// de dias seguidos estudando.
  Future<List<DateTime>> diasComPontosDistintos() async {
    final db = await database;
    final linhas = await db.rawQuery('SELECT DISTINCT data FROM eventos_pontos');
    final dias = linhas.map((linha) {
      final data = DateTime.parse(linha['data'] as String);
      return DateTime(data.year, data.month, data.day);
    }).toSet().toList();
    dias.sort((a, b) => b.compareTo(a));
    return dias;
  }

  /// 7 valores (pontos ganhos naquele dia), de segunda a domingo da
  /// semana de [segunda].
  Future<List<int>> pontosPorDiaDaSemana(DateTime segunda) async {
    final resultados = <int>[];
    for (var i = 0; i < 7; i++) {
      final dia = segunda.add(Duration(days: i));
      final inicio = DateTime(dia.year, dia.month, dia.day);
      final fim = inicio
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      resultados.add(await somaPontosEntre(inicio, fim));
    }
    return resultados;
  }

  // ---------------------------------------------------------------
  // Conquistas
  // ---------------------------------------------------------------

  Future<void> desbloquearConquista(String conquistaId) async {
    final db = await database;
    await db.insert(
      'conquistas_desbloqueadas',
      ConquistaDesbloqueada(
        conquistaId: conquistaId,
        desbloqueadaEm: DateTime.now(),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<ConquistaDesbloqueada>> listarConquistasDesbloqueadas() async {
    final db = await database;
    final maps = await db.query('conquistas_desbloqueadas');
    return maps.map(ConquistaDesbloqueada.fromMap).toList();
  }
}
