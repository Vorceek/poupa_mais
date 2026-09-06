import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/usuario.dart';
import 'database_helper.dart';

/// RF01: cadastro, autenticação e modo local sem conta.
/// RNF04: a senha nunca é gravada em texto puro; armazenamos SHA-256(sal+senha)
/// com sal aleatório por usuário.
class UsuarioRepository {
  final DatabaseHelper _dbHelper;

  UsuarioRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static String gerarSal() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  static String hashSenha(String senha, String sal) =>
      sha256.convert(utf8.encode('$sal$senha')).toString();

  Future<Usuario> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final db = await _dbHelper.database;
    final existente = await db.query('usuario',
        where: 'email = ?', whereArgs: [email.trim().toLowerCase()]);
    if (existente.isNotEmpty) {
      throw Exception('Já existe uma conta com este e-mail.');
    }
    final sal = gerarSal();
    final usuario = Usuario(
      nome: nome.trim(),
      email: email.trim().toLowerCase(),
      senhaHash: hashSenha(senha, sal),
      sal: sal,
      criadoEm: DateTime.now(),
    );
    final id = await db.insert('usuario', usuario.toMap()..remove('id'));
    return (await buscarPorId(id))!;
  }

  Future<Usuario> entrar({required String email, required String senha}) async {
    final db = await _dbHelper.database;
    final rows = await db.query('usuario',
        where: 'email = ?', whereArgs: [email.trim().toLowerCase()]);
    if (rows.isEmpty) {
      throw Exception('E-mail não encontrado. Crie uma conta.');
    }
    final usuario = Usuario.fromMap(rows.first);
    if (usuario.senhaHash != hashSenha(senha, usuario.sal!)) {
      throw Exception('Senha incorreta.');
    }
    return usuario;
  }

  /// Modo local sem conta (RF01): cria (ou reutiliza) um perfil local único.
  Future<Usuario> entrarModoLocal() async {
    final db = await _dbHelper.database;
    final rows = await db.query('usuario', where: 'modo_local = 1', limit: 1);
    if (rows.isNotEmpty) return Usuario.fromMap(rows.first);
    final usuario = Usuario(
      nome: 'Uso local',
      criadoEm: DateTime.now(),
      modoLocal: true,
    );
    final id = await db.insert('usuario', usuario.toMap()..remove('id'));
    return (await buscarPorId(id))!;
  }

  Future<Usuario?> buscarPorId(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('usuario', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Usuario.fromMap(rows.first);
  }

  Future<void> atualizar(Usuario usuario) async {
    final db = await _dbHelper.database;
    await db.update('usuario', usuario.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [usuario.id]);
  }

  /// RNF05 (LGPD): exclusão total da conta e dos dados. As tabelas
  /// dependentes caem em cascata (ON DELETE CASCADE).
  Future<void> excluirConta(int usuarioId) async {
    final db = await _dbHelper.database;
    await db.delete('usuario', where: 'id = ?', whereArgs: [usuarioId]);
  }
}
