/// Uma conquista que o usuário pode desbloquear (ex.: "Descobrimento",
/// "Estudioso", "Constante").
///
/// As conquistas em si são fixas no app (uma lista pré-definida em
/// código); o que muda por usuário é QUANDO cada uma foi desbloqueada,
/// guardado em [ConquistaDesbloqueada].
class Conquista {
  final String id;
  final String nome;
  final String descricao;

  const Conquista({
    required this.id,
    required this.nome,
    required this.descricao,
  });
}

/// Liga uma [Conquista] ao momento em que o usuário a desbloqueou.
class ConquistaDesbloqueada {
  final String conquistaId;
  final DateTime desbloqueadaEm;

  const ConquistaDesbloqueada({
    required this.conquistaId,
    required this.desbloqueadaEm,
  });

  Map<String, Object?> toMap() {
    return {
      'conquista_id': conquistaId,
      'desbloqueada_em': desbloqueadaEm.toIso8601String(),
    };
  }

  factory ConquistaDesbloqueada.fromMap(Map<String, Object?> map) {
    return ConquistaDesbloqueada(
      conquistaId: map['conquista_id'] as String,
      desbloqueadaEm: DateTime.parse(map['desbloqueada_em'] as String),
    );
  }
}

/// Lista fixa de conquistas do app, conforme a ideia original do
/// grupo (Descobrimento, Estudioso, Constante, Finalizador, Autor).
const List<Conquista> conquistasDisponiveis = [
  Conquista(
    id: 'descobrimento',
    nome: 'Descobrimento',
    descricao: 'Criou o primeiro projeto.',
  ),
  Conquista(
    id: 'estudioso',
    nome: 'Estudioso',
    descricao: 'Acumulou 500 pontos.',
  ),
  Conquista(
    id: 'constante_3',
    nome: 'Constante',
    descricao: 'Estudou 3 dias seguidos.',
  ),
  Conquista(
    id: 'constante_7',
    nome: 'Disciplinado',
    descricao: 'Estudou 7 dias seguidos.',
  ),
  Conquista(
    id: 'finalizador',
    nome: 'Finalizador',
    descricao: 'Concluiu o primeiro projeto (100%).',
  ),
];
