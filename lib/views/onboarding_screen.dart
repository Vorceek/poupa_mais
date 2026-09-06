import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../viewmodels/categoria_viewmodel.dart';
import '../viewmodels/sessao_viewmodel.dart';
import 'home_shell.dart';

/// Tela 2 do protótipo (RF02/RF06): assistente de primeiro acesso que capta
/// a renda mensal e as categorias que o usuário quer acompanhar. Pode ser
/// pulado, preservando a autonomia de quem quer usar o app imediatamente.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _rendaCtrl = TextEditingController();
  final Set<int> _desativadas = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriaViewModel>().carregar();
    });
  }

  @override
  void dispose() {
    _rendaCtrl.dispose();
    super.dispose();
  }

  Future<void> _concluir({bool pular = false}) async {
    final sessao = context.read<SessaoViewModel>();
    final categorias = context.read<CategoriaViewModel>();
    if (!pular) {
      // Desativa as categorias de despesa que o usuário não quer acompanhar.
      for (final c in categorias.todas) {
        if (_desativadas.contains(c.id)) {
          await categorias.atualizar(c.copyWith(ativa: false));
        }
      }
    }
    final renda = pular ? 0 : (Formatters.parseMoney(_rendaCtrl.text) ?? 0);
    await sessao.concluirOnboarding(rendaMensal: renda);
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) {
    final categorias = context.watch<CategoriaViewModel>();
    // No onboarding só faz sentido escolher categorias de gasto do dia a dia.
    final selecionaveis = categorias.todas
        .where((c) => c.nome != 'Salário' && c.nome != 'Poupança')
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vamos começar'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Qual sua renda mensal?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'Usamos isso só para sugerir seus orçamentos. Você pode mudar depois.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rendaCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                MoneyInputFormatter(),
              ],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                prefixText: 'R\$ ',
                hintText: '0,00',
              ),
            ),
            const SizedBox(height: 32),
            const Text('O que você quer acompanhar?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in selecionaveis)
                  FilterChip(
                    label: Text(c.nome),
                    avatar: Icon(c.iconData, size: 18),
                    selected: !_desativadas.contains(c.id),
                    selectedColor: AppColors.surface,
                    checkmarkColor: AppColors.primary,
                    onSelected: (selecionada) => setState(() {
                      if (selecionada) {
                        _desativadas.remove(c.id);
                      } else {
                        _desativadas.add(c.id!);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Você pode criar categorias próprias depois, em Perfil > Categorias.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => _concluir(),
              child: const Text('Continuar'),
            ),
            TextButton(
              onPressed: () => _concluir(pular: true),
              child: const Text('Pular esta etapa'),
            ),
          ],
        ),
      ),
    );
  }
}
