import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../data/lancamento_repository.dart';
import '../models/lancamento.dart';
import '../viewmodels/financas_viewmodel.dart';
import '../widgets/lancamento_tile.dart';
import 'nova_transacao_sheet.dart';

/// Tela 5 do protótipo (RF05, RF08): lançamentos agrupados por data, com
/// filtros por período (mês), categoria e tipo, e busca textual. Deslizar um
/// item exclui (com confirmação); tocar edita.
class ExtratoScreen extends StatefulWidget {
  const ExtratoScreen({super.key});

  @override
  State<ExtratoScreen> createState() => _ExtratoScreenState();
}

class _ExtratoScreenState extends State<ExtratoScreen> {
  final _buscaCtrl = TextEditingController();
  DateTime _mes = DateTime.now();
  TipoLancamento? _tipo;
  int? _categoriaId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _aplicarFiltro());
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  void _aplicarFiltro() {
    context.read<FinancasViewModel>().aplicarFiltroExtrato(FiltroExtrato(
          inicio: DateTime(_mes.year, _mes.month, 1),
          fim: DateTime(_mes.year, _mes.month + 1, 0),
          tipo: _tipo,
          categoriaId: _categoriaId,
          busca: _buscaCtrl.text,
        ));
  }

  void _mudarMes(int delta) {
    setState(() => _mes = DateTime(_mes.year, _mes.month + delta, 1));
    _aplicarFiltro();
  }

  Future<void> _editar(Lancamento lancamento) async {
    final alerta = await NovaTransacaoSheet.abrir(context, editar: lancamento);
    if (!mounted || alerta == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(alerta), backgroundColor: AppColors.warning));
  }

  /// RF05: confirmação antes da exclusão definitiva.
  Future<bool> _confirmarExclusao(Lancamento lancamento) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: Text(
            'O lançamento de ${Formatters.money(lancamento.valor)} será removido definitivamente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }

  Future<void> _exportarCsv() async {
    final financas = context.read<FinancasViewModel>();
    final csv = await financas.exportarCsv(FiltroExtrato(
      inicio: DateTime(_mes.year, _mes.month, 1),
      fim: DateTime(_mes.year, _mes.month + 1, 0),
    ));
    if (!mounted) return;
    // RF14 (desejável): exporta o período em CSV. Copiamos para a área de
    // transferência para o usuário colar em qualquer app (planilha, e-mail).
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('CSV do mês copiado para a área de transferência.')));
  }

  @override
  Widget build(BuildContext context) {
    final financas = context.watch<FinancasViewModel>();
    final categorias = financas.categoriasPorId.values.toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    final grupos = _agruparPorData(financas.extrato);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extrato'),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV do mês',
            icon: const Icon(Icons.ios_share),
            onPressed: _exportarCsv,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                        tooltip: 'Mês anterior',
                        onPressed: () => _mudarMes(-1),
                        icon: const Icon(Icons.chevron_left)),
                    Expanded(
                      child: Text(Formatters.monthYear(_mes),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    IconButton(
                        tooltip: 'Próximo mês',
                        onPressed: () => _mudarMes(1),
                        icon: const Icon(Icons.chevron_right)),
                  ],
                ),
                TextField(
                  controller: _buscaCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Buscar lançamento',
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (_) => _aplicarFiltro(),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _tipo == null,
                        onSelected: (_) {
                          setState(() => _tipo = null);
                          _aplicarFiltro();
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Despesas'),
                        selected: _tipo == TipoLancamento.despesa,
                        onSelected: (_) {
                          setState(() => _tipo = TipoLancamento.despesa);
                          _aplicarFiltro();
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Receitas'),
                        selected: _tipo == TipoLancamento.receita,
                        onSelected: (_) {
                          setState(() => _tipo = TipoLancamento.receita);
                          _aplicarFiltro();
                        },
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int?>(
                        value: _categoriaId,
                        hint: const Text('Categoria'),
                        underline: const SizedBox.shrink(),
                        items: [
                          const DropdownMenuItem<int?>(
                              value: null, child: Text('Todas as categorias')),
                          for (final c in categorias)
                            DropdownMenuItem<int?>(
                                value: c.id, child: Text(c.nome)),
                        ],
                        onChanged: (v) {
                          setState(() => _categoriaId = v);
                          _aplicarFiltro();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: grupos.isEmpty
                ? const Center(
                    child: Text('Nenhum lançamento neste período.',
                        style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: grupos.length,
                    itemBuilder: (context, i) {
                      final grupo = grupos[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 4),
                            child: Text(
                              _tituloDoDia(grupo.data),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.5),
                            ),
                          ),
                          for (final l in grupo.lancamentos)
                            Dismissible(
                              key: ValueKey('lancamento-${l.id}'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => _confirmarExclusao(l),
                              onDismissed: (_) => context
                                  .read<FinancasViewModel>()
                                  .excluirLancamento(l.id!),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                    color: AppColors.expense,
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.delete_outline,
                                    color: Colors.white),
                              ),
                              child: LancamentoTile(
                                lancamento: l,
                                categoria: financas.categoria(l.categoriaId),
                                onTap: () => _editar(l),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static String _tituloDoDia(DateTime data) {
    final hoje = DateTime.now();
    final ontem = hoje.subtract(const Duration(days: 1));
    bool mesmoDia(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    if (mesmoDia(data, hoje)) return 'HOJE, ${Formatters.date(data)}';
    if (mesmoDia(data, ontem)) return 'ONTEM, ${Formatters.date(data)}';
    return Formatters.date(data).toUpperCase();
  }

  static List<({DateTime data, List<Lancamento> lancamentos})> _agruparPorData(
      List<Lancamento> lancamentos) {
    final grupos = <({DateTime data, List<Lancamento> lancamentos})>[];
    for (final l in lancamentos) {
      if (grupos.isNotEmpty &&
          grupos.last.data.year == l.data.year &&
          grupos.last.data.month == l.data.month &&
          grupos.last.data.day == l.data.day) {
        grupos.last.lancamentos.add(l);
      } else {
        grupos.add((data: l.data, lancamentos: [l]));
      }
    }
    return grupos;
  }
}
