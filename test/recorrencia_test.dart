import 'package:flutter_test/flutter_test.dart';
import 'package:poupa_mais/data/lancamento_repository.dart';
import 'package:poupa_mais/models/lancamento.dart';

void main() {
  group('RF13: geração de ocorrências recorrentes', () {
    test('mensal: uma ocorrência por mês, no mesmo dia', () {
      final datas = LancamentoRepository.proximasOcorrencias(
        DateTime(2026, 5, 10),
        Recorrencia.mensal,
        DateTime(2026, 8, 15),
      );
      expect(datas, [
        DateTime(2026, 6, 10),
        DateTime(2026, 7, 10),
        DateTime(2026, 8, 10),
      ]);
    });

    test('mensal: dia 31 é ajustado para o último dia de meses curtos', () {
      final datas = LancamentoRepository.proximasOcorrencias(
        DateTime(2026, 1, 31),
        Recorrencia.mensal,
        DateTime(2026, 4, 30),
      );
      expect(datas, [
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
      ]);
    });

    test('semanal: a cada 7 dias até a data-limite', () {
      final datas = LancamentoRepository.proximasOcorrencias(
        DateTime(2026, 8, 1),
        Recorrencia.semanal,
        DateTime(2026, 8, 22),
      );
      expect(datas, [
        DateTime(2026, 8, 8),
        DateTime(2026, 8, 15),
        DateTime(2026, 8, 22),
      ]);
    });

    test('sem recorrência não gera nada', () {
      expect(
        LancamentoRepository.proximasOcorrencias(
            DateTime(2026, 1, 1), Recorrencia.nenhuma, DateTime(2026, 12, 31)),
        isEmpty,
      );
    });
  });
}
