import 'perfil_social.dart';

/// Tipo da publicação. `texto` é a publicação comum; os outros são atividades de
/// estudo que a pessoa escolheu compartilhar (nunca saem sozinhas).
enum TipoPublicacao {
  texto,
  projetoConcluido,
  conquista,
  sequencia,
  evolucao;

  /// Valor gravado na coluna `tipo` do Supabase.
  String get valorBanco {
    switch (this) {
      case TipoPublicacao.texto:
        return 'texto';
      case TipoPublicacao.projetoConcluido:
        return 'projeto_concluido';
      case TipoPublicacao.conquista:
        return 'conquista';
      case TipoPublicacao.sequencia:
        return 'sequencia';
      case TipoPublicacao.evolucao:
        return 'evolucao';
    }
  }

  static TipoPublicacao deBanco(String? valor) {
    return TipoPublicacao.values.firstWhere(
      (tipo) => tipo.valorBanco == valor,
      orElse: () => TipoPublicacao.texto,
    );
  }
}

class Publicacao {
  final String id;
  final PerfilResumo autor;
  final String conteudo;
  final TipoPublicacao tipo;

  /// Detalhes da atividade compartilhada: `titulo`, `detalhe` e, para
  /// conquistas, `conquista_id`.
  final Map<String, dynamic> meta;

  final DateTime criadoEm;

  /// Texto original de `criado_em`, usado como cursor da paginação. O DateTime
  /// do Dart perde microssegundos na web, e isso pularia publicações.
  final String criadoEmBruto;

  final int curtidas;
  final int comentarios;
  final bool curtidaPorMim;

  const Publicacao({
    required this.id,
    required this.autor,
    required this.conteudo,
    required this.tipo,
    required this.meta,
    required this.criadoEm,
    required this.criadoEmBruto,
    this.curtidas = 0,
    this.comentarios = 0,
    this.curtidaPorMim = false,
  });

  String? get metaTitulo => meta['titulo'] as String?;
  String? get metaDetalhe => meta['detalhe'] as String?;
  String? get metaConquistaId => meta['conquista_id'] as String?;

  Publicacao copyWith({int? curtidas, int? comentarios, bool? curtidaPorMim}) {
    return Publicacao(
      id: id,
      autor: autor,
      conteudo: conteudo,
      tipo: tipo,
      meta: meta,
      criadoEm: criadoEm,
      criadoEmBruto: criadoEmBruto,
      curtidas: curtidas ?? this.curtidas,
      comentarios: comentarios ?? this.comentarios,
      curtidaPorMim: curtidaPorMim ?? this.curtidaPorMim,
    );
  }

  /// O PostgREST devolve contagens embutidas assim: `curtidas: [{count: 3}]`.
  static int _contagem(dynamic valor) {
    if (valor is List && valor.isNotEmpty && valor.first is Map) {
      return ((valor.first as Map)['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  factory Publicacao.fromMap(
    Map<String, dynamic> map, {
    bool curtidaPorMim = false,
  }) {
    final bruto = map['criado_em'] as String;
    final autorMapa = map['autor'] as Map?;
    return Publicacao(
      id: map['id'] as String,
      autor: autorMapa != null
          ? PerfilResumo.fromMap(Map<String, dynamic>.from(autorMapa))
          : PerfilResumo(id: map['autor_id'] as String, nome: 'Estudante'),
      conteudo: map['conteudo'] as String,
      tipo: TipoPublicacao.deBanco(map['tipo'] as String?),
      meta: Map<String, dynamic>.from((map['meta'] as Map?) ?? const {}),
      criadoEm: DateTime.parse(bruto),
      criadoEmBruto: bruto,
      curtidas: _contagem(map['curtidas']),
      comentarios: _contagem(map['comentarios']),
      curtidaPorMim: curtidaPorMim,
    );
  }
}

class Comentario {
  final String id;
  final PerfilResumo autor;
  final String conteudo;
  final DateTime criadoEm;

  const Comentario({
    required this.id,
    required this.autor,
    required this.conteudo,
    required this.criadoEm,
  });

  factory Comentario.fromMap(Map<String, dynamic> map) {
    final autorMapa = map['autor'] as Map?;
    return Comentario(
      id: map['id'] as String,
      autor: autorMapa != null
          ? PerfilResumo.fromMap(Map<String, dynamic>.from(autorMapa))
          : PerfilResumo(id: map['autor_id'] as String, nome: 'Estudante'),
      conteudo: map['conteudo'] as String,
      criadoEm: DateTime.parse(map['criado_em'] as String),
    );
  }
}
