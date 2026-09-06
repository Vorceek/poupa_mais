import 'package:flutter/material.dart';

class Categoria {
  final int? id;
  final String nome;
  final int icone; // codePoint de um Icons.* constante
  final int cor; // valor ARGB
  final bool ativa;
  final bool padrao;

  const Categoria({
    this.id,
    required this.nome,
    required this.icone,
    required this.cor,
    this.ativa = true,
    this.padrao = false,
  });

  IconData get iconData => _iconById[icone] ?? Icons.category_outlined;
  Color get color => Color(cor);

  Categoria copyWith({String? nome, int? icone, int? cor, bool? ativa}) =>
      Categoria(
        id: id,
        nome: nome ?? this.nome,
        icone: icone ?? this.icone,
        cor: cor ?? this.cor,
        ativa: ativa ?? this.ativa,
        padrao: padrao,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'nome': nome,
        'icone': icone,
        'cor': cor,
        'ativa': ativa ? 1 : 0,
        'padrao': padrao ? 1 : 0,
      };

  factory Categoria.fromMap(Map<String, Object?> map) => Categoria(
        id: map['id'] as int?,
        nome: map['nome'] as String,
        icone: map['icone'] as int,
        cor: map['cor'] as int,
        ativa: (map['ativa'] as int?) == 1,
        padrao: (map['padrao'] as int?) == 1,
      );

  /// Ícones disponíveis para categorias. Usamos um catálogo fixo (id -> ícone
  /// constante) para permitir tree shaking de ícones no build de release.
  static const Map<int, IconData> _iconById = {
    1: Icons.restaurant_outlined,
    2: Icons.directions_bus_outlined,
    3: Icons.home_outlined,
    4: Icons.sports_esports_outlined,
    5: Icons.favorite_outline,
    6: Icons.school_outlined,
    7: Icons.savings_outlined,
    8: Icons.pets_outlined,
    9: Icons.shopping_bag_outlined,
    10: Icons.work_outline,
    11: Icons.card_giftcard_outlined,
    12: Icons.build_outlined,
  };

  static Map<int, IconData> get catalogoIcones => _iconById;
}
