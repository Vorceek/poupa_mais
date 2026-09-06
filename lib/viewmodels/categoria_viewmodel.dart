import 'package:flutter/foundation.dart';

import '../data/categoria_repository.dart';
import '../models/categoria.dart';

/// RF06: gestão de categorias.
class CategoriaViewModel extends ChangeNotifier {
  final CategoriaRepository _repo;

  List<Categoria> _todas = [];
  bool _carregando = false;

  CategoriaViewModel({CategoriaRepository? repo})
      : _repo = repo ?? CategoriaRepository();

  List<Categoria> get todas => _todas;
  List<Categoria> get ativas => _todas.where((c) => c.ativa).toList();
  bool get carregando => _carregando;

  Future<void> carregar() async {
    _carregando = true;
    notifyListeners();
    _todas = await _repo.listar();
    _carregando = false;
    notifyListeners();
  }

  Future<void> criar(String nome, int icone, int cor) async {
    await _repo.criar(Categoria(nome: nome.trim(), icone: icone, cor: cor));
    await carregar();
  }

  Future<void> atualizar(Categoria categoria) async {
    await _repo.atualizar(categoria);
    await carregar();
  }

  /// RN04: exclui se não houver lançamentos; caso contrário, desativa.
  /// Retorna true quando foi realmente excluída.
  Future<bool> excluirOuDesativar(Categoria categoria) async {
    final tinhaLancamentos = await _repo.possuiLancamentos(categoria.id!);
    await _repo.excluirOuDesativar(categoria.id!);
    await carregar();
    return !tinhaLancamentos;
  }

  Future<void> reativar(Categoria categoria) async {
    await _repo.reativar(categoria.id!);
    await carregar();
  }
}
