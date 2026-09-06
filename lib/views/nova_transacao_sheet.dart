import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/validators.dart';
import '../models/lancamento.dart';
import '../viewmodels/financas_viewmodel.dart';
import '../viewmodels/sessao_viewmodel.dart';

/// Tela 4 do protótipo (RF03, RF04, RF13, US01): formulário de lançamento em
/// 3 toques (valor com foco automático, categoria e salvar). A data vem
/// preenchida com o dia corrente e a categoria sugere a última utilizada.
class NovaTransacaoSheet extends StatefulWidget {
  final Lancamento? editar;

  const NovaTransacaoSheet({super.key, this.editar});

  /// Abre o formulário como modal. Retorna a mensagem de alerta de orçamento
  /// (RF10) quando o lançamento salvo cruzar 80% ou estourar o teto.
  static Future<String?> abrir(BuildContext context, {Lancamento? editar}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: NovaTransacaoSheet(editar: editar),
      ),
    );
  }

  @override
  State<NovaTransacaoSheet> createState() => _NovaTransacaoSheetState();
}

class _NovaTransacaoSheetState extends State<NovaTransacaoSheet> {
  final _valorCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _valorFocus = FocusNode();

  TipoLancamento _tipo = TipoLancamento.despesa;
  int? _categoriaId;
  DateTime _data = DateTime.now();
  Recorrencia _recorrencia = Recorrencia.nenhuma;
  String? _erroValor;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final editar = widget.editar;
    if (editar != null) {
      _tipo = editar.tipo;
      _categoriaId = editar.categoriaId;
      _data = editar.data;
      _recorrencia = editar.recorrencia;
      _valorCtrl.text = Formatters.moneyPlain(editar.valor);
      _descricaoCtrl.text = editar.descricao;
    } else {
      // Sugere a última categoria usada (RF03).
      _categoriaId = context.read<FinancasViewModel>().ultimaCategoriaDespesa;
    }
    // Foco automático no valor: o campo mais importante (US01).
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _valorFocus.requestFocus());
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _descricaoCtrl.dispose();
    _valorFocus.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final sessao = context.read<SessaoViewModel>();
    final criadoEm = sessao.usuario?.criadoEm ?? DateTime(2020);
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      // RN03: sem datas anteriores à criação da conta nem além de 12 meses.
      firstDate: DateTime(criadoEm.year, criadoEm.month, criadoEm.day),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  Future<void> _salvar() async {
    final sessao = context.read<SessaoViewModel>();
    final financas = context.read<FinancasViewModel>();
    final cents = Formatters.parseMoney(_valorCtrl.text);

    // RN01: valor sempre maior que zero.
    final erroValor = Validators.transactionValue(cents);
    setState(() => _erroValor = erroValor);
    if (erroValor != null) return;

    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Escolha uma categoria.'),
          backgroundColor: AppColors.expense));
      return;
    }

    final erroData = Validators.transactionDate(
        _data, sessao.usuario?.criadoEm ?? DateTime(2020));
    if (erroData != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(erroData), backgroundColor: AppColors.expense));
      return;
    }

    setState(() => _salvando = true);
    final base = widget.editar;
    final lancamento = base != null
        ? base.copyWith(
            categoriaId: _categoriaId,
            valor: cents,
            tipo: _tipo,
            data: _data,
            descricao: _descricaoCtrl.text.trim(),
            recorrencia: _recorrencia,
          )
        : Lancamento(
            usuarioId: sessao.usuario!.id!,
            categoriaId: _categoriaId!,
            valor: cents!,
            tipo: _tipo,
            data: _data,
            descricao: _descricaoCtrl.text.trim(),
            recorrencia: _recorrencia,
          );
    final alerta = await financas.salvarLancamento(lancamento);
    if (!mounted) return;
    Navigator.of(context).pop(alerta);
  }

  @override
  Widget build(BuildContext context) {
    final financas = context.watch<FinancasViewModel>();
    final categorias = financas.categoriasPorId.values
        .where((c) => c.ativa)
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    final despesa = _tipo == TipoLancamento.despesa;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.editar == null ? 'Nova transação' : 'Editar transação',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SegmentedButton<TipoLancamento>(
            segments: const [
              ButtonSegment(
                  value: TipoLancamento.despesa,
                  label: Text('Despesa'),
                  icon: Icon(Icons.arrow_downward)),
              ButtonSegment(
                  value: TipoLancamento.receita,
                  label: Text('Receita'),
                  icon: Icon(Icons.arrow_upward)),
            ],
            selected: {_tipo},
            onSelectionChanged: (sel) => setState(() => _tipo = sel.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _valorCtrl,
            focusNode: _valorFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              MoneyInputFormatter(),
            ],
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: despesa ? AppColors.expense : AppColors.income),
            decoration: InputDecoration(
              prefixText: 'R\$ ',
              hintText: '0,00',
              errorText: _erroValor,
            ),
          ),
          const SizedBox(height: 20),
          const Text('CATEGORIA',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in categorias)
                ChoiceChip(
                  label: Text(c.nome),
                  avatar: Icon(c.iconData,
                      size: 18,
                      color: _categoriaId == c.id ? Colors.white : c.color),
                  selected: _categoriaId == c.id,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                      color:
                          _categoriaId == c.id ? Colors.white : AppColors.text),
                  onSelected: (_) => setState(() => _categoriaId = c.id),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _escolherData,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    _ehHoje(_data)
                        ? '${Formatters.date(_data)} (hoje)'
                        : Formatters.date(_data),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<Recorrencia>(
                  initialValue: _recorrencia,
                  decoration: const InputDecoration(
                      labelText: 'Repetir',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                  items: const [
                    DropdownMenuItem(
                        value: Recorrencia.nenhuma, child: Text('Não repete')),
                    DropdownMenuItem(
                        value: Recorrencia.semanal, child: Text('Semanal')),
                    DropdownMenuItem(
                        value: Recorrencia.mensal, child: Text('Mensal')),
                  ],
                  onChanged: (v) =>
                      setState(() => _recorrencia = v ?? Recorrencia.nenhuma),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descricaoCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration:
                const InputDecoration(labelText: 'Descrição (opcional)'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Salvar lançamento'),
          ),
        ],
      ),
    );
  }

  static bool _ehHoje(DateTime d) {
    final hoje = DateTime.now();
    return d.year == hoje.year && d.month == hoje.month && d.day == hoje.day;
  }
}
