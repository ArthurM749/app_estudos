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

const List<Conquista> conquistasDisponiveis = [
  Conquista(
    id: 'primeira_anotacao',
    nome: 'Primeira anotação',
    descricao: 'Criou sua primeira anotação.',
  ),
  Conquista(
    id: 'arquiteto',
    nome: 'Arquiteto',
    descricao: 'Criou seu primeiro projeto.',
  ),
  Conquista(
    id: 'maos_a_obra',
    nome: 'Mãos à obra',
    descricao: 'Concluiu sua primeira tarefa.',
  ),
  Conquista(
    id: 'biblioteca',
    nome: 'Biblioteca',
    descricao: 'Criou 10 anotações.',
  ),
  Conquista(
    id: 'nivel_5',
    nome: 'Nível 5',
    descricao: 'Alcançou o nível 5.',
  ),
  Conquista(
    id: 'nivel_10',
    nome: 'Nível 10',
    descricao: 'Alcançou o nível 10.',
  ),
  Conquista(
    id: 'aquecendo',
    nome: 'Aquecendo',
    descricao: '3 dias seguidos estudando.',
  ),
  Conquista(
    id: 'semana_perfeita',
    nome: 'Semana perfeita',
    descricao: '7 dias seguidos estudando.',
  ),
  Conquista(
    id: 'centenario',
    nome: 'Centenário',
    descricao: 'Juntou 100 pontos.',
  ),
  Conquista(
    id: 'estudioso',
    nome: 'Estudioso',
    descricao: 'Juntou 500 pontos.',
  ),
  Conquista(
    id: 'dedicado',
    nome: 'Dedicado',
    descricao: 'Concluiu um projeto em 100%.',
  ),
];
