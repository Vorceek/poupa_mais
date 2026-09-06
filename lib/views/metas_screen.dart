import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/meta.dart';
import '../viewmodels/financas_viewmodel.dart';

/// Tela 7 do protótipo (RF11, RN06, RN07, US05): metas com barra de
/// progresso e o valor mensal necessário para cumprir o prazo já calculado.
/// Metas concluídas continuam visíveis, somente leitura, como reforço
/// positivo.
class MetasScreen extends StatelessWidget {
  const MetasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final financas = context.watch<FinancasViewModel>();
    final metas = financas.statusMetas;
    final ativas = metas.where((m) => !m.meta.concluida).length;
    final concluidas = metas.length - ativas;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Minhas metas',
                style: TextStyle(fontWeight: FontWeight.w700)),
            Text(
              '$ativas ativa${ativas == 1 ? '' : 's'}, '
              '$concluidas concluída${concluidas == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          if (metas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'Nenhuma meta ainda.\nCrie um objetivo de poupança e acompanhe o progresso.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          for (final status in metas) ...[
            _MetaCard(status: status),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () => _criarMeta(context),
            icon: const Icon(Icons.add),
            label: const Text('Criar nova meta'),
          ),
        ],
      ),
    );
  }

  Future<void> _criarMeta(BuildContext context) async {
    final financas = context.read<FinancasViewModel>();
    final nomeCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    DateTime prazo = DateTime.now().add(const Duration(days: 180));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Nova meta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Nome (ex.: Reserva de emergência)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valorCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  MoneyInputFormatter(),
                ],
                decoration: const InputDecoration(
                    labelText: 'Valor-alvo', prefixText: 'R\$ '),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text('Prazo: ${Formatters.date(prazo)}'),
                onPressed: () async {
                  final escolhida = await showDatePicker(
                    context: dialogContext,
                    initialDate: prazo,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365 * 10)),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (escolhida != null) setState(() => prazo = escolhida);
                },
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
                if (nomeCtrl.text.trim().isEmpty ||
                    valor == null ||
                    valor <= 0) {
                  return;
                }
                financas.criarMeta(
                    nome: nomeCtrl.text.trim(), valorAlvo: valor, prazo: prazo);
                Navigator.pop(dialogContext);
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final MetaStatus status;
  const _MetaCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final meta = status.meta;
    final concluida = meta.concluida || status.atingida;
    final prazoFmt = DateFormat('MMM/yyyy', 'pt_BR').format(meta.prazo);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _excluir(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      concluida ? '${meta.nome} ✓' : meta.nome,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color:
                            concluida ? AppColors.income : AppColors.text,
                      ),
                    ),
                  ),
                  Text(
                    '${(status.progresso * 100).round()}%',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: concluida
                            ? AppColors.income
                            : AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${Formatters.money(status.valorAtual)} de ${Formatters.money(meta.valorAlvo)}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: status.progresso,
                  minHeight: 8,
                  backgroundColor: AppColors.surface,
                  color: concluida ? AppColors.income : AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (!concluida) ...[
                Text(
                  'Prazo $prazoFmt, guarde '
                  '${Formatters.money(status.aporteMensalNecessario())}/mês',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _adicionarAporte(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Adicionar aporte'),
                ),
              ] else
                const Text('Meta concluída, parabéns!',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.income,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _adicionarAporte(BuildContext context) async {
    final financas = context.read<FinancasViewModel>();
    final valorCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Aporte em "${status.meta.nome}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valorCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                MoneyInputFormatter(),
              ],
              decoration: const InputDecoration(
                  labelText: 'Valor do aporte', prefixText: 'R\$ '),
            ),
            const SizedBox(height: 8),
            const Text(
              // RN07 explicada ao usuário, sem jargão.
              'O aporte entra como despesa na categoria Poupança, para o saldo do mês continuar real.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
              if (valor == null || valor <= 0) return;
              financas.registrarAporte(status.meta, valor);
              Navigator.pop(dialogContext);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _excluir(BuildContext context) async {
    final financas = context.read<FinancasViewModel>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Excluir a meta "${status.meta.nome}"?'),
        content: const Text(
            'Os aportes já lançados como despesa de Poupança não são removidos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.expense),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmado == true) {
      await financas.excluirMeta(status.meta.id!);
    }
  }
}
