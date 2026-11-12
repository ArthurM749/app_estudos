/// Versão enxuta de um perfil: o suficiente para mostrar avatar + nome numa
/// publicação, comentário ou lista de pessoas.
class PerfilResumo {
  final String id;
  final String nome;
  final String? usuario;

  /// Cor do avatar como inteiro ARGB (mesmas cores dos projetos). Nulo = padrão do tema.
  final int? avatarCor;

  /// Foto de perfil (endereço público no Storage). Nulo = só inicial + cor.
  final String? avatarUrl;

  const PerfilResumo({
    required this.id,
    required this.nome,
    this.usuario,
    this.avatarCor,
    this.avatarUrl,
  });

  factory PerfilResumo.fromMap(Map<String, dynamic> map) {
    return PerfilResumo(
      id: map['id'] as String,
      nome: (map['nome'] as String?) ?? 'Estudante',
      usuario: map['usuario'] as String?,
      avatarCor: (map['avatar_cor'] as num?)?.toInt(),
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}

/// Perfil como OUTRAS pessoas enxergam, vindo da função `perfil_publico` do
/// Supabase. Campo nulo = a pessoa não quis mostrar (ou ainda não sincronizou).
class PerfilPublico {
  final PerfilResumo resumo;
  final String bio;
  final DateTime? criadoEm;

  final int? pontosTotais;
  final int? nivel;
  final int? sequenciaDias;
  final int? totalAnotacoes;
  final int? totalTarefasConcluidas;
  final int? totalProjetosConcluidos;

  /// Ids das conquistas que a pessoa escolheu destacar (vazio se escondeu).
  final List<String> conquistas;

  final int seguidores;
  final int seguindo;
  final bool euSigo;

  /// Interruptor "mostrar projetos" (a política do banco usa o mesmo valor).
  final bool mostrarProjetos;

  const PerfilPublico({
    required this.resumo,
    this.bio = '',
    this.criadoEm,
    this.pontosTotais,
    this.nivel,
    this.sequenciaDias,
    this.totalAnotacoes,
    this.totalTarefasConcluidas,
    this.totalProjetosConcluidos,
    this.conquistas = const [],
    this.seguidores = 0,
    this.seguindo = 0,
    this.euSigo = false,
    this.mostrarProjetos = false,
  });

  String get id => resumo.id;

  bool get temEstatisticas =>
      totalAnotacoes != null ||
      totalTarefasConcluidas != null ||
      totalProjetosConcluidos != null;

  PerfilPublico copyWith({int? seguidores, bool? euSigo}) {
    return PerfilPublico(
      resumo: resumo,
      bio: bio,
      criadoEm: criadoEm,
      pontosTotais: pontosTotais,
      nivel: nivel,
      sequenciaDias: sequenciaDias,
      totalAnotacoes: totalAnotacoes,
      totalTarefasConcluidas: totalTarefasConcluidas,
      totalProjetosConcluidos: totalProjetosConcluidos,
      conquistas: conquistas,
      seguidores: seguidores ?? this.seguidores,
      seguindo: seguindo,
      euSigo: euSigo ?? this.euSigo,
      mostrarProjetos: mostrarProjetos,
    );
  }

  factory PerfilPublico.fromMap(Map<String, dynamic> map) {
    int? numero(String chave) => (map[chave] as num?)?.toInt();
    final criadoEmTexto = map['criado_em'] as String?;
    return PerfilPublico(
      resumo: PerfilResumo.fromMap(map),
      bio: (map['bio'] as String?) ?? '',
      criadoEm: criadoEmTexto != null ? DateTime.parse(criadoEmTexto) : null,
      pontosTotais: numero('pontos_totais'),
      nivel: numero('nivel'),
      sequenciaDias: numero('sequencia_dias'),
      totalAnotacoes: numero('total_anotacoes'),
      totalTarefasConcluidas: numero('total_tarefas_concluidas'),
      totalProjetosConcluidos: numero('total_projetos_concluidos'),
      conquistas: ((map['conquistas'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      seguidores: numero('seguidores') ?? 0,
      seguindo: numero('seguindo') ?? 0,
      euSigo: (map['eu_sigo'] as bool?) ?? false,
      mostrarProjetos: (map['mostrar_projetos'] as bool?) ?? false,
    );
  }
}

/// Os dados do MEU perfil que posso editar (incluindo os interruptores de
/// privacidade). Lido direto das tabelas, não da função pública, porque a
/// função esconde justamente o que eu desliguei.
class PerfilEditavel {
  final String nome;
  final String? usuario;
  final String bio;
  final int? avatarCor;
  final String? avatarUrl;

  final bool mostrarPontos;
  final bool mostrarSequencia;
  final bool mostrarEstatisticas;
  final bool mostrarConquistas;
  final bool mostrarProjetos;

  final List<String> conquistasDestaque;

  const PerfilEditavel({
    required this.nome,
    this.usuario,
    this.bio = '',
    this.avatarCor,
    this.avatarUrl,
    this.mostrarPontos = false,
    this.mostrarSequencia = false,
    this.mostrarEstatisticas = false,
    this.mostrarConquistas = false,
    this.mostrarProjetos = false,
    this.conquistasDestaque = const [],
  });

  /// Cópia com outro endereço de foto (nulo remove a foto).
  PerfilEditavel comAvatarUrl(String? url) {
    return PerfilEditavel(
      nome: nome,
      usuario: usuario,
      bio: bio,
      avatarCor: avatarCor,
      avatarUrl: url,
      mostrarPontos: mostrarPontos,
      mostrarSequencia: mostrarSequencia,
      mostrarEstatisticas: mostrarEstatisticas,
      mostrarConquistas: mostrarConquistas,
      mostrarProjetos: mostrarProjetos,
      conquistasDestaque: conquistasDestaque,
    );
  }

  /// Nada ligado = o perfil público só mostra nome e bio.
  bool get tudoPrivado =>
      !mostrarPontos &&
      !mostrarSequencia &&
      !mostrarEstatisticas &&
      !mostrarConquistas &&
      !mostrarProjetos;

  factory PerfilEditavel.fromMaps(
    Map<String, dynamic> perfil,
    Map<String, dynamic>? estatisticas,
  ) {
    final destaque = estatisticas?['conquistas_destaque'] as List<dynamic>?;
    return PerfilEditavel(
      nome: (perfil['nome'] as String?) ?? 'Estudante',
      usuario: perfil['usuario'] as String?,
      bio: (perfil['bio'] as String?) ?? '',
      avatarCor: (perfil['avatar_cor'] as num?)?.toInt(),
      avatarUrl: perfil['avatar_url'] as String?,
      mostrarPontos: (perfil['mostrar_pontos'] as bool?) ?? false,
      mostrarSequencia: (perfil['mostrar_sequencia'] as bool?) ?? false,
      mostrarEstatisticas: (perfil['mostrar_estatisticas'] as bool?) ?? false,
      mostrarConquistas: (perfil['mostrar_conquistas'] as bool?) ?? false,
      mostrarProjetos: (perfil['mostrar_projetos'] as bool?) ?? false,
      conquistasDestaque: (destaque ?? const []).map((e) => e.toString()).toList(),
    );
  }
}

/// Cartão de um projeto que a pessoa decidiu mostrar no perfil.
class ProjetoPublico {
  final int projetoLocalId;
  final String nome;
  final int cor;
  final int progresso;

  const ProjetoPublico({
    required this.projetoLocalId,
    required this.nome,
    required this.cor,
    required this.progresso,
  });

  factory ProjetoPublico.fromMap(Map<String, dynamic> map) {
    return ProjetoPublico(
      projetoLocalId: (map['projeto_local_id'] as num).toInt(),
      nome: map['nome'] as String,
      cor: (map['cor'] as num).toInt(),
      progresso: (map['progresso'] as num).toInt(),
    );
  }
}
