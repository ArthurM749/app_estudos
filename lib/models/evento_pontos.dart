/// A ação que gerou pontos para o usuário.
///
/// Os valores de pontos por ação ficam centralizados em
/// `RegrasDePontos` (lib/data/regras_pontos.dart), não aqui — este
/// enum só identifica QUAL ação aconteceu.
enum TipoAcao {
  criarAnotacao,
  concluirTarefa,
  registrarIdeia,
  concluirProjeto,
}

/// Um registro histórico de pontos ganhos.
///
/// A soma desses eventos por dia/semana é o que alimenta o
/// dashboard (pontos de hoje x ontem) e a tela de progresso.
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
