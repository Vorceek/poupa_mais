import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poupa_mais/models/categoria.dart';
import 'package:poupa_mais/models/lancamento.dart';
import 'package:poupa_mais/widgets/lancamento_tile.dart';

void main() {
  const categoria =
      Categoria(id: 1, nome: 'Alimentação', icone: 1, cor: 0xFF0D6E62);

  Widget montar(Lancamento lancamento) => MaterialApp(
        home: Scaffold(
          body: LancamentoTile(lancamento: lancamento, categoria: categoria),
        ),
      );

  testWidgets('despesa aparece com sinal negativo (RF04)', (tester) async {
    await tester.pumpWidget(montar(Lancamento(
      usuarioId: 1,
      categoriaId: 1,
      valor: 14280,
      tipo: TipoLancamento.despesa,
      data: DateTime(2026, 8, 15),
      descricao: 'Supermercado Rede',
    )));
    expect(find.text('Supermercado Rede'), findsOneWidget);
    expect(find.text('-142,80'), findsOneWidget);
  });

  testWidgets('receita aparece com sinal positivo (RF04)', (tester) async {
    await tester.pumpWidget(montar(Lancamento(
      usuarioId: 1,
      categoriaId: 1,
      valor: 390000,
      tipo: TipoLancamento.receita,
      data: DateTime(2026, 8, 5),
      descricao: 'Salário',
    )));
    expect(find.text('+3.900,00'), findsOneWidget);
  });
}
