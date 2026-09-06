import '../models/categoria.dart';
import 'database_helper.dart';

/// RF06: gestão de categorias (padrão + personalizadas).
class CategoriaRepository {
  final DatabaseHelper _dbHelper;

  CategoriaRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Categoria>> listar({bool somenteAtivas = false}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'categoria',
      where: somenteAtivas ? 'ativa = 1' : null,
      orderBy: 'nome COLLATE NOCASE',
    );
    return rows.map(Categoria.fromMap).toList();
  }

  Future<Categoria?> buscarPorId(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('categoria', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Categoria.fromMap(rows.first);
  }

  Future<Categoria?> buscarPorNome(String nome) async {
    final db = await _dbHelper.database;
    final rows = await db.query('categoria',
        where: 'nome = ? COLLATE NOCASE', whereArgs: [nome]);
    return rows.isEmpty ? null : Categoria.fromMap(rows.first);
  }

  Future<Categoria> criar(Categoria categoria) async {
    final db = await _dbHelper.database;
    final id = await db.insert('categoria', categoria.toMap()..remove('id'));
    return (await buscarPorId(id))!;
  }

  Future<void> atualizar(Categoria categoria) async {
    final db = await _dbHelper.database;
    await db.update('categoria', categoria.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [categoria.id]);
  }

  Future<bool> possuiLancamentos(int categoriaId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM lancamento WHERE categoria_id = ?',
        [categoriaId]);
    return (rows.first['total'] as int) > 0;
  }

  /// RN04: uma categoria com lançamentos vinculados não pode ser excluída,
  /// apenas desativada, preservando o histórico.
  Future<void> excluirOuDesativar(int categoriaId) async {
    final db = await _dbHelper.database;
    if (await possuiLancamentos(categoriaId)) {
      await db.update('categoria', {'ativa': 0},
          where: 'id = ?', whereArgs: [categoriaId]);
    } else {
      await db.delete('categoria', where: 'id = ?', whereArgs: [categoriaId]);
    }
  }

  Future<void> reativar(int categoriaId) async {
    final db = await _dbHelper.database;
    await db.update('categoria', {'ativa': 1},
        where: 'id = ?', whereArgs: [categoriaId]);
  }
}
