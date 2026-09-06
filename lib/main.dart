import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'viewmodels/categoria_viewmodel.dart';
import 'viewmodels/cotacao_viewmodel.dart';
import 'viewmodels/financas_viewmodel.dart';
import 'viewmodels/sessao_viewmodel.dart';
import 'views/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Dados de localização pt_BR para datas e moeda (RNF12).
  await initializeDateFormatting('pt_BR');
  runApp(const PoupaMaisApp());
}

class PoupaMaisApp extends StatelessWidget {
  const PoupaMaisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessaoViewModel()),
        ChangeNotifierProvider(create: (_) => FinancasViewModel()),
        ChangeNotifierProvider(create: (_) => CategoriaViewModel()),
        ChangeNotifierProvider(create: (_) => CotacaoViewModel()),
      ],
      child: MaterialApp(
        title: 'Poupa+',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
