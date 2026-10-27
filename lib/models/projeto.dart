/// Como a porcentagem de um [Projeto] é calculada.
enum ModoProgresso {
  /// O usuário arrasta a barrinha e define o valor na mão.
  manual,

  /// O progresso é a razão entre tarefas concluídas e tarefas totais
  /// do projeto.
  porTarefas,
}

/// Uma pasta de estudo: agrupa anotações, tarefas e ideias sobre um
/// mesmo assunto (ex.: "Estruturas de Dados", "TCC").
class Projeto {
  final int? id;
  final String nome;

  /// Cor do cartão do projeto, em formato ARGB (0xFFRRGGBB).
  final int cor;

  final ModoProgresso modoProgresso;

  /// Progresso de 0 a 100. Só é usado quando [modoProgresso] é
  /// [ModoProgresso.manual] — no modo por tarefas, o valor é
  /// calculado na hora a partir dos itens do projeto.
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
