import 'package:flutter_test/flutter_test.dart';
import 'package:poupa_mais/core/formatters.dart';

void main() {
  group('Formatters (RNF12: padrão pt_BR)', () {
    test('formata centavos como moeda brasileira', () {
      // O intl usa NBSP ( ) entre o símbolo e o valor em pt_BR.
      expect(Formatters.money(142380).replaceAll(RegExp(r'\s'), ' '),
          'R\$ 1.423,80');
      expect(Formatters.moneyPlain(50), '0,50');
    });

    test('converte texto digitado em centavos', () {
      expect(Formatters.parseMoney('1.423,80'), 142380);
      expect(Formatters.parseMoney('1423,8'), 142380);
      expect(Formatters.parseMoney('R\$ 25,00'), 2500);
      expect(Formatters.parseMoney(''), null);
      expect(Formatters.parseMoney('abc'), null);
    });

    test('data no formato dd/mm/aaaa', () {
      expect(Formatters.date(DateTime(2026, 8, 15)), '15/08/2026');
    });
  });

  group('MoneyInputFormatter', () {
    TextEditingValue formatar(String digitado) =>
        MoneyInputFormatter().formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: digitado),
        );

    test('interpreta dígitos como centavos', () {
      expect(formatar('1').text, '0,01');
      expect(formatar('12345').text, '123,45');
      expect(formatar('123456789').text, '1.234.567,89');
    });

    test('ignora caracteres não numéricos', () {
      expect(formatar('12a3').text, '1,23');
      expect(formatar('').text, '');
    });
  });
}
