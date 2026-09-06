import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Acesso único ao banco SQLite local (RNF03: operação 100% offline;
/// RNF09: gravação transacional — nenhum lançamento é perdido em caso de
/// encerramento abrupto, pois o SQLite confirma cada escrita em transação).
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'poupa_mais.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT UNIQUE,
        senha_hash TEXT,
        sal TEXT,
        renda_mensal INTEGER NOT NULL DEFAULT 0,
        criado_em TEXT NOT NULL,
        modo_local INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE categoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        icone INTEGER NOT NULL,
        cor INTEGER NOT NULL,
        ativa INTEGER NOT NULL DEFAULT 1,
        padrao INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE lancamento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
        categoria_id INTEGER NOT NULL REFERENCES categoria(id),
        valor INTEGER NOT NULL CHECK (valor > 0),
        tipo TEXT NOT NULL CHECK (tipo IN ('despesa', 'receita')),
        data TEXT NOT NULL,
        descricao TEXT NOT NULL DEFAULT '',
        recorrencia TEXT NOT NULL DEFAULT 'nenhuma',
        origem_recorrente_id INTEGER
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_lancamento_usuario_data ON lancamento (usuario_id, data)');
    await db.execute('''
      CREATE TABLE orcamento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
        categoria_id INTEGER NOT NULL REFERENCES categoria(id),
        valor_teto INTEGER NOT NULL CHECK (valor_teto > 0),
        UNIQUE (usuario_id, categoria_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE meta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
        nome TEXT NOT NULL,
        valor_alvo INTEGER NOT NULL CHECK (valor_alvo > 0),
        prazo TEXT NOT NULL,
        concluida INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE aporte (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meta_id INTEGER NOT NULL REFERENCES meta(id) ON DELETE CASCADE,
        valor INTEGER NOT NULL CHECK (valor > 0),
        data TEXT NOT NULL
      )
    ''');

    // Categorias padrão (RF06). "Poupança" recebe os aportes de metas (RN07).
    final defaults = <Map<String, Object?>>[
      {'nome': 'Alimentação', 'icone': 1, 'cor': 0xFF0D6E62},
      {'nome': 'Transporte', 'icone': 2, 'cor': 0xFF2E7DA6},
      {'nome': 'Moradia', 'icone': 3, 'cor': 0xFF6A4FA3},
      {'nome': 'Lazer', 'icone': 4, 'cor': 0xFFE08B00},
      {'nome': 'Saúde', 'icone': 5, 'cor': 0xFFB3261E},
      {'nome': 'Educação', 'icone': 6, 'cor': 0xFF1F7A3F},
      {'nome': 'Poupança', 'icone': 7, 'cor': 0xFF08483F},
      {'nome': 'Salário', 'icone': 10, 'cor': 0xFF1F7A3F},
      {'nome': 'Outros', 'icone': 9, 'cor': 0xFF5B6663},
    ];
    for (final c in defaults) {
      await db.insert('categoria', {...c, 'ativa': 1, 'padrao': 1});
    }
  }

  /// Usado nos testes para injetar um banco em memória.
  @visibleForTesting
  void overrideDatabase(Database db) => _db = db;

  @visibleForTesting
  Future<void> createSchema(Database db) => _onCreate(db, _dbVersion);
}
