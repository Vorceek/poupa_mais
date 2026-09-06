import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/categoria.dart';
import '../viewmodels/categoria_viewmodel.dart';
import '../viewmodels/financas_viewmodel.dart';

/// RF06: criar, renomear, escolher ícone e cor, e desativar categorias.
/// RN04: categorias com lançamentos não são excluídas, apenas desativadas.
class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  static const _cores = [
    0xFF0D6E62, 0xFF08483F, 0xFF1F7A3F, 0xFF2E7DA6, 0xFF6A4FA3,
    0xFFB3261E, 0xFFE08B00, 0xFF5B6663, 0xFFAD1457, 0xFF4E342E,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaViewModel>().carregar();
    });
  }

  Future<void> _editarCategoria(BuildContext context,
      {Categoria? existente}) async {
    final vm = context.read<CategoriaViewModel>();
    final financas = context.read<FinancasViewModel>();
    final nomeCtrl = TextEditingController(text: existente?.nome ?? '');
    var icone = existente?.icone ?? 9;
    var cor = existente?.cor ?? _cores.first;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(existente == null ? 'Nova categoria' : 'Editar categoria'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeCtrl,
                  autofocus: existente == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 16),
                const Text('Ícone',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final entry in Categoria.catalogoIcones.entries)
                      IconButton(
                        icon: Icon(entry.value),
                        isSelected: icone == entry.key,
                        selectedIcon: Icon(entry.value, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: icone == entry.key
                              ? Color(cor)
                              : AppColors.surface,
                        ),
                        onPressed: () => setState(() => icone = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Cor',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in _cores)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => cor = c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: cor == c
                                ? Border.all(
                                    color: AppColors.text, width: 3)
                                : null,
                          ),
                          child: cor == c
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final nome = nomeCtrl.text.trim();
                if (nome.isEmpty) return;
                if (existente == null) {
                  await vm.criar(nome, icone, cor);
                } else {
                  await vm.atualizar(
                      existente.copyWith(nome: nome, icone: icone, cor: cor));
                }
                await financas.recarregar();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _remover(Categoria categoria) async {
    final vm = context.read<CategoriaViewModel>();
    final financas = context.read<FinancasViewModel>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remover "${categoria.nome}"?'),
        content: const Text(
            'Se a categoria tiver lançamentos, ela será apenas desativada, '
            'preservando o histórico.'),
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
    if (confirmado != true || !mounted) return;
    final excluida = await vm.excluirOuDesativar(categoria);
    await financas.recarregar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(excluida
          ? 'Categoria excluída.'
          : 'Categoria desativada (havia lançamentos vinculados).'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoriaViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editarCategoria(context),
        tooltip: 'Nova categoria',
        child: const Icon(Icons.add),
      ),
      body: vm.carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                for (final c in vm.todas)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: c.color.withValues(alpha: 0.15),
                        child: Icon(c.iconData, color: c.color, size: 20),
                      ),
                      title: Text(c.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: c.ativa
                                ? AppColors.text
                                : AppColors.textMuted,
                            decoration: c.ativa
                                ? null
                                : TextDecoration.lineThrough,
                          )),
                      subtitle: Text(
                        [
                          if (c.padrao) 'padrão',
                          if (!c.ativa) 'desativada',
                        ].join(' · '),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!c.ativa)
                            IconButton(
                              tooltip: 'Reativar',
                              icon: const Icon(Icons.refresh),
                              onPressed: () async {
                                await vm.reativar(c);
                                if (context.mounted) {
                                  await context
                                      .read<FinancasViewModel>()
                                      .recarregar();
                                }
                              },
                            ),
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _editarCategoria(context, existente: c),
                          ),
                          IconButton(
                            tooltip: 'Remover',
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.expense),
                            onPressed: () => _remover(c),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
