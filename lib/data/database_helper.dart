import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart' as ffi;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as ffi_web;

import '../models/conquista.dart';
import '../models/evento_pontos.dart';
import '../models/item.dart';
import '../models/projeto.dart';

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
    if (kIsWeb) {
      databaseFactory = ffi_web.databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux) {
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
    }

    final path = join(await getDatabasesPath(), 'app_estudos.db');
    return openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE perfil ADD COLUMN tema TEXT NOT NULL DEFAULT 'claro'");
      await db.execute('ALTER TABLE perfil ADD COLUMN criado_em TEXT');
    }
    if (oldVersion < 3) {
      // Pontos idempotentes: eventos antigos ficam com referência nula (o índice
      // parcial ignora nulos) e só os novos passam a ser deduplicados.
      await db.execute('ALTER TABLE eventos_pontos ADD COLUMN referencia TEXT');
      await db.execute(_sqlIndicePontosUnicos);
    }
    if (oldVersion < 4) {
      // Anotações publicadas guardam o id do post correspondente no Supabase.
      await db.execute('ALTER TABLE itens ADD COLUMN publicacao_id TEXT');
    }
    if (oldVersion < 5) {
      // Fila de saída: o que foi publicado/editado/apagado sem internet espera
      // aqui até o app conseguir falar com o Supabase.
      await db.execute(
          'ALTER TABLE itens ADD COLUMN sync_pendente INTEGER NOT NULL DEFAULT 0');
      await _criarTabelasDaFila(db);
    }
  }

  Future<void> _criarTabelasDaFila(Database db) async {
    // Atividades compartilhadas (conquista, projeto, sequência, evolução).
    await db.execute('''
      CREATE TABLE publicacoes_pendentes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conta_id TEXT,
        titulo TEXT,
        conteudo TEXT NOT NULL,
        tipo TEXT NOT NULL,
        meta TEXT NOT NULL,
        criado_em TEXT NOT NULL
      )
    ''');
    // Publicações que precisam sair da nuvem porque a anotação foi apagada.
    await db.execute('''
      CREATE TABLE remocoes_pendentes (
        publicacao_id TEXT PRIMARY KEY,
        conta_id TEXT
      )
    ''');
  }

  static const _sqlIndicePontosUnicos =
      'CREATE UNIQUE INDEX idx_pontos_referencia ON eventos_pontos (tipo, referencia) '
      'WHERE referencia IS NOT NULL';

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
        publicacao_id TEXT,
        sync_pendente INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (projeto_id) REFERENCES projetos (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE eventos_pontos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        pontos INTEGER NOT NULL,
        data TEXT NOT NULL,
        referencia TEXT
      )
    ''');
    await db.execute(_sqlIndicePontosUnicos);

    await db.execute('''
      CREATE TABLE conquistas_desbloqueadas (
        conquista_id TEXT PRIMARY KEY,
        desbloqueada_em TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_itens_projeto ON itens (projeto_id)');
    await _criarTabelasDaFila(db);

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

  Future<int> inserirProjeto(Projeto projeto) async {
    final db = await database;
    return db.insert('projetos', projeto.toMap()..remove('id'));
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

  /// A publicação sumiu do Supabase (apagada pelo feed ou perfil): a anotação
  /// correspondente volta a ser privada, para a tela não mostrar "publicada"
  /// para algo que já não está no ar.
  Future<void> marcarAnotacaoPrivada(String publicacaoId) async {
    final db = await database;
    await db.update(
      'itens',
      {
        'publicacao_id': null,
        'visibilidade': Visibilidade.privada.name,
        'sync_pendente': 0,
      },
      where: 'publicacao_id = ?',
      whereArgs: [publicacaoId],
    );
  }

  // ------------------------------------------------------- fila de saída

  /// Anotações cujo estado na nuvem ainda não bate com o que a pessoa escolheu.
  Future<List<Item>> listarAnotacoesPendentes() async {
    final db = await database;
    final linhas = await db.query(
      'itens',
      where: "tipo = 'anotacao' AND ("
          "(visibilidade = 'publica' AND (publicacao_id IS NULL OR sync_pendente = 1)) "
          "OR (visibilidade = 'privada' AND publicacao_id IS NOT NULL))",
    );
    return linhas.map(Item.fromMap).toList();
  }

  /// Grava só o estado de envio, sem mexer no texto (o texto pode ter sido
  /// editado enquanto o envio acontecia).
  Future<void> definirEnvioDoItem(
    int itemId, {
    required String? publicacaoId,
    required bool pendente,
  }) async {
    final db = await database;
    await db.update(
      'itens',
      {'publicacao_id': publicacaoId, 'sync_pendente': pendente ? 1 : 0},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  /// A publicação não existe mais: a anotação volta a ser privada.
  Future<void> tornarAnotacaoPrivada(int itemId) async {
    final db = await database;
    await db.update(
      'itens',
      {
        'publicacao_id': null,
        'visibilidade': Visibilidade.privada.name,
        'sync_pendente': 0,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> adicionarRemocaoPendente(
      String publicacaoId, String? contaId) async {
    final db = await database;
    await db.insert(
      'remocoes_pendentes',
      {'publicacao_id': publicacaoId, 'conta_id': contaId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> listarRemocoesPendentes(String contaId) async {
    final db = await database;
    final linhas = await db.query(
      'remocoes_pendentes',
      where: 'conta_id = ? OR conta_id IS NULL',
      whereArgs: [contaId],
    );
    return linhas.map((l) => l['publicacao_id'] as String).toList();
  }

  Future<void> removerRemocaoPendente(String publicacaoId) async {
    final db = await database;
    await db.delete('remocoes_pendentes',
        where: 'publicacao_id = ?', whereArgs: [publicacaoId]);
  }

  Future<void> adicionarPublicacaoPendente({
    required String? contaId,
    required String? titulo,
    required String conteudo,
    required String tipo,
    required String metaJson,
  }) async {
    final db = await database;
    await db.insert('publicacoes_pendentes', {
      'conta_id': contaId,
      'titulo': titulo,
      'conteudo': conteudo,
      'tipo': tipo,
      'meta': metaJson,
      'criado_em': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> listarPublicacoesPendentes(
      String contaId) async {
    final db = await database;
    return db.query(
      'publicacoes_pendentes',
      where: 'conta_id = ? OR conta_id IS NULL',
      whereArgs: [contaId],
      orderBy: 'id ASC',
    );
  }

  Future<void> removerPublicacaoPendente(int id) async {
    final db = await database;
    await db.delete('publicacoes_pendentes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> excluirItem(int id) async {
    final db = await database;
    return db.delete('itens', where: 'id = ?', whereArgs: [id]);
  }

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

  Future<int> progressoPorTarefas(int projetoId) async {
    final db = await database;
    final total = Sqflite.firstIntValue(await db.rawQuery(
          "SELECT COUNT(*) FROM itens WHERE projeto_id = ? AND tipo = 'tarefa'",
          [projetoId],
        )) ??
        0;
    if (total == 0) return 0;

    final concluidas = Sqflite.firstIntValue(await db.rawQuery(
          "SELECT COUNT(*) FROM itens WHERE projeto_id = ? AND tipo = 'tarefa' AND concluido = 1",
          [projetoId],
        )) ??
        0;

    return ((concluidas / total) * 100).round();
  }

  Future<void> salvarPerfil({
    String? nome,
    String? email,
    required bool pulou,
  }) async {
    final db = await database;
    final existente = await obterPerfil();
    await db.insert(
      'perfil',
      {
        'id': 1,
        'nome': nome,
        'email': email,
        'pulou': pulou ? 1 : 0,
        'tema': existente?['tema'] ?? 'claro',
        // Preserva a data original: regravar o perfil não é "começar a
        // estudar" de novo.
        'criado_em':
            existente?['criado_em'] ?? DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Object?>?> obterPerfil() async {
    final db = await database;
    final resultados = await db.query('perfil', where: 'id = 1', limit: 1);
    return resultados.isEmpty ? null : resultados.first;
  }

  Future<void> atualizarTema(String tema) async {
    final db = await database;
    await db.update('perfil', {'tema': tema}, where: 'id = 1');
  }

  /// Mantém o nome local igual ao do perfil público (uma identidade só).
  Future<void> atualizarNome(String nome) async {
    final db = await database;
    await db.update('perfil', {'nome': nome}, where: 'id = 1');
  }

  Future<void> apagarPerfil() async {
    final db = await database;
    await db.delete('perfil');
  }

  Future<void> apagarTudo() async {
    final db = await database;
    await db.delete('itens');
    await db.delete('projetos');
    await db.delete('eventos_pontos');
    await db.delete('conquistas_desbloqueadas');
    await db.delete('perfil');
    await db.delete('publicacoes_pendentes');
    await db.delete('remocoes_pendentes');
  }

  Future<int> registrarPontos(EventoDePontos evento) async {
    final db = await database;
    // ignore: se a referência já gerou pontos desse tipo, não duplica.
    return db.insert(
      'eventos_pontos',
      evento.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

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

  Future<List<DateTime>> diasComPontosDistintos() async {
    final db = await database;
    final linhas =
        await db.rawQuery('SELECT DISTINCT data FROM eventos_pontos');
    final dias = linhas
        .map((linha) {
          final data = DateTime.parse(linha['data'] as String);
          return DateTime(data.year, data.month, data.day);
        })
        .toSet()
        .toList();
    dias.sort((a, b) => b.compareTo(a));
    return dias;
  }

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
