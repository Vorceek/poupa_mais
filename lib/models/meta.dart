class Meta {
  final int? id;
  final int usuarioId;
  final String nome;
  final int valorAlvo; // em centavos
  final DateTime prazo;
  final bool concluida;

  const Meta({
    this.id,
    required this.usuarioId,
    required this.nome,
    required this.valorAlvo,
    required this.prazo,
    this.concluida = false,
  });

  Meta copyWith({bool? concluida}) => Meta(
        id: id,
        usuarioId: usuarioId,
        nome: nome,
        valorAlvo: valorAlvo,
        prazo: prazo,
        concluida: concluida ?? this.concluida,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'nome': nome,
        'valor_alvo': valorAlvo,
        'prazo': prazo.toIso8601String().substring(0, 10),
        'concluida': concluida ? 1 : 0,
      };

  factory Meta.fromMap(Map<String, Object?> map) => Meta(
        id: map['id'] as int?,
        usuarioId: map['usuario_id'] as int,
        nome: map['nome'] as String,
        valorAlvo: map['valor_alvo'] as int,
        prazo: DateTime.parse(map['prazo'] as String),
        concluida: (map['concluida'] as int?) == 1,
      );
}

class Aporte {
  final int? id;
  final int metaId;
  final int valor; // em centavos
  final DateTime data;

  const Aporte({
    this.id,
    required this.metaId,
    required this.valor,
    required this.data,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'meta_id': metaId,
        'valor': valor,
        'data': data.toIso8601String().substring(0, 10),
      };

  factory Aporte.fromMap(Map<String, Object?> map) => Aporte(
        id: map['id'] as int?,
        metaId: map['meta_id'] as int,
        valor: map['valor'] as int,
        data: DateTime.parse(map['data'] as String),
      );
}

/// Estado calculado de uma meta (RF11): progresso e valor mensal necessário
/// para cumprir o prazo.
class MetaStatus {
  final Meta meta;
  final int valorAtual; // soma dos aportes, em centavos

  const MetaStatus({required this.meta, required this.valorAtual});

  double get progresso =>
      meta.valorAlvo <= 0 ? 0 : (valorAtual / meta.valorAlvo).clamp(0.0, 1.0);

  /// RN06: concluída quando a soma dos aportes atinge ou supera o valor-alvo.
  bool get atingida => valorAtual >= meta.valorAlvo;

  int get restante => (meta.valorAlvo - valorAtual).clamp(0, meta.valorAlvo);

  /// Quantos meses (inteiros, mínimo 1) faltam até o prazo, contados a partir
  /// de [referencia] (por padrão, hoje).
  int mesesRestantes([DateTime? referencia]) {
    final hoje = referencia ?? DateTime.now();
    final meses =
        (meta.prazo.year - hoje.year) * 12 + (meta.prazo.month - hoje.month);
    return meses < 1 ? 1 : meses;
  }

  /// Valor mensal necessário para cumprir o prazo (US05).
  int aporteMensalNecessario([DateTime? referencia]) {
    if (atingida) return 0;
    return (restante / mesesRestantes(referencia)).ceil();
  }
}
