enum TipoAcao {
  criarProjeto,
  criarAnotacao,
  concluirTarefa,
  concluirProjeto,

  /// Pontos que a conta já tinha na nuvem (ganhos em outro aparelho) e que este
  /// aparelho recebeu ao sincronizar. Só entra no total; não é uma ação.
  ajusteNuvem,
}

class EventoDePontos {
  final int? id;
  final TipoAcao tipo;
  final int pontos;
  final DateTime data;

  /// Identifica "o que gerou" os pontos (ex.: `item:12`, `projeto:3`). O banco
  /// não aceita dois eventos do mesmo tipo com a mesma referência, então
  /// marcar e desmarcar a mesma tarefa não rende pontos de novo.
  final String? referencia;

  const EventoDePontos({
    this.id,
    required this.tipo,
    required this.pontos,
    required this.data,
    this.referencia,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'tipo': tipo.name,
      'pontos': pontos,
      'data': data.toIso8601String(),
      'referencia': referencia,
    };
  }

  factory EventoDePontos.fromMap(Map<String, Object?> map) {
    return EventoDePontos(
      id: map['id'] as int?,
      tipo: TipoAcao.values.byName(map['tipo'] as String),
      pontos: map['pontos'] as int,
      data: DateTime.parse(map['data'] as String),
      referencia: map['referencia'] as String?,
    );
  }
}
