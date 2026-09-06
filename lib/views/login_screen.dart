import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/validators.dart';
import '../viewmodels/sessao_viewmodel.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

/// Tela 1 do protótipo (RF01): login, criação de conta e modo local sem
/// cadastro, que remove a barreira de entrada.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _cadastro = false;
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _prosseguir(Future<bool> Function() acao) async {
    final sessao = context.read<SessaoViewModel>();
    final ok = await acao();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sessao.erro ?? 'Não foi possível entrar.'),
        backgroundColor: AppColors.expense,
      ));
      return;
    }
    final destino = sessao.onboardingConcluido
        ? const HomeShell()
        : const OnboardingScreen();
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => destino));
  }

  void _enviarFormulario() {
    if (!_formKey.currentState!.validate()) return;
    final sessao = context.read<SessaoViewModel>();
    if (_cadastro) {
      _prosseguir(() => sessao.cadastrar(
          _nomeCtrl.text, _emailCtrl.text, _senhaCtrl.text));
    } else {
      _prosseguir(() => sessao.entrar(_emailCtrl.text, _senhaCtrl.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final carregando =
        context.watch<SessaoViewModel>().carregando;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('P+',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Poupa+',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const Text('Seu dinheiro, sob controle',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 32),
                  if (_cadastro) ...[
                    TextFormField(
                      controller: _nomeCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senhaCtrl,
                    obscureText: !_senhaVisivel,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      suffixIcon: IconButton(
                        tooltip:
                            _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                        icon: Icon(_senhaVisivel
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _senhaVisivel = !_senhaVisivel),
                      ),
                    ),
                    validator: Validators.password,
                    onFieldSubmitted: (_) => _enviarFormulario(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: carregando ? null : _enviarFormulario,
                    child: carregando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_cadastro ? 'Criar conta' : 'Entrar'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: carregando
                        ? null
                        : () => setState(() => _cadastro = !_cadastro),
                    child: Text(_cadastro
                        ? 'Já tenho conta'
                        : 'Criar conta grátis'),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: carregando
                        ? null
                        : () => _prosseguir(
                            context.read<SessaoViewModel>().entrarModoLocal),
                    child: const Text('Usar sem conta (modo local)'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
