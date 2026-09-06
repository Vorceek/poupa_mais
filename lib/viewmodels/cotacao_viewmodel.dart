import 'package:flutter/foundation.dart';

import '../data/cotacao_service.dart';
import '../models/cotacao.dart';

/// Estado do card de cotações do painel (integração com API).
class CotacaoViewModel extends ChangeNotifier {
  final CotacaoService _service;

  List<Cotacao> _cotacoes = [];
  bool _carregando = false;
  bool _offline = false;
  bool _falhou = false;

  CotacaoViewModel({CotacaoService? service})
      : _service = service ?? CotacaoService();

  List<Cotacao> get cotacoes => _cotacoes;
  bool get carregando => _carregando;

  /// true quando os dados exibidos vieram do cache local (sem conexão).
  bool get offline => _offline;
  bool get falhou => _falhou;

  Future<void> carregar() async {
    _carregando = true;
    _falhou = false;
    notifyListeners();
    try {
      final resultado = await _service.buscar();
      _cotacoes = resultado.cotacoes;
      _offline = resultado.doCache;
    } catch (_) {
      // Sem conexão e sem cache: o card simplesmente não aparece.
      _falhou = true;
      _cotacoes = [];
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}
