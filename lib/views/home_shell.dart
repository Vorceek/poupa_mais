import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/cotacao_viewmodel.dart';
import '../viewmodels/financas_viewmodel.dart';
import '../viewmodels/sessao_viewmodel.dart';
import 'dashboard_screen.dart';
import 'extrato_screen.dart';
import 'metas_screen.dart';
import 'nova_transacao_sheet.dart';
import 'orcamentos_screen.dart';
import 'perfil_screen.dart';

/// Estrutura de navegação (seção 4.2): abas inferiores com profundidade
/// máxima de dois níveis e botão flutuante de lançamento visível em todas as
/// abas, garantindo o fluxo de 3 toques do RNF02.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _abaAtual = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final usuario = context.read<SessaoViewModel>().usuario;
      if (usuario != null) {
        context.read<FinancasViewModel>().iniciar(usuario.id!);
      }
      context.read<CotacaoViewModel>().carregar();
    });
  }

  Future<void> _novaTransacao() async {
    final alerta = await NovaTransacaoSheet.abrir(context);
    if (!mounted || alerta == null) return;
    // RF10: alerta visual imediato ao cruzar 80% ou estourar o orçamento.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(alerta),
      backgroundColor: const Color(0xFFE08B00),
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _abaAtual,
        children: const [
          DashboardScreen(),
          ExtratoScreen(),
          OrcamentosScreen(),
          MetasScreen(),
          PerfilScreen(),
        ],
      ),
      floatingActionButton: _abaAtual == 4
          ? null
          : FloatingActionButton(
              onPressed: _novaTransacao,
              tooltip: 'Novo lançamento',
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,
        onDestinationSelected: (i) => setState(() => _abaAtual = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Início'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Extrato'),
          NavigationDestination(
              icon: Icon(Icons.donut_small_outlined),
              selectedIcon: Icon(Icons.donut_small),
              label: 'Orçamentos'),
          NavigationDestination(
              icon: Icon(Icons.flag_outlined),
              selectedIcon: Icon(Icons.flag),
              label: 'Metas'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }
}
