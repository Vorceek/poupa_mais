class Orcamento {
  final int? id;
  final int usuarioId;
  final int categoriaId;
  final int valorTeto; // em centavos

  const Orcamento({
    this.id,
    required this.usuarioId,
    required this.categoriaId,
    required this.valorTeto,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'categoria_id': categoriaId,
        'valor_teto': valorTeto,
      };

  factory Orcamento.fromMap(Map<String, Object?> map) => Orcamento(
        id: map['id'] as int?,
        usuarioId: map['usuario_id'] as int,
        categoriaId: map['categoria_id'] as int,
        valorTeto: map['valor_teto'] as int,
      );
}

/// Estado calculado de um orçamento no mês corrente (RF09/RF10).
/// O teto é mensal e o consumo reinicia automaticamente a cada mês (RN05),
/// pois o gasto é sempre somado sobre os lançamentos do mês de referência.
enum FaixaOrcamento { ok, alerta, estourado }

class OrcamentoStatus {
  final Orcamento orcamento;
  final int gasto; // em centavos, no mês corrente

  const OrcamentoStatus({required this.orcamento, required this.gasto});

  double get percentual =>
      orcamento.valorTeto <= 0 ? 0 : gasto / orcamento.valorTeto;

  /// Semáforo do protótipo (tela 6): verde até 79%, âmbar de 80% a 99%,
  /// vermelho ao atingir o teto.
  FaixaOrcamento get faixa {
    if (percentual >= 1.0) return FaixaOrcamento.estourado;
    if (percentual >= 0.8) return FaixaOrcamento.alerta;
    return FaixaOrcamento.ok;
  }
}
