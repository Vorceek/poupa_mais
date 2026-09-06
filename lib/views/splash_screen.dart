import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../viewmodels/sessao_viewmodel.dart';
import 'home_shell.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

/// Tela de abertura: restaura a sessão salva e direciona para o destino
/// certo (login, onboarding ou painel).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    final sessao = context.read<SessaoViewModel>();
    final logado = await sessao.restaurarSessao();
    if (!mounted) return;
    final Widget destino;
    if (!logado) {
      destino = const LoginScreen();
    } else if (!sessao.onboardingConcluido) {
      destino = const OnboardingScreen();
    } else {
      destino = const HomeShell();
    }
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => destino));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: const Text(
                'P+',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Poupa+',
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'Seu dinheiro, sob controle',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
