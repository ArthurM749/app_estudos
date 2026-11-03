enum ModoProgresso {
  manual,

  porTarefas,
}

class Projeto {
  final int? id;
  final String nome;

  final int cor;

  final ModoProgresso modoProgresso;

  final int progressoManual;

  final bool arquivado;
  final DateTime criadoEm;

  const Projeto({
    this.id,
    required this.nome,
    required this.cor,
    this.modoProgresso = ModoProgresso.porTarefas,
    this.progressoManual = 0,
    this.arquivado = false,
    required this.criadoEm,
  });

  Projeto copyWith({
    int? id,
    String? nome,
    int? cor,
    ModoProgresso? modoProgresso,
    int? progressoManual,
    bool? arquivado,
    DateTime? criadoEm,
  }) {
    return Projeto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cor: cor ?? this.cor,
      modoProgresso: modoProgresso ?? this.modoProgresso,
      progressoManual: progressoManual ?? this.progressoManual,
      arquivado: arquivado ?? this.arquivado,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cor': cor,
      'modo_progresso': modoProgresso.name,
      'progresso_manual': progressoManual,
      'arquivado': arquivado ? 1 : 0,
      'criado_em': criadoEm.toIso8601String(),
    };
  }

  factory Projeto.fromMap(Map<String, Object?> map) {
    return Projeto(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      cor: map['cor'] as int,
      modoProgresso:
          ModoProgresso.values.byName(map['modo_progresso'] as String),
      progressoManual: map['progresso_manual'] as int,
      arquivado: (map['arquivado'] as int) == 1,
      criadoEm: DateTime.parse(map['criado_em'] as String),
    );
  }
}
