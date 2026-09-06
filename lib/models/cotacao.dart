/// Cotação de moeda obtida da AwesomeAPI (integração com servidor via HTTPS).
class Cotacao {
  final String codigo; // ex.: "USD"
  final String nome; // ex.: "Dólar Americano/Real Brasileiro"
  final double compra; // valor de compra em BRL
  final double variacaoPct; // variação percentual do dia
  final DateTime atualizadoEm;

  const Cotacao({
    required this.codigo,
    required this.nome,
    required this.compra,
    required this.variacaoPct,
    required this.atualizadoEm,
  });

  factory Cotacao.fromJson(Map<String, dynamic> json) => Cotacao(
        codigo: json['code'] as String,
        nome: (json['name'] as String).split('/').first,
        compra: double.parse(json['bid'] as String),
        variacaoPct: double.parse(json['pctChange'] as String),
        atualizadoEm: DateTime.parse(json['create_date'] as String),
      );

  Map<String, dynamic> toJson() => {
        'code': codigo,
        'name': nome,
        'bid': compra.toString(),
        'pctChange': variacaoPct.toString(),
        'create_date': atualizadoEm.toIso8601String(),
      };
}
