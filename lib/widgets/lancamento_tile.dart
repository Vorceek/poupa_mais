import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/categoria.dart';
import '../models/lancamento.dart';

/// Item de lançamento usado no painel e no extrato. A distinção visual entre
/// receita e despesa (RF04) usa cor + sinal, nunca só a cor (RNF08).
class LancamentoTile extends StatelessWidget {
  final Lancamento lancamento;
  final Categoria? categoria;
  final String? subtitulo;
  final VoidCallback? onTap;

  const LancamentoTile({
    super.key,
    required this.lancamento,
    required this.categoria,
    this.subtitulo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final receita = lancamento.tipo == TipoLancamento.receita;
    final cor = receita ? AppColors.income : AppColors.expense;
    final sinal = receita ? '+' : '-';
    final titulo = lancamento.descricao.isNotEmpty
        ? lancamento.descricao
        : (categoria?.nome ?? 'Lançamento');
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor:
            (categoria?.color ?? AppColors.primary).withValues(alpha: 0.15),
        child: Icon(categoria?.iconData ?? Icons.category_outlined,
            color: categoria?.color ?? AppColors.primary, size: 20),
      ),
      title: Text(titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitulo ??
            '${categoria?.nome ?? ''}'
                '${lancamento.recorrencia != Recorrencia.nenhuma ? ' · recorrente' : ''}',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
      trailing: Text(
        '$sinal${Formatters.moneyPlain(lancamento.valor)}',
        style:
            TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
  }
}
