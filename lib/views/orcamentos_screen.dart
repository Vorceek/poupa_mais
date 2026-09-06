import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/orcamento.dart';
import '../viewmodels/financas_viewmodel.dart';

/// Tela 6 do protótipo (RF09, RF10, US03): teto por categoria com semáforo —
/// verde até 79%, âmbar de 80% a 99%, vermelho ao atingir o teto. O aviso
/// aparece antes do estouro, e os valores absolutos acompanham a barra para
/// a informação não depender só da cor (RNF08).
class OrcamentosScreen extends StatelessWidget {
  const OrcamentosScreen({super.key});

  static Color _corDaFaixa(FaixaOrcamento faixa) => switch (faixa) {
        FaixaOrcamento.ok => AppColors.primary,
        FaixaOrcamento.alerta => AppColors.warning,
        FaixaOrcamento.estourado => AppColors.expense,
      };

  Future<void> _definirOrcamento(BuildContext context,
      {int? categoriaInicial}) async {
    final financas = context.read<FinancasViewModel>();
    final valorCtrl = TextEditingController();
    final comOrcamento = financas.statusOrcamentos
        .map((s) => s.orcamento.categoriaId)
        .toSet();
    final categorias = financas.categoriasPorId.values
        .where((c) =>
            c.ativa && (comOrcamento.contains(c.id) || c.nome != 'Salário'))
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    int? categoriaId = categoriaInicial ??
        categorias
            .where((c) => !comOrcamento.contains(c.id))
            .firstOrNull
            ?.id;
    if (categoriaInicial != null) {
      final atual = financas.statusOrcamentos
          .where((s) => s.orcamento.categoriaId == categoriaInicial)
          .firstOrNull;
      if (atual != null) {
        valorCtrl.text = Formatters.moneyPlain(atual.orcamento.valorTeto);
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Definir orçamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: categoriaId,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [
                  for (final c in categorias)
                    DropdownMenuItem(value: c.id, child: Text(c.nome)),
                ],
                onChanged: (v) => setState(() => categoriaId = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valorCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  MoneyInputFormatter(),
                ],
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Teto mensal', prefixText: 'R\$ '),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final valor = Formatters.parseMoney(valorCtrl.text);
                if (categoriaId == null || valor == null || valor <= 0) return;
                financas.definirOrcamento(categoriaId!, valor);
                Navigator.pop(dialogContext);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final financas = context.watch<FinancasViewModel>();
    final status = financas.statusOrcamentos;
    final emAlerta =
        status.where((s) => s.faixa != FaixaOrcamento.ok).toList();
    final totalGasto = status.fold<int>(0, (soma, s) => soma + s.gasto);
    final totalTeto =
        status.fold<int>(0, (soma, s) => soma + s.orcamento.valorTeto);
    final proximoReinicio = DateTime(DateTime.now().year,
        DateTime.now().month + 1, 1);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Orçamentos',
                style: TextStyle(fontWeight: FontWeight.w700)),
            if (status.isNotEmpty)
              Text(
                '${Formatters.money(totalGasto)} de ${Formatters.money(totalTeto)}',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          // US03: o aviso aparece antes do estouro acontecer, não depois.
          if (emAlerta.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Atenção em ${emAlerta.length} '
                      '${emAlerta.length == 1 ? 'categoria' : 'categorias'}: '
                      '${emAlerta.map((s) => financas.categoria(s.orcamento.categoriaId)?.nome ?? '').join(', ')}.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (status.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'Nenhum orçamento definido.\nCrie um teto mensal por categoria para acompanhar seus gastos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          for (final s in status) ...[
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _definirOrcamento(context,
                    categoriaInicial: s.orcamento.categoriaId),
                onLongPress: () => _removerOrcamento(context, s),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                              financas
                                      .categoria(s.orcamento.categoriaId)
                                      ?.iconData ??
                                  Icons.category_outlined,
                              size: 20,
                              color: _corDaFaixa(s.faixa)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              financas
                                      .categoria(s.orcamento.categoriaId)
                                      ?.nome ??
                                  'Categoria',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${Formatters.moneyPlain(s.gasto)} / ${Formatters.moneyPlain(s.orcamento.valorTeto)}',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _corDaFaixa(s.faixa)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: s.percentual.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: AppColors.surface,
                          color: _corDaFaixa(s.faixa),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(s.percentual * 100).round()}% usado'
                        '${s.faixa == FaixaOrcamento.estourado ? ' · teto atingido' : ''}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () => _definirOrcamento(context),
            icon: const Icon(Icons.add),
            label: const Text('Definir novo orçamento'),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              // RN05: o consumo reinicia automaticamente todo mês.
              'Reinicia dia ${Formatters.date(proximoReinicio)}',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removerOrcamento(
      BuildContext context, OrcamentoStatus s) async {
    final financas = context.read<FinancasViewModel>();
    final nome = financas.categoria(s.orcamento.categoriaId)?.nome ?? '';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remover orçamento de $nome?'),
        content: const Text('Os lançamentos não são afetados.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.expense),
              child: const Text('Remover')),
        ],
      ),
    );
    if (confirmado == true) {
      await financas.removerOrcamento(s.orcamento.id!);
    }
  }
}
