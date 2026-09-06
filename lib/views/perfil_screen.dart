import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../viewmodels/financas_viewmodel.dart';
import '../viewmodels/sessao_viewmodel.dart';
import 'categorias_screen.dart';
import 'login_screen.dart';

/// Tela 9 do protótipo (RNF05, RNF12): perfil e configurações. A exclusão
/// total da conta e dos dados fica na própria tela, cumprindo o direito de
/// eliminação previsto na LGPD; a ação destrutiva é sinalizada em vermelho e
/// isolada do restante da lista.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<SessaoViewModel>();
    final usuario = sessao.usuario;
    if (usuario == null) return const SizedBox.shrink();
    final inicial =
        usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: Text(inicial,
                      style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Text(usuario.nome,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                Text(
                  usuario.modoLocal
                      ? 'Modo local (sem conta)'
                      : usuario.email ?? '',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _TituloSecao('PREFERÊNCIAS'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Nome'),
                  subtitle: Text(usuario.nome),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editarNome(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Renda mensal'),
                  subtitle: Text(Formatters.money(usuario.rendaMensal)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editarRenda(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Categorias'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CategoriasScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _TituloSecao('CONTA'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sair'),
                  onTap: () => _sair(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.delete_forever, color: AppColors.expense),
                  title: const Text('Excluir conta e dados',
                      style: TextStyle(
                          color: AppColors.expense,
                          fontWeight: FontWeight.w600)),
                  subtitle: const Text('Remove tudo deste aparelho (LGPD)'),
                  onTap: () => _excluirConta(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text('Poupa+ · Versão 1.0.0',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Projeto acadêmico — Desenvolvimento de Aplicações Mobile',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editarNome(BuildContext context) async {
    final sessao = context.read<SessaoViewModel>();
    final ctrl = TextEditingController(text: sessao.usuario?.nome ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Seu nome'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().length >= 2) {
                sessao.atualizarPerfil(nome: ctrl.text.trim());
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editarRenda(BuildContext context) async {
    final sessao = context.read<SessaoViewModel>();
    final ctrl = TextEditingController(
        text: sessao.usuario == null
            ? ''
            : Formatters.moneyPlain(sessao.usuario!.rendaMensal));
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Renda mensal'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            MoneyInputFormatter(),
          ],
          decoration: const InputDecoration(prefixText: 'R\$ '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final valor = Formatters.parseMoney(ctrl.text);
              if (valor != null) {
                sessao.atualizarPerfil(rendaMensal: valor);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _sair(BuildContext context) async {
    final sessao = context.read<SessaoViewModel>();
    final financas = context.read<FinancasViewModel>();
    await sessao.sair();
    financas.limpar();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Future<void> _excluirConta(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conta e dados?'),
        content: const Text(
            'Todos os lançamentos, orçamentos e metas serão apagados '
            'definitivamente deste aparelho. Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Excluir tudo'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    final sessao = context.read<SessaoViewModel>();
    final financas = context.read<FinancasViewModel>();
    await sessao.excluirConta();
    financas.limpar();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }
}

class _TituloSecao extends StatelessWidget {
  final String titulo;
  const _TituloSecao(this.titulo);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(titulo,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.5)),
    );
  }
}
