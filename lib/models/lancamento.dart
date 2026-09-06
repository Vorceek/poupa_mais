enum TipoLancamento { despesa, receita }

enum Recorrencia { nenhuma, semanal, mensal }

class Lancamento {
  final int? id;
  final int usuarioId;
  final int categoriaId;
  final int valor; // em centavos, sempre positivo (RN01)
  final TipoLancamento tipo;
  final DateTime data;
  final String descricao;
  final Recorrencia recorrencia;

  /// Preenchido quando o lançamento foi gerado automaticamente a partir de
  /// um lançamento recorrente (RF13); aponta para o lançamento de origem.
  final int? origemRecorrenteId;

  const Lancamento({
    this.id,
    required this.usuarioId,
    required this.categoriaId,
    required this.valor,
    required this.tipo,
    required this.data,
    this.descricao = '',
    this.recorrencia = Recorrencia.nenhuma,
    this.origemRecorrenteId,
  });

  Lancamento copyWith({
    int? categoriaId,
    int? valor,
    TipoLancamento? tipo,
    DateTime? data,
    String? descricao,
    Recorrencia? recorrencia,
  }) =>
      Lancamento(
        id: id,
        usuarioId: usuarioId,
        categoriaId: categoriaId ?? this.categoriaId,
        valor: valor ?? this.valor,
        tipo: tipo ?? this.tipo,
        data: data ?? this.data,
        descricao: descricao ?? this.descricao,
        recorrencia: recorrencia ?? this.recorrencia,
        origemRecorrenteId: origemRecorrenteId,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'categoria_id': categoriaId,
        'valor': valor,
        'tipo': tipo.name,
        'data': data.toIso8601String().substring(0, 10),
        'descricao': descricao,
        'recorrencia': recorrencia.name,
        'origem_recorrente_id': origemRecorrenteId,
      };

  factory Lancamento.fromMap(Map<String, Object?> map) => Lancamento(
        id: map['id'] as int?,
        usuarioId: map['usuario_id'] as int,
        categoriaId: map['categoria_id'] as int,
        valor: map['valor'] as int,
        tipo: TipoLancamento.values.byName(map['tipo'] as String),
        data: DateTime.parse(map['data'] as String),
        descricao: (map['descricao'] as String?) ?? '',
        recorrencia:
            Recorrencia.values.byName((map['recorrencia'] as String?) ?? 'nenhuma'),
        origemRecorrenteId: map['origem_recorrente_id'] as int?,
      );
}
