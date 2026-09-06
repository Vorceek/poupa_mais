import '../models/meta.dart';
import 'database_helper.dart';

/// RF11: metas de economia com aportes.
class MetaRepository {
  final DatabaseHelper _dbHelper;

  MetaRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<MetaStatus>> listar(int usuarioId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT m.id, m.usuario_id, m.nome, m.valor_alvo, m.prazo, m.concluida,
             COALESCE((SELECT SUM(a.valor) FROM aporte a WHERE a.meta_id = m.id), 0)
               AS valor_atual
      FROM meta m
      WHERE m.usuario_id = ?
      ORDER BY m.concluida ASC, m.prazo ASC
    ''', [usuarioId]);
    return rows
        .map((row) => MetaStatus(
              meta: Meta.fromMap(row),
              valorAtual: row['valor_atual'] as int,
            ))
        .toList();
  }

  Future<Meta> criar(Meta meta) async {
    final db = await _dbHelper.database;
    final id = await db.insert('meta', meta.toMap()..remove('id'));
    final rows = await db.query('meta', where: 'id = ?', whereArgs: [id]);
    return Meta.fromMap(rows.first);
  }

  Future<void> excluir(int metaId) async {
    final db = await _dbHelper.database;
    await db.delete('meta', where: 'id = ?', whereArgs: [metaId]);
  }

  /// Registra um aporte na meta. Em uma única transação (RNF09):
  ///  1. grava o aporte;
  ///  2. lança a despesa correspondente na categoria "Poupança" (RN07),
  ///     para não inflar artificialmente o saldo disponível;
  ///  3. marca a meta como concluída quando o alvo é atingido (RN06).
  Future<void> registrarAporte({
    required Meta meta,
    required int valor,
    required int categoriaPoupancaId,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final hoje = DateTime.now().toIso8601String().substring(0, 10);
      await txn.insert('aporte', {
        'meta_id': meta.id,
        'valor': valor,
        'data': hoje,
      });
      await txn.insert('lancamento', {
        'usuario_id': meta.usuarioId,
        'categoria_id': categoriaPoupancaId,
        'valor': valor,
        'tipo': 'despesa',
        'data': hoje,
        'descricao': 'Aporte na meta "${meta.nome}"',
        'recorrencia': 'nenhuma',
      });
      final rows = await txn.rawQuery(
          'SELECT COALESCE(SUM(valor), 0) AS total FROM aporte WHERE meta_id = ?',
          [meta.id]);
      final total = rows.first['total'] as int;
      if (total >= meta.valorAlvo) {
        await txn.update('meta', {'concluida': 1},
            where: 'id = ?', whereArgs: [meta.id]);
      }
    });
  }
}
