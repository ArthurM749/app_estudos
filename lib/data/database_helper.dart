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
  // Itens (anotações, tarefas, ideias)
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
