import 'package:flutter_test/flutter_test.dart';
import 'package:poupa_mais/data/cotacao_service.dart';

void main() {
  group('Integração com a AwesomeAPI: parse da resposta', () {
    const respostaExemplo = '''
    {
      "USDBRL": {
        "code": "USD", "codein": "BRL",
        "name": "Dólar Americano/Real Brasileiro",
        "bid": "5.4321", "pctChange": "-0.35",
        "create_date": "2026-09-04 17:59:58"
      },
      "EURBRL": {
        "code": "EUR", "codein": "BRL",
        "name": "Euro/Real Brasileiro",
        "bid": "6.1234", "pctChange": "0.12",
        "create_date": "2026-09-04 17:59:58"
      }
    }
    ''';

    test('extrai código, valor de compra e variação', () {
      final cotacoes = CotacaoService.parseResposta(respostaExemplo);
      expect(cotacoes, hasLength(2));
      expect(cotacoes.first.codigo, 'USD');
      expect(cotacoes.first.nome, 'Dólar Americano');
      expect(cotacoes.first.compra, closeTo(5.4321, 0.0001));
      expect(cotacoes.first.variacaoPct, closeTo(-0.35, 0.001));
      expect(cotacoes.last.codigo, 'EUR');
    });

    test('ignora pares ausentes sem quebrar (resiliência)', () {
      final cotacoes = CotacaoService.parseResposta('{}');
      expect(cotacoes, isEmpty);
    });
  });
}
