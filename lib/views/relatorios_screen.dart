import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../viewmodels/financas_viewmodel.dart';

/// Tela 8 do protótipo (RF12, US04): gráfico de rosca com o total no centro
/// e legenda ordenada por valor decrescente — indica onde cortar primeiro —
/// e gráfico de barras com a evolução dos últimos seis meses.
class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final financas = context.watch<FinancasViewModel>();
    final despesas = financas.despesasPorCategoria;
    final total = despesas.values.fold<int>(0, (a, b) => a + b);
    final entradas = despesas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Relatórios',
                style: TextStyle(fontWeight: FontWeight.w700)),
            Text(Formatters.monthYear(DateTime.now()),
                style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('DESPESAS POR CATEGORIA',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text('Sem despesas neste mês.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 60,
                              sections: [
                                for (final e in entradas)
                                  PieChartSectionData(
                                    value: e.value.toDouble(),
                                    color: financas.categoria(e.key)?.color ??
                                        AppColors.textMuted,
                                    radius: 34,
                                    showTitle: false,
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(Formatters.money(total),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18)),
                              const Text('no mês',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final e in entradas)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: financas.categoria(e.key)?.color ??
                                    AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  financas.categoria(e.key)?.nome ?? 'Outros',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                            Text(Formatters.money(e.value),
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 13)),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 44,
                              child: Text(
                                '${(e.value / total * 100).round()}%',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('EVOLUÇÃO DOS GASTOS',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: SizedBox(
                height: 180,
                child: _GraficoBarras(serie: financas.serieMensal),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GraficoBarras extends StatelessWidget {
  final List<({DateTime mes, int total})> serie;
  const _GraficoBarras({required this.serie});

  @override
  Widget build(BuildContext context) {
    if (serie.every((p) => p.total == 0)) {
      return const Center(
        child: Text('Sem dados suficientes ainda.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    final maiorValor =
        serie.map((p) => p.total).reduce((a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maiorValor * 1.2 / 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
              Formatters.money((rod.toY * 100).round()),
              const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= serie.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('MMM', 'pt_BR').format(serie[i].mes),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < serie.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: serie[i].total / 100,
                  width: 22,
                  color: i == serie.length - 1
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.45),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
