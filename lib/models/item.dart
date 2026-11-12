enum TipoItem { anotacao, tarefa }

enum Visibilidade { privada, publica }

class Item {
  final int? id;
  final int? projetoId;
  final TipoItem tipo;
  final String titulo;
  final String conteudo;

  final bool concluido;

  final Visibilidade visibilidade;
  final DateTime criadoEm;

  /// Id da publicação no Supabase quando a anotação está publicada. Nulo =
  /// privada (a anotação nunca saiu do aparelho).
  final String? publicacaoId;

  /// Anotação já publicada que foi editada e ainda não teve o texto novo
  /// enviado (sem internet na hora de salvar). O app reenvia sozinho depois.
  final bool syncPendente;

  const Item({
    this.id,
    this.projetoId,
    required this.tipo,
    required this.titulo,
    this.conteudo = '',
    this.concluido = false,
    this.visibilidade = Visibilidade.privada,
    required this.criadoEm,
    this.publicacaoId,
    this.syncPendente = false,
  });

  /// A pessoa quer esta anotação pública (a "intenção"). Se o envio ainda não
  /// aconteceu, [aguardandoEnvio] fica verdadeiro.
  bool get querPublicada => visibilidade == Visibilidade.publica;

  bool get estaPublicada => publicacaoId != null;

  /// A nuvem ainda não reflete o que a pessoa escolheu: publicar, atualizar o
  /// texto ou retirar. É a "fila de saída" das anotações.
  bool get aguardandoEnvio =>
      tipo == TipoItem.anotacao &&
      ((querPublicada && (publicacaoId == null || syncPendente)) ||
          (!querPublicada && publicacaoId != null));

  Item copyWith({
    int? id,
    int? projetoId,
    TipoItem? tipo,
    String? titulo,
    String? conteudo,
    bool? concluido,
    Visibilidade? visibilidade,
    DateTime? criadoEm,
    String? publicacaoId,
    bool limparPublicacaoId = false,
    bool? syncPendente,
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
      publicacaoId:
          limparPublicacaoId ? null : (publicacaoId ?? this.publicacaoId),
      syncPendente: syncPendente ?? this.syncPendente,
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
      'publicacao_id': publicacaoId,
      'sync_pendente': syncPendente ? 1 : 0,
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
      publicacaoId: map['publicacao_id'] as String?,
      syncPendente: (map['sync_pendente'] as int? ?? 0) == 1,
    );
  }
}
