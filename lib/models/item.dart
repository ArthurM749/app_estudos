/// Tipo de um [Item]: uma anotação, uma tarefa ou uma ideia.
///
/// As três coisas compartilham a mesma tabela/entidade porque têm os
/// mesmos campos básicos (título, conteúdo, projeto opcional). O que
/// muda é como cada tela interpreta e exibe o registro.
enum TipoItem { anotacao, tarefa, ideia }

/// Se uma anotação pode ser vista só pelo dono ou por qualquer pessoa.
///
/// Na versão teste isso só existe como campo de dados — não há feed
/// nem publicação de verdade ainda (isso fica para a fase de
/// sincronização, quando o app tiver conexão com a internet).
enum Visibilidade { privada, publica }

/// Uma anotação, tarefa ou ideia do usuário.
///
/// Pode pertencer a um [Projeto] (via [projetoId]) ou existir solta,
/// sem projeto nenhum — por isso [projetoId] é opcional.
class Item {
  final int? id;
  final int? projetoId;
  final TipoItem tipo;
  final String titulo;
  final String conteudo;

  /// Só é relevante quando [tipo] é [TipoItem.tarefa]. Anotações e
  /// ideias ignoram este campo.
  final bool concluido;

  final Visibilidade visibilidade;
  final DateTime criadoEm;

  const Item({
    this.id,
    this.projetoId,
    required this.tipo,
    required this.titulo,
    this.conteudo = '',
    this.concluido = false,
    this.visibilidade = Visibilidade.privada,
    required this.criadoEm,
  });

  Item copyWith({
    int? id,
    int? projetoId,
    TipoItem? tipo,
    String? titulo,
    String? conteudo,
    bool? concluido,
    Visibilidade? visibilidade,
    DateTime? criadoEm,
  }) {
    return Item(
      id: id ?? this.id,
      projetoId: projetoId ?? this.projetoId,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      conteudo: conteudo ?? this.conteudo,
      concluido: concluido ?? this.concluido,
      visibilidade: visibilidade ?? this.visibilidade,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'projeto_id': projetoId,
      'tipo': tipo.name,
      'titulo': titulo,
      'conteudo': conteudo,
      'concluido': concluido ? 1 : 0,
      'visibilidade': visibilidade.name,
      'criado_em': criadoEm.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, Object?> map) {
    return Item(
      id: map['id'] as int?,
      projetoId: map['projeto_id'] as int?,
      tipo: TipoItem.values.byName(map['tipo'] as String),
      titulo: map['titulo'] as String,
      conteudo: map['conteudo'] as String? ?? '',
      concluido: (map['concluido'] as int) == 1,
      visibilidade: Visibilidade.values.byName(map['visibilidade'] as String),
      criadoEm: DateTime.parse(map['criado_em'] as String),
    );
  }
}
