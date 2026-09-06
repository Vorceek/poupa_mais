import '../models/orcamento.dart';
import 'database_helper.dart';

/// RF09/RF10: teto de gasto mensal por categoria e consumo no mês corrente.
/// RN05: o orçamento é sempre mensal e o consumo reinicia no primeiro dia de
/// cada mês, já que o cálculo soma apenas os lançamentos do mês de referência.
class OrcamentoRepository {
  final DatabaseHelper _dbHelper;

  OrcamentoRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Orcamento>> listar(int usuarioId) async {
    final db = await _dbHelper.database;
    final rows = await db
        .query('orcamento', where: 'usuario_id = ?', whereArgs: [usuarioId]);
    return rows.map(Orcamento.fromMap).toList();
  }

  /// Cria ou atualiza o teto da categoria (UNIQUE usuario_id + categoria_id).
  Future<void> definir(Orcamento orcamento) async {
    final db = await _dbHelper.database;
    await db.rawInsert('''
      INSERT INTO orcamento (usuario_id, categoria_id, valor_teto)
      VALUES (?, ?, ?)
      ON CONFLICT (usuario_id, categoria_id)
      DO UPDATE SET valor_teto = excluded.valor_teto
    ''', [orcamento.usuarioId, orcamento.categoriaId, orcamento.valorTeto]);
  }

  Future<void> remover(int orcamentoId) async {
    final db = await _dbHelper.database;
    await db.delete('orcamento', where: 'id = ?', whereArgs: [orcamentoId]);
  }

  /// Status de todos os orçamentos no mês: teto x gasto realizado.
  Future<List<OrcamentoStatus>> statusDoMes(int usuarioId, DateTime mes) async {
    final db = await _dbHelper.database;
    final inicio =
        DateTime(mes.year, mes.month, 1).toIso8601String().substring(0, 10);
    final fim =
        DateTime(mes.year, mes.month + 1, 0).toIso8601String().substring(0, 10);
    final rows = await db.rawQuery('''
      SELECT o.id, o.usuario_id, o.categoria_id, o.valor_teto,
             COALESCE((
               SELECT SUM(l.valor) FROM lancamento l
               WHERE l.usuario_id = o.usuario_id
                 AND l.categoria_id = o.categoria_id
                 AND l.tipo = 'despesa'
                 AND l.data BETWEEN ? AND ?
             ), 0) AS gasto
      FROM orcamento o
      WHERE o.usuario_id = ?
    ''', [inicio, fim, usuarioId]);
    final status = rows
        .map((row) => OrcamentoStatus(
              orcamento: Orcamento.fromMap(row),
              gasto: row['gasto'] as int,
            ))
        .toList();
    // Mais críticos primeiro, como na tela 6 do protótipo.
    status.sort((a, b) => b.percentual.compareTo(a.percentual));
    return status;
  }
}
