/// Regras de negócio do formulário de lançamento e de cadastro
/// (seção 2.3 do documento de concepção).
class Validators {
  Validators._();

  /// RN01: o valor de um lançamento deve ser sempre maior que zero.
  static String? transactionValue(int? cents) {
    if (cents == null || cents <= 0) {
      return 'Informe um valor maior que zero.';
    }
    return null;
  }

  /// RN03: um lançamento não pode ter data futura superior a 12 meses
  /// nem anterior à data de criação da conta.
  static String? transactionDate(DateTime date, DateTime accountCreatedAt) {
    final limit = DateTime.now().add(const Duration(days: 365));
    final floor = DateTime(
        accountCreatedAt.year, accountCreatedAt.month, accountCreatedAt.day);
    if (date.isAfter(limit)) {
      return 'A data não pode passar de 12 meses no futuro.';
    }
    if (date.isBefore(floor)) {
      return 'A data não pode ser anterior à criação da conta.';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Informe seu nome.';
    }
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    final regex = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');
    if (!regex.hasMatch(v)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  static String? goalTarget(int? cents) {
    if (cents == null || cents <= 0) {
      return 'Informe o valor-alvo da meta.';
    }
    return null;
  }
}
