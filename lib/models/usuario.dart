class Usuario {
  final int? id;
  final String nome;
  final String? email;
  final String? senhaHash;
  final String? sal;
  final int rendaMensal; // em centavos
  final DateTime criadoEm;
  final bool modoLocal;

  const Usuario({
    this.id,
    required this.nome,
    this.email,
    this.senhaHash,
    this.sal,
    this.rendaMensal = 0,
    required this.criadoEm,
    this.modoLocal = false,
  });

  Usuario copyWith({String? nome, int? rendaMensal}) => Usuario(
        id: id,
        nome: nome ?? this.nome,
        email: email,
        senhaHash: senhaHash,
        sal: sal,
        rendaMensal: rendaMensal ?? this.rendaMensal,
        criadoEm: criadoEm,
        modoLocal: modoLocal,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'nome': nome,
        'email': email,
        'senha_hash': senhaHash,
        'sal': sal,
        'renda_mensal': rendaMensal,
        'criado_em': criadoEm.toIso8601String(),
        'modo_local': modoLocal ? 1 : 0,
      };

  factory Usuario.fromMap(Map<String, Object?> map) => Usuario(
        id: map['id'] as int?,
        nome: map['nome'] as String,
        email: map['email'] as String?,
        senhaHash: map['senha_hash'] as String?,
        sal: map['sal'] as String?,
        rendaMensal: (map['renda_mensal'] as int?) ?? 0,
        criadoEm: DateTime.parse(map['criado_em'] as String),
        modoLocal: (map['modo_local'] as int?) == 1,
      );
}
