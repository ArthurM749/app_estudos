import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart' as ffi;

import 'package:app_estudos/data/database_helper.dart';

void main() {
  setUp(() {
    ffi.sqfliteFfiInit();
    databaseFactory = ffi.databaseFactoryFfi;
  });

  test('garante a tabela perfil mesmo quando ela ainda não existe', () async {
    final db = await openDatabase(inMemoryDatabasePath);

    await db.execute('CREATE TABLE projetos (id INTEGER PRIMARY KEY)');
    await DatabaseHelper.instance.garantirTabelaPerfil(db);

    final rows = await db.query('perfil');
    expect(rows, isEmpty);

    await db.insert(
      'perfil',
      {'id': 1, 'nome': 'Ana', 'email': 'ana@test.com', 'pulou': 0},
    );
    final perfil = await db.query('perfil', where: 'id = ?', whereArgs: [1]);

    expect(perfil.single['nome'], 'Ana');
    await db.close();
  });
}
