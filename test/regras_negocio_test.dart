import 'package:flutter_test/flutter_test.dart';
import 'package:poupa_mais/core/validators.dart';
import 'package:poupa_mais/models/meta.dart';
import 'package:poupa_mais/models/orcamento.dart';

void main() {
  group('RN01: valor do lançamento sempre maior que zero', () {
    test('rejeita nulo, zero e valores não positivos', () {
      expect(Validators.transactionValue(null), isNotNull);
      expect(Validators.transactionValue(0), isNotNull);
      expect(Validators.transactionValue(-100), isNotNull);
    });

    test('aceita valores positivos', () {
      expect(Validators.transactionValue(1), isNull);
      expect(Validators.transactionValue(142380), isNull);
    });
  });

  group('RN03: janela de datas do lançamento', () {
    final criacaoConta = DateTime(2026, 1, 10);

    test('rejeita data anterior à criação da conta', () {
      expect(
          Validators.transactionDate(DateTime(2026, 1, 9), criacaoConta),
          isNotNull);
    });

    test('rejeita data futura além de 12 meses', () {
      final muitoLonge = DateTime.now().add(const Duration(days: 400));
      expect(Validators.transactionDate(muitoLonge, criacaoConta), isNotNull);
    });

    test('aceita datas dentro da janela', () {
      expect(Validators.transactionDate(DateTime.now(), criacaoConta), isNull);
      expect(
          Validators.transactionDate(criacaoConta, criacaoConta), isNull);
    });
  });

  group('RF09/RF10: semáforo do orçamento', () {
    OrcamentoStatus status(int teto, int gasto) => OrcamentoStatus(
          orcamento: Orcamento(usuarioId: 1, categoriaId: 1, valorTeto: teto),
          gasto: gasto,
        );

    test('verde até 79%', () {
      expect(status(90000, 71000).faixa, FaixaOrcamento.ok);
    });

    test('âmbar de 80% a 99% (alerta antes do estouro, US03)', () {
      expect(status(90000, 72000).faixa, FaixaOrcamento.alerta);
      expect(status(90000, 89999).faixa, FaixaOrcamento.alerta);
    });

    test('vermelho ao atingir ou ultrapassar o teto', () {
      expect(status(90000, 90000).faixa, FaixaOrcamento.estourado);
      expect(status(90000, 120000).faixa, FaixaOrcamento.estourado);
    });
  });

  group('RF11/RN06: metas de economia', () {
    final meta = Meta(
      usuarioId: 1,
      nome: 'Reserva de emergência',
      valorAlvo: 600000, // R$ 6.000,00
      prazo: DateTime(2026, 12, 1),
    );

    test('progresso percentual', () {
      final status = MetaStatus(meta: meta, valorAtual: 240000);
      expect(status.progresso, closeTo(0.4, 0.001));
      expect(status.atingida, isFalse);
    });

    test('RN06: atingida quando os aportes alcançam o alvo', () {
      final status = MetaStatus(meta: meta, valorAtual: 600000);
      expect(status.atingida, isTrue);
      expect(status.aporteMensalNecessario(), 0);
    });

    test('valor mensal necessário para cumprir o prazo (US05)', () {
      final status = MetaStatus(meta: meta, valorAtual: 240000);
      // Faltam R$ 3.600,00 e 4 meses (ago -> dez): R$ 900,00/mês.
      final referencia = DateTime(2026, 8, 15);
      expect(status.mesesRestantes(referencia), 4);
      expect(status.aporteMensalNecessario(referencia), 90000);
    });

    test('prazo vencido usa no mínimo 1 mês', () {
      final status = MetaStatus(meta: meta, valorAtual: 0);
      final depoisDoPrazo = DateTime(2027, 5, 1);
      expect(status.mesesRestantes(depoisDoPrazo), 1);
      expect(status.aporteMensalNecessario(depoisDoPrazo), 600000);
    });
  });
}
