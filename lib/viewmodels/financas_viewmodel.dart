import 'package:flutter/foundation.dart';

import '../core/formatters.dart';
import '../data/categoria_repository.dart';
import '../data/lancamento_repository.dart';
import '../data/meta_repository.dart';
import '../data/orcamento_repository.dart';
import '../models/categoria.dart';
import '../models/lancamento.dart';
import '../models/meta.dart';
import '../models/orcamento.dart';

/// ViewModel central das finanças: mantém o estado do mês corrente
/// (resumo, extrato, orçamentos, metas e relatórios) e o recarrega de forma
/// consistente após cada mutação. As regras RN01–RN07 são aplicadas aqui e
/// nos repositórios, nunca na camada de interface (RNF10).
class FinancasViewModel extends ChangeNotifier {
  final LancamentoRepository _lancamentos;
  final OrcamentoRepository _orcamentos;
  final MetaRepository _metas;
  final CategoriaRepository _categorias;

  FinancasViewModel({
    LancamentoRepository? lancamentos,
    OrcamentoRepository? orcamentos,
    MetaRepository? metas,
    CategoriaRepository? categorias,
  })  : _lancamentos = lancamentos ?? LancamentoRepository(),
        _orcamentos = orcamentos ?? OrcamentoRepository(),
        _metas = metas ?? MetaRepository(),
        _categorias = categorias ?? CategoriaRepository();

  int? _usuarioId;
  bool _carregando = false;

  ResumoMensal _resumo = const ResumoMensal(totalReceitas: 0, totalDespesas: 0);
  List<Lancamento> _ultimos = [];
  List<Lancamento> _extrato = [];
  List<OrcamentoStatus> _statusOrcamentos = [];
  List<MetaStatus> _statusMetas = [];
  Map<int, Categoria> _categoriasPorId = {};
  Map<int, int> _despesasPorCategoria = {};
  List<({DateTime mes, int total})> _serieMensal = [];
  FiltroExtrato? _filtroAtual;

  bool get carregando => _carregando;
  ResumoMensal get resumo => _resumo;
  List<Lancamento> get ultimos => _ultimos;
  List<Lancamento> get extrato => _extrato;
  List<OrcamentoStatus> get statusOrcamentos => _statusOrcamentos;
  List<MetaStatus> get statusMetas => _statusMetas;
  Map<int, Categoria> get categoriasPorId => _categoriasPorId;
  Map<int, int> get despesasPorCategoria => _despesasPorCategoria;
  List<({DateTime mes, int total})> get serieMensal => _serieMensal;
  FiltroExtrato? get filtroAtual => _filtroAtual;

  /// Percentual agregado do orçamento do mês (barra do painel, tela 3).
  double get percentualOrcamentoGeral {
    final teto = _statusOrcamentos.fold<int>(
        0, (soma, s) => soma + s.orcamento.valorTeto);
    if (teto <= 0) return 0;
    final gasto =
        _statusOrcamentos.fold<int>(0, (soma, s) => soma + s.gasto);
    return (gasto / teto).clamp(0.0, 9.99);
  }

  Categoria? categoria(int id) => _categoriasPorId[id];

  /// Última categoria usada em despesa, sugerida no formulário (RF03).
  int? get ultimaCategoriaDespesa {
    for (final l in _ultimos) {
      if (l.tipo == TipoLancamento.despesa &&
          _categoriasPorId[l.categoriaId]?.nome != 'Poupança') {
        return l.categoriaId;
      }
    }
    return null;
  }

  /// Carga inicial: gera recorrências pendentes (RF13) e lê tudo do banco.
  Future<void> iniciar(int usuarioId) async {
    _usuarioId = usuarioId;
    _carregando = true;
    notifyListeners();
    await _lancamentos.gerarRecorrentesPendentes(usuarioId);
    await recarregar();
    _carregando = false;
    notifyListeners();
  }

  Future<void> recarregar() async {
    final id = _usuarioId;
    if (id == null) return;
    final hoje = DateTime.now();
    final categorias = await _categorias.listar();
    _categoriasPorId = {for (final c in categorias) c.id!: c};
    _resumo = await _lancamentos.resumoDoMes(id, hoje);
    _ultimos = await _lancamentos.ultimos(id);
    _statusOrcamentos = await _orcamentos.statusDoMes(id, hoje);
    _statusMetas = await _metas.listar(id);
    _despesasPorCategoria = await _lancamentos.despesasPorCategoria(id, hoje);
    _serieMensal = await _lancamentos.serieMensalDespesas(id);
    if (_filtroAtual != null) {
      _extrato = await _lancamentos.listar(id, _filtroAtual!);
    }
    notifyListeners();
  }

  Future<void> aplicarFiltroExtrato(FiltroExtrato filtro) async {
    final id = _usuarioId;
    if (id == null) return;
    _filtroAtual = filtro;
    _extrato = await _lancamentos.listar(id, filtro);
    notifyListeners();
  }

  /// Salva um lançamento (novo ou edição) e devolve, quando for o caso, o
  /// alerta de orçamento gerado (RF10): aviso ao cruzar 80% do teto e ao
  /// ultrapassá-lo.
  Future<String?> salvarLancamento(Lancamento lancamento) async {
    final antes = _percentualDaCategoria(lancamento.categoriaId);
    if (lancamento.id == null) {
      await _lancamentos.inserir(lancamento);
    } else {
      await _lancamentos.atualizar(lancamento);
    }
    await recarregar();
    if (lancamento.tipo != TipoLancamento.despesa) return null;
    final depois = _percentualDaCategoria(lancamento.categoriaId);
    final nome = _categoriasPorId[lancamento.categoriaId]?.nome ?? 'categoria';
    if (antes < 1.0 && depois >= 1.0) {
      final status = _statusDaCategoria(lancamento.categoriaId);
      final excesso =
          status == null ? 0 : status.gasto - status.orcamento.valorTeto;
      return 'Orçamento de $nome estourado'
          '${excesso > 0 ? ' em ${Formatters.money(excesso)}' : ''}!';
    }
    if (antes < 0.8 && depois >= 0.8) {
      return 'Atenção: $nome atingiu ${(depois * 100).round()}% do orçamento.';
    }
    return null;
  }

  Future<void> excluirLancamento(int id) async {
    await _lancamentos.excluir(id);
    await recarregar();
  }

  double _percentualDaCategoria(int categoriaId) =>
      _statusDaCategoria(categoriaId)?.percentual ?? 0;

  OrcamentoStatus? _statusDaCategoria(int categoriaId) {
    for (final s in _statusOrcamentos) {
      if (s.orcamento.categoriaId == categoriaId) return s;
    }
    return null;
  }

  Future<void> definirOrcamento(int categoriaId, int valorTeto) async {
    final id = _usuarioId;
    if (id == null) return;
    await _orcamentos.definir(Orcamento(
        usuarioId: id, categoriaId: categoriaId, valorTeto: valorTeto));
    await recarregar();
  }

  Future<void> removerOrcamento(int orcamentoId) async {
    await _orcamentos.remover(orcamentoId);
    await recarregar();
  }

  Future<void> criarMeta(
      {required String nome, required int valorAlvo, required DateTime prazo}) async {
    final id = _usuarioId;
    if (id == null) return;
    await _metas.criar(
        Meta(usuarioId: id, nome: nome, valorAlvo: valorAlvo, prazo: prazo));
    await recarregar();
  }

  Future<void> excluirMeta(int metaId) async {
    await _metas.excluir(metaId);
    await recarregar();
  }

  /// RN07: o aporte vira despesa na categoria "Poupança".
  Future<void> registrarAporte(Meta meta, int valor) async {
    var poupanca = await _categorias.buscarPorNome('Poupança');
    poupanca ??= await _categorias.criar(const Categoria(
        nome: 'Poupança', icone: 7, cor: 0xFF08483F, padrao: true));
    await _metas.registrarAporte(
        meta: meta, valor: valor, categoriaPoupancaId: poupanca.id!);
    await recarregar();
  }

  Future<String> exportarCsv(FiltroExtrato filtro) async {
    final id = _usuarioId;
    if (id == null) return '';
    final nomes = {
      for (final e in _categoriasPorId.entries) e.key: e.value.nome,
    };
    return _lancamentos.exportarCsv(id, filtro, nomes);
  }

  void limpar() {
    _usuarioId = null;
    _resumo = const ResumoMensal(totalReceitas: 0, totalDespesas: 0);
    _ultimos = [];
    _extrato = [];
    _statusOrcamentos = [];
    _statusMetas = [];
    _despesasPorCategoria = {};
    _serieMensal = [];
    _filtroAtual = null;
    notifyListeners();
  }
}
