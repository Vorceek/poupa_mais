import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/usuario_repository.dart';
import '../models/usuario.dart';

/// Sessão do usuário (RF01): login, cadastro, modo local e logout.
/// O id do usuário logado fica em SharedPreferences para reabrir o app
/// direto no painel.
class SessaoViewModel extends ChangeNotifier {
  static const _prefUsuarioId = 'usuario_logado_id';
  static const _prefOnboarding = 'onboarding_concluido_';

  final UsuarioRepository _repo;

  Usuario? _usuario;
  bool _onboardingConcluido = false;
  bool _carregando = false;
  String? _erro;

  SessaoViewModel({UsuarioRepository? repo})
      : _repo = repo ?? UsuarioRepository();

  Usuario? get usuario => _usuario;
  bool get logado => _usuario != null;
  bool get onboardingConcluido => _onboardingConcluido;
  bool get carregando => _carregando;
  String? get erro => _erro;

  /// Restaura a sessão salva. Retorna true se havia usuário logado.
  Future<bool> restaurarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_prefUsuarioId);
    if (id == null) return false;
    _usuario = await _repo.buscarPorId(id);
    if (_usuario != null) {
      _onboardingConcluido =
          prefs.getBool('$_prefOnboarding${_usuario!.id}') ?? false;
    }
    notifyListeners();
    return _usuario != null;
  }

  Future<bool> entrar(String email, String senha) =>
      _executar(() => _repo.entrar(email: email, senha: senha));

  Future<bool> cadastrar(String nome, String email, String senha) =>
      _executar(() => _repo.cadastrar(nome: nome, email: email, senha: senha));

  Future<bool> entrarModoLocal() => _executar(_repo.entrarModoLocal);

  Future<bool> _executar(Future<Usuario> Function() acao) async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      _usuario = await acao();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefUsuarioId, _usuario!.id!);
      _onboardingConcluido =
          prefs.getBool('$_prefOnboarding${_usuario!.id}') ?? false;
      return true;
    } catch (e) {
      _erro = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> concluirOnboarding({required int rendaMensal}) async {
    if (_usuario == null) return;
    _usuario = _usuario!.copyWith(rendaMensal: rendaMensal);
    await _repo.atualizar(_usuario!);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefOnboarding${_usuario!.id}', true);
    _onboardingConcluido = true;
    notifyListeners();
  }

  Future<void> atualizarPerfil({String? nome, int? rendaMensal}) async {
    if (_usuario == null) return;
    _usuario = _usuario!.copyWith(nome: nome, rendaMensal: rendaMensal);
    await _repo.atualizar(_usuario!);
    notifyListeners();
  }

  Future<void> sair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUsuarioId);
    _usuario = null;
    _onboardingConcluido = false;
    notifyListeners();
  }

  /// RNF05 (LGPD): exclui a conta e todos os dados locais do usuário.
  Future<void> excluirConta() async {
    if (_usuario == null) return;
    await _repo.excluirConta(_usuario!.id!);
    await sair();
  }
}
