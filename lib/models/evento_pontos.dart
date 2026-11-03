enum TipoAcao {
  criarProjeto,
  criarAnotacao,
  concluirTarefa,
  concluirProjeto,
}

class EventoDePontos {
  final int? id;
  final TipoAcao tipo;
  final int pontos;
  final DateTime data;

  const EventoDePontos({
    this.id,
    required this.tipo,
    required this.pontos,
    required this.data,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'tipo': tipo.name,
      'pontos': pontos,
      'data': data.toIso8601String(),
    };
  }

  factory EventoDePontos.fromMap(Map<String, Object?> map) {
    return EventoDePontos(
      id: map['id'] as int?,
      tipo: TipoAcao.values.byName(map['tipo'] as String),
      pontos: map['pontos'] as int,
      data: DateTime.parse(map['data'] as String),
    );
  }
}
