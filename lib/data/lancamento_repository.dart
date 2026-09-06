import '../models/lancamento.dart';
import 'database_helper.dart';

/// Totais do mês exibidos no painel (RF07).
/// RN02: saldo = total de receitas do mês - total de despesas do mês.
class ResumoMensal {
  final int totalReceitas;
  final int totalDespesas;

  const ResumoMensal({required this.totalReceitas, required this.totalDespesas});

  int get saldo => totalReceitas - totalDespesas;
}

class FiltroExtrato {
  final DateTime inicio;
  final DateTime fim;
  final int? categoriaId;
  final TipoLancamento? tipo;
  final String busca;

  const FiltroExtrato({
    required this.inicio,
    required this.fim,
    this.categoriaId,
    this.tipo,
    this.busca = '',
  });
}

/// RF03, RF04, RF05, RF08 e RF13.
class LancamentoRepository {
  final DatabaseHelper _dbHelper;

  LancamentoRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static String _dataSql(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<Lancamento> inserir(Lancamento lancamento) async {
    final db = await _dbHelper.database;
    final id = await db.insert('lancamento', lancamento.toMap()..remove('id'));
    final rows = await db.query('lancamento', where: 'id = ?', whereArgs: [id]);
    return Lancamento.fromMap(rows.first);
  }

  Future<void> atualizar(Lancamento lancamento) async {
    final db = await _dbHelper.database;
    await db.update('lancamento', lancamento.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [lancamento.id]);
  }

  Future<void> excluir(int id) async {
    final db = await _dbHelper.database;
    await db.delete('lancamento', where: 'id = ?', whereArgs: [id]);
  }

  /// Extrato com filtros por período, categoria, tipo e busca textual (RF08).
  Future<List<Lancamento>> listar(int usuarioId, FiltroExtrato filtro) async {
    final db = await _dbHelper.database;
    final where = StringBuffer('usuario_id = ? AND data BETWEEN ? AND ?');
    final args = <Object?>[
      usuarioId,
      _dataSql(filtro.inicio),
      _dataSql(filtro.fim),
    ];
    if (filtro.categoriaId != null) {
      where.write(' AND categoria_id = ?');
      args.add(filtro.categoriaId);
    }
    if (filtro.tipo != null) {
      where.write(' AND tipo = ?');
      args.add(filtro.tipo!.name);
    }
    if (filtro.busca.trim().isNotEmpty) {
      where.write(' AND descricao LIKE ?');
      args.add('%${filtro.busca.trim()}%');
    }
    final rows = await db.query('lancamento',
        where: where.toString(), whereArgs: args, orderBy: 'data DESC, id DESC');
    return rows.map(Lancamento.fromMap).toList();
  }

  Future<List<Lancamento>> ultimos(int usuarioId, {int limite = 5}) async {
    final db = await _dbHelper.database;
    final rows = await db.query('lancamento',
        where: 'usuario_id = ?',
        whereArgs: [usuarioId],
        orderBy: 'data DESC, id DESC',
        limit: limite);
    return rows.map(Lancamento.fromMap).toList();
  }

  Future<ResumoMensal> resumoDoMes(int usuarioId, DateTime mes) async {
    final db = await _dbHelper.database;
    final inicio = DateTime(mes.year, mes.month, 1);
    final fim = DateTime(mes.year, mes.month + 1, 0);
    final rows = await db.rawQuery('''
      SELECT tipo, COALESCE(SUM(valor), 0) AS total
      FROM lancamento
      WHERE usuario_id = ? AND data BETWEEN ? AND ?
      GROUP BY tipo
    ''', [usuarioId, _dataSql(inicio), _dataSql(fim)]);
    var receitas = 0;
    var despesas = 0;
    for (final row in rows) {
      if (row['tipo'] == 'receita') {
        receitas = row['total'] as int;
      } else {
        despesas = row['total'] as int;
      }
    }
    return ResumoMensal(totalReceitas: receitas, totalDespesas: despesas);
  }

  /// Total de despesas por categoria no mês (RF12, gráfico de rosca).
  Future<Map<int, int>> despesasPorCategoria(int usuarioId, DateTime mes) async {
    final db = await _dbHelper.database;
    final inicio = DateTime(mes.year, mes.month, 1);
    final fim = DateTime(mes.year, mes.month + 1, 0);
    final rows = await db.rawQuery('''
      SELECT categoria_id, COALESCE(SUM(valor), 0) AS total
      FROM lancamento
      WHERE usuario_id = ? AND tipo = 'despesa' AND data BETWEEN ? AND ?
      GROUP BY categoria_id
      ORDER BY total DESC
    ''', [usuarioId, _dataSql(inicio), _dataSql(fim)]);
    return {
      for (final row in rows) row['categoria_id'] as int: row['total'] as int,
    };
  }

  /// Evolução das despesas dos últimos [meses] meses (RF12, gráfico de barras).
  Future<List<({DateTime mes, int total})>> serieMensalDespesas(
      int usuarioId, {int meses = 6}) async {
    final resultado = <({DateTime mes, int total})>[];
    final hoje = DateTime.now();
    for (var i = meses - 1; i >= 0; i--) {
      final mes = DateTime(hoje.year, hoje.month - i, 1);
      final resumo = await resumoDoMes(usuarioId, mes);
      resultado.add((mes: mes, total: resumo.totalDespesas));
    }
    return resultado;
  }

  /// RF13: gera automaticamente as ocorrências pendentes dos lançamentos
  /// marcados como recorrentes (mensal ou semanal), até a data de hoje.
  /// Chamado na abertura do app.
  Future<int> gerarRecorrentesPendentes(int usuarioId) async {
    final db = await _dbHelper.database;
    final templates = await db.query('lancamento',
        where: "usuario_id = ? AND recorrencia != 'nenhuma' "
            'AND origem_recorrente_id IS NULL',
        whereArgs: [usuarioId]);

    var gerados = 0;
    final hoje = DateTime.now();
    for (final row in templates) {
      final template = Lancamento.fromMap(row);
      final ocorrencias = proximasOcorrencias(
          template.data, template.recorrencia, hoje);
      for (final data in ocorrencias) {
        final existentes = await db.query('lancamento',
            where: 'origem_recorrente_id = ? AND data = ?',
            whereArgs: [template.id, _dataSql(data)]);
        if (existentes.isNotEmpty) continue;
        await db.insert('lancamento', {
          'usuario_id': template.usuarioId,
          'categoria_id': template.categoriaId,
          'valor': template.valor,
          'tipo': template.tipo.name,
          'data': _dataSql(data),
          'descricao': template.descricao,
          'recorrencia': 'nenhuma',
          'origem_recorrente_id': template.id,
        });
        gerados++;
      }
    }
    return gerados;
  }

  /// Datas de ocorrência de uma recorrência entre a data base (exclusiva)
  /// e [ate] (inclusiva). Público para permitir teste unitário.
  static List<DateTime> proximasOcorrencias(
      DateTime base, Recorrencia recorrencia, DateTime ate) {
    final datas = <DateTime>[];
    final limite = DateTime(ate.year, ate.month, ate.day);
    if (recorrencia == Recorrencia.semanal) {
      var d = base.add(const Duration(days: 7));
      while (!d.isAfter(limite) && datas.length < 260) {
        datas.add(DateTime(d.year, d.month, d.day));
        d = d.add(const Duration(days: 7));
      }
    } else if (recorrencia == Recorrencia.mensal) {
      var i = 1;
      while (i <= 60) {
        final alvo = DateTime(base.year, base.month + i, 1);
        final ultimoDia = DateTime(alvo.year, alvo.month + 1, 0).day;
        final d = DateTime(
            alvo.year, alvo.month, base.day > ultimoDia ? ultimoDia : base.day);
        if (d.isAfter(limite)) break;
        datas.add(d);
        i++;
      }
    }
    return datas;
  }

  /// RF14: exporta os lançamentos de um período em CSV.
  Future<String> exportarCsv(
      int usuarioId, FiltroExtrato filtro, Map<int, String> nomesCategoria) async {
    final lancamentos = await listar(usuarioId, filtro);
    final buffer = StringBuffer('data;tipo;categoria;descricao;valor\n');
    for (final l in lancamentos) {
      final valor = (l.valor / 100).toStringAsFixed(2).replaceAll('.', ',');
      final descricao = l.descricao.replaceAll(';', ',');
      buffer.writeln('${_dataSql(l.data)};${l.tipo.name};'
          '${nomesCategoria[l.categoriaId] ?? ''};$descricao;$valor');
    }
    return buffer.toString();
  }
}
