import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/orcamento.dart';
import '../viewmodels/cotacao_viewmodel.dart';
import '../viewmodels/financas_viewmodel.dart';
import '../viewmodels/sessao_viewmodel.dart';
import '../widgets/lancamento_tile.dart';
import 'relatorios_screen.dart';

/// Tela 3 do protótipo (RF07, US02, US03): o saldo disponível ocupa a
/// primeira dobra e a barra agregada de orçamento responde à pergunta
/// "posso gastar hoje?".
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<SessaoViewModel>();
    final financas = context.watch<FinancasViewModel>();
    final nome = sessao.usuario?.nome.split(' ').first ?? '';
    final hoje = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, $nome',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(Formatters.monthYear(hoje),
                style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Relatórios',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RelatoriosScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await financas.recarregar();
          if (context.mounted) {
            await context.read<CotacaoViewModel>().carregar();
          }
        },
        child: financas.carregando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _CardSaldo(financas: financas),
                  const SizedBox(height: 12),
                  if (financas.statusOrcamentos.isNotEmpty) ...[
                    _CardOrcamentoAgregado(financas: financas),
                    const SizedBox(height: 12),
                  ],
                  const _CardCotacoes(),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('ÚLTIMOS LANÇAMENTOS',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5)),
                  ),
                  if (financas.ultimos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Nenhum lançamento ainda.\nToque em + para registrar o primeiro gasto.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Column(
                          children: [
                            for (final l in financas.ultimos)
                              LancamentoTile(
                                lancamento: l,
                                categoria: financas.categoria(l.categoriaId),
                                subtitulo:
                                    '${financas.categoria(l.categoriaId)?.nome ?? ''}, '
                                    '${Formatters.date(l.data)}',
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }
}

class _CardSaldo extends StatelessWidget {
  final FinancasViewModel financas;
  const _CardSaldo({required this.financas});

  @override
  Widget build(BuildContext context) {
    final resumo = financas.resumo;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DISPONÍVEL PARA GASTAR',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(
            Formatters.money(resumo.saldo),
            style: const TextStyle(
                color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniTotal(
                  rotulo: 'Receitas',
                  valor: resumo.totalReceitas,
                  icone: Icons.arrow_upward),
              const SizedBox(width: 24),
              _MiniTotal(
                  rotulo: 'Despesas',
                  valor: resumo.totalDespesas,
                  icone: Icons.arrow_downward),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTotal extends StatelessWidget {
  final String rotulo;
  final int valor;
  final IconData icone;
  const _MiniTotal(
      {required this.rotulo, required this.valor, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icone, color: Colors.white70, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotulo,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(Formatters.money(valor),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardOrcamentoAgregado extends StatelessWidget {
  final FinancasViewModel financas;
  const _CardOrcamentoAgregado({required this.financas});

  @override
  Widget build(BuildContext context) {
    final pct = financas.percentualOrcamentoGeral;
    final cor = pct >= 1.0
        ? AppColors.expense
        : (pct >= 0.8 ? AppColors.warning : AppColors.primary);
    final emAlerta = financas.statusOrcamentos
        .where((s) => s.faixa != FaixaOrcamento.ok)
        .length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Orçamento do mês',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${(pct * 100).round()}% usado',
                    style: TextStyle(fontWeight: FontWeight.w700, color: cor)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.surface,
                color: cor,
              ),
            ),
            if (emAlerta > 0) ...[
              const SizedBox(height: 8),
              Text(
                '⚠ Atenção em $emAlerta ${emAlerta == 1 ? 'categoria' : 'categorias'}',
                style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card de cotações (integração com API): mostra dólar, euro e bitcoin com a
/// variação do dia; em modo offline exibe o último valor em cache.
class _CardCotacoes extends StatelessWidget {
  const _CardCotacoes();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CotacaoViewModel>();
    if (vm.falhou && vm.cotacoes.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cotações agora',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                if (vm.offline)
                  const Tooltip(
                    message: 'Sem conexão: exibindo última cotação salva',
                    child: Icon(Icons.cloud_off,
                        size: 18, color: AppColors.textMuted),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (vm.carregando && vm.cotacoes.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ))
            else
              Row(
                children: [
                  for (final c in vm.cotacoes)
                    Expanded(child: _Cotacao(codigo: c.codigo, valor: c.compra, variacao: c.variacaoPct)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Cotacao extends StatelessWidget {
  final String codigo;
  final double valor;
  final double variacao;
  const _Cotacao(
      {required this.codigo, required this.valor, required this.variacao});

  @override
  Widget build(BuildContext context) {
    final subiu = variacao >= 0;
    final formato = valor >= 1000
        ? NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$')
        : NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(codigo,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(formato.format(valor),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Text(
          '${subiu ? '▲' : '▼'} ${variacao.abs().toStringAsFixed(2).replaceAll('.', ',')}%',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: subiu ? AppColors.income : AppColors.expense),
        ),
      ],
    );
  }
}
