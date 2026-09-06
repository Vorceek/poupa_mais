import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatação em português do Brasil (RNF12): valores em R$, separador
/// decimal por vírgula e datas no formato dd/mm/aaaa.
/// Todos os valores monetários do app circulam como inteiros em centavos,
/// evitando erros de arredondamento de ponto flutuante.
class Formatters {
  Formatters._();

  static final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final DateFormat _date = DateFormat('dd/MM/yyyy');
  static final DateFormat _monthYear = DateFormat("MMMM 'de' yyyy", 'pt_BR');

  /// 142380 (centavos) -> "R$ 1.423,80"
  static String money(int cents) => _currency.format(cents / 100);

  /// Valor sem símbolo: 142380 -> "1.423,80"
  static String moneyPlain(int cents) =>
      _currency.format(cents / 100).replaceFirst('R\$', '').trim();

  static String date(DateTime d) => _date.format(d);

  /// "agosto de 2026" -> "Agosto de 2026"
  static String monthYear(DateTime d) {
    final s = _monthYear.format(d);
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Converte texto digitado ("1.423,80" ou "1423,8") em centavos.
  /// Retorna null quando o texto não representa um valor válido.
  static int? parseMoney(String input) {
    final cleaned = input
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null) return null;
    return (value * 100).round();
  }
}

/// Formatador de campo monetário: o usuário digita apenas dígitos e o campo
/// exibe o valor como moeda ("1" -> 0,01; "12345" -> 123,45), no mesmo padrão
/// dos aplicativos bancários brasileiros.
class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    // Limita a 10^10 centavos para evitar overflow de exibição.
    final trimmed = digits.length > 11 ? digits.substring(0, 11) : digits;
    final cents = int.parse(trimmed);
    final text = Formatters.moneyPlain(cents);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
