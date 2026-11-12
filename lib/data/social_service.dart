import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/perfil_social.dart';
import '../models/projeto.dart';
import '../models/publicacao.dart';

/// Erro "de negócio" da parte social, com mensagem pronta para mostrar.
class SocialException implements Exception {
  final String mensagem;
  const SocialException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Todas as chamadas ao Supabase da parte social ficam aqui, no mesmo estilo do
/// AuthService: telas e estado não montam consulta nenhuma. Reaproveita o
/// cliente que o `Supabase.initialize` do main.dart já criou (e, com ele, a
/// sessão do login) — nada de autenticação é alterado aqui.
class SocialService {
  SocialService._();
  static final SocialService instance = SocialService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Id da conta logada, ou null se a pessoa está no modo "sem conta".
  String? get meuId {
    try {
      return _client.auth.currentUser?.id;
    } catch (_) {
      return null; // Supabase não iniciou (sem internet na abertura)
    }
  }

  String get _meuIdObrigatorio {
    final id = meuId;
    if (id == null) {
      throw const SocialException(
          'Entre na sua conta para usar a parte social.');
    }
    return id;
  }

  // Um espaço depois da vírgula pode quebrar o select do PostgREST, então a
  // string é escrita sem espaços. `autor:perfis!publicacoes_autor_fkey(...)`
  // usa o nome da chave estrangeira definido em supabase/social_v1.sql.
  static const _selecaoPublicacao =
      'id,autor_id,titulo,conteudo,tipo,meta,criado_em,'
      'autor:perfis!publicacoes_autor_fkey(id,nome,usuario,avatar_cor,avatar_url),'
      'curtidas(count),comentarios(count)';

  static const _selecaoComentario = 'id,autor_id,conteudo,criado_em,'
      'autor:perfis!comentarios_autor_fkey(id,nome,usuario,avatar_cor,avatar_url)';

  static const _bucketAvatares = 'avatares';

  // ------------------------------------------------------------------ perfil

  /// Cria a linha em `perfis` se ainda não existir (contas antigas ou falha do
  /// gatilho do banco). Não sobrescreve nada que já existe.
  Future<void> garantirPerfil({required String nome}) async {
    final id = _meuIdObrigatorio;
    final existente =
        await _client.from('perfis').select('id').eq('id', id).maybeSingle();
    if (existente != null) return;
    final nomeLimpo = nome.trim().isEmpty ? 'Estudante' : nome.trim();
    await _client.from('perfis').insert({
      'id': id,
      'nome': nomeLimpo.length > 60 ? nomeLimpo.substring(0, 60) : nomeLimpo,
    });
  }

  Future<PerfilEditavel?> obterMeuPerfil() async {
    final id = _meuIdObrigatorio;
    final perfil =
        await _client.from('perfis').select().eq('id', id).maybeSingle();
    if (perfil == null) return null;
    final estatisticas = await _client
        .from('perfis_estatisticas')
        .select('conquistas_destaque')
        .eq('usuario_id', id)
        .maybeSingle();
    return PerfilEditavel.fromMaps(perfil, estatisticas);
  }

  Future<void> salvarMeuPerfil(PerfilEditavel perfil) async {
    final id = _meuIdObrigatorio;
    await _client.from('perfis').update({
      'nome': perfil.nome,
      'usuario': perfil.usuario,
      'bio': perfil.bio,
      'avatar_cor': perfil.avatarCor,
      'avatar_url': perfil.avatarUrl,
      'mostrar_pontos': perfil.mostrarPontos,
      'mostrar_sequencia': perfil.mostrarSequencia,
      'mostrar_estatisticas': perfil.mostrarEstatisticas,
      'mostrar_conquistas': perfil.mostrarConquistas,
      'mostrar_projetos': perfil.mostrarProjetos,
    }).eq('id', id);

    // As conquistas destacadas ficam na tabela privada: quem vê é decidido
    // pela função perfil_publico, de acordo com o interruptor acima.
    await _client.from('perfis_estatisticas').upsert(
      {
        'usuario_id': id,
        'conquistas_destaque': perfil.conquistasDestaque,
      },
      onConflict: 'usuario_id',
    );
  }

  /// Envia a foto de perfil e devolve o endereço público. Cada envio usa um
  /// nome novo (`<id>/<instante>.<ext>`), então ninguém fica vendo a foto
  /// antiga em cache. A pasta com o id da conta é o que a política do Storage
  /// exige para aceitar o arquivo.
  Future<String> enviarAvatar(Uint8List bytes, String extensao) async {
    final id = _meuIdObrigatorio;
    final caminho = '$id/${DateTime.now().millisecondsSinceEpoch}.$extensao';
    final tipo = extensao == 'png'
        ? 'image/png'
        : extensao == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    await _client.storage.from(_bucketAvatares).uploadBinary(
          caminho,
          bytes,
          fileOptions: FileOptions(contentType: tipo, upsert: false),
        );
    return _client.storage.from(_bucketAvatares).getPublicUrl(caminho);
  }

  /// Apaga uma foto antiga a partir do endereço público. Melhor esforço: se
  /// falhar, só sobra um arquivo órfão no bucket, sem efeito para ninguém.
  Future<void> removerAvatarAntigo(String? url) async {
    if (url == null) return;
    final marcador = '/$_bucketAvatares/';
    final posicao = url.indexOf(marcador);
    if (posicao == -1) return;
    final caminho =
        Uri.decodeComponent(url.substring(posicao + marcador.length));
    // Só apaga dentro da própria pasta (a política do banco também exige).
    if (!caminho.startsWith('$_meuIdObrigatorio/')) return;
    try {
      await _client.storage.from(_bucketAvatares).remove([caminho]);
    } catch (_) {}
  }

  /// Envia os números do app (que moram no SQLite) para a tabela privada.
  /// Quem os enxerga é decidido depois, pela função perfil_publico.
  Future<void> atualizarEstatisticas({
    required int pontosTotais,
    required int nivel,
    required int sequenciaDias,
    required int totalAnotacoes,
    required int totalTarefasConcluidas,
    required int totalProjetosConcluidos,
  }) async {
    await _client.from('perfis_estatisticas').upsert(
      {
        'usuario_id': _meuIdObrigatorio,
        'pontos_totais': pontosTotais,
        'nivel': nivel,
        'sequencia_dias': sequenciaDias,
        'total_anotacoes': totalAnotacoes,
        'total_tarefas_concluidas': totalTarefasConcluidas,
        'total_projetos_concluidos': totalProjetosConcluidos,
        'atualizado_em': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'usuario_id',
    );
  }

  Future<PerfilPublico?> perfilPublico(String usuarioId) async {
    final resposta =
        await _client.rpc('perfil_publico', params: {'p_id': usuarioId});
    final linhas = resposta as List<dynamic>;
    if (linhas.isEmpty) return null;
    return PerfilPublico.fromMap(Map<String, dynamic>.from(linhas.first as Map));
  }

  // ---------------------------------------------------------------- projetos

  Future<List<ProjetoPublico>> projetosPublicosDe(String usuarioId) async {
    final linhas = await _client
        .from('projetos_publicos')
        .select()
        .eq('usuario_id', usuarioId)
        .order('atualizado_em', ascending: false);
    return linhas.map(ProjetoPublico.fromMap).toList();
  }

  Future<Set<int>> idsProjetosPublicadosPorMim() async {
    final linhas = await _client
        .from('projetos_publicos')
        .select('projeto_local_id')
        .eq('usuario_id', _meuIdObrigatorio);
    return linhas.map((l) => (l['projeto_local_id'] as num).toInt()).toSet();
  }

  Future<void> publicarProjetos(
    List<Projeto> projetos,
    Map<int, int> progressoPorProjeto,
  ) async {
    if (projetos.isEmpty) return;
    final meuId = _meuIdObrigatorio;
    final agora = DateTime.now().toUtc().toIso8601String();
    await _client.from('projetos_publicos').upsert(
      [
        for (final projeto in projetos)
          {
            'usuario_id': meuId,
            'projeto_local_id': projeto.id,
            'nome': projeto.nome,
            'cor': projeto.cor,
            'progresso': (progressoPorProjeto[projeto.id] ?? 0).clamp(0, 100),
            'atualizado_em': agora,
          },
      ],
      onConflict: 'usuario_id,projeto_local_id',
    );
  }

  Future<void> removerProjetosPublicos(Iterable<int> idsLocais) async {
    final lista = idsLocais.toList();
    if (lista.isEmpty) return;
    await _client
        .from('projetos_publicos')
        .delete()
        .eq('usuario_id', _meuIdObrigatorio)
        .inFilter('projeto_local_id', lista);
  }

  // ------------------------------------------------------------------- feed

  /// Publicações mais recentes primeiro. [autores] restringe a quem a pessoa
  /// segue; [autorId] restringe a um único perfil; [antesDe] é o cursor da
  /// paginação (o `criadoEmBruto` da última publicação já carregada).
  Future<List<Publicacao>> listarPublicacoes({
    List<String>? autores,
    String? autorId,
    String? antesDe,
    String? tituloContem,
    int limite = 20,
  }) async {
    if (autores != null && autores.isEmpty) return [];

    var consulta = _client.from('publicacoes').select(_selecaoPublicacao);
    if (autores != null) consulta = consulta.inFilter('autor_id', autores);
    if (autorId != null) consulta = consulta.eq('autor_id', autorId);
    if (antesDe != null) consulta = consulta.lt('criado_em', antesDe);
    if (tituloContem != null && tituloContem.trim().isNotEmpty) {
      // %, _ e \ são curingas do LIKE: escapados para o texto digitado ser
      // buscado literalmente.
      final termo = tituloContem
          .trim()
          .replaceAll('\\', '\\\\')
          .replaceAll('%', '\\%')
          .replaceAll('_', '\\_');
      consulta = consulta.ilike('titulo', '%$termo%');
    }

    final linhas =
        await consulta.order('criado_em', ascending: false).limit(limite);

    final ids = linhas.map((l) => l['id'] as String).toList();
    final curtidas = await _curtidasMinhasEntre(ids);

    return linhas
        .map((l) => Publicacao.fromMap(l,
            curtidaPorMim: curtidas.contains(l['id'] as String)))
        .toList();
  }

  Future<Set<String>> _curtidasMinhasEntre(List<String> publicacaoIds) async {
    if (publicacaoIds.isEmpty) return {};
    final linhas = await _client
        .from('curtidas')
        .select('publicacao_id')
        .eq('usuario_id', _meuIdObrigatorio)
        .inFilter('publicacao_id', publicacaoIds);
    return linhas.map((l) => l['publicacao_id'] as String).toSet();
  }

  /// Cria a publicação e devolve o id (as anotações guardam esse id para
  /// poder atualizar ou retirar a publicação depois).
  Future<String> publicar({
    String? titulo,
    required String conteudo,
    TipoPublicacao tipo = TipoPublicacao.texto,
    Map<String, dynamic> meta = const {},
  }) async {
    final linha = await _client
        .from('publicacoes')
        .insert({
          'autor_id': _meuIdObrigatorio,
          'titulo': titulo,
          'conteudo': conteudo,
          'tipo': tipo.valorBanco,
          'meta': meta,
        })
        .select('id')
        .single();
    return linha['id'] as String;
  }

  /// Atualiza título e texto de uma publicação minha (anotação editada).
  /// Devolve false se ela não existe mais (apagada em outro aparelho).
  Future<bool> atualizarPublicacao({
    required String id,
    required String titulo,
    required String conteudo,
  }) async {
    final linhas = await _client
        .from('publicacoes')
        .update({'titulo': titulo, 'conteudo': conteudo})
        .eq('id', id)
        .eq('autor_id', _meuIdObrigatorio)
        .select('id');
    return linhas.isNotEmpty;
  }

  Future<void> excluirPublicacao(String id) async {
    await _client.from('publicacoes').delete().eq('id', id);
  }

  /// Quantas publicações existem com esse id (0 = já foi apagada).
  Future<bool> publicacaoExiste(String id) async {
    final linha = await _client
        .from('publicacoes')
        .select('id')
        .eq('id', id)
        .maybeSingle();
    return linha != null;
  }

  // ---------------------------------------------------------------- curtidas

  Future<void> curtir(String publicacaoId) async {
    try {
      await _client.from('curtidas').insert({
        'publicacao_id': publicacaoId,
        'usuario_id': _meuIdObrigatorio,
      });
    } on PostgrestException catch (e) {
      // 23505 = já tinha curtido (duplo toque, outro aparelho): o resultado
      // desejado já existe, então não é erro.
      if (e.code != '23505') rethrow;
    }
  }

  Future<void> descurtir(String publicacaoId) async {
    await _client
        .from('curtidas')
        .delete()
        .eq('publicacao_id', publicacaoId)
        .eq('usuario_id', _meuIdObrigatorio);
  }

  // ------------------------------------------------------------- comentários

  Future<List<Comentario>> listarComentarios(String publicacaoId) async {
    final linhas = await _client
        .from('comentarios')
        .select(_selecaoComentario)
        .eq('publicacao_id', publicacaoId)
        .order('criado_em', ascending: true);
    return linhas.map(Comentario.fromMap).toList();
  }

  Future<void> comentar(String publicacaoId, String conteudo) async {
    await _client.from('comentarios').insert({
      'publicacao_id': publicacaoId,
      'autor_id': _meuIdObrigatorio,
      'conteudo': conteudo,
    });
  }

  Future<void> excluirComentario(String comentarioId) async {
    await _client.from('comentarios').delete().eq('id', comentarioId);
  }

  // --------------------------------------------------------------- seguidores

  Future<void> seguir(String usuarioId) async {
    try {
      await _client.from('seguidores').insert({
        'seguidor_id': _meuIdObrigatorio,
        'seguido_id': usuarioId,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
    }
  }

  Future<void> deixarDeSeguir(String usuarioId) async {
    await _client
        .from('seguidores')
        .delete()
        .eq('seguidor_id', _meuIdObrigatorio)
        .eq('seguido_id', usuarioId);
  }

  Future<List<String>> idsSeguidosPorMim() async {
    final linhas = await _client
        .from('seguidores')
        .select('seguido_id')
        .eq('seguidor_id', _meuIdObrigatorio);
    return linhas.map((l) => l['seguido_id'] as String).toList();
  }

  Future<List<PerfilResumo>> listarSeguidores(String usuarioId) async {
    final linhas = await _client
        .from('seguidores')
        .select('pessoa:perfis!seguidores_seguidor_fkey(id,nome,usuario,avatar_cor,avatar_url)')
        .eq('seguido_id', usuarioId)
        .order('criado_em', ascending: false);
    return _pessoasDe(linhas);
  }

  Future<List<PerfilResumo>> listarSeguindo(String usuarioId) async {
    final linhas = await _client
        .from('seguidores')
        .select('pessoa:perfis!seguidores_seguido_fkey(id,nome,usuario,avatar_cor,avatar_url)')
        .eq('seguidor_id', usuarioId)
        .order('criado_em', ascending: false);
    return _pessoasDe(linhas);
  }

  List<PerfilResumo> _pessoasDe(List<Map<String, dynamic>> linhas) {
    return linhas
        .map((l) => l['pessoa'])
        .whereType<Map>()
        .map((m) => PerfilResumo.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Busca simples por nome ou @usuario.
  Future<List<PerfilResumo>> buscarPessoas(String termo) async {
    // Vírgula, parênteses e % têm significado especial no filtro `or` do
    // PostgREST; tirá-los evita que o texto digitado vire parte da consulta.
    final limpo = termo.replaceAll(RegExp(r'[,()%*\\]'), ' ').trim();
    if (limpo.length < 2) return [];
    final linhas = await _client
        .from('perfis')
        .select('id,nome,usuario,avatar_cor,avatar_url')
        .or('nome.ilike.%$limpo%,usuario.ilike.%$limpo%')
        .order('nome', ascending: true)
        .limit(30);
    return linhas.map(PerfilResumo.fromMap).toList();
  }

  /// Pesquisa pelo @usuário (o "@" digitado é ignorado). Usada na barra de
  /// pesquisa do feed quando o texto começa com "@".
  Future<List<PerfilResumo>> buscarPessoasPorUsuario(String termo) async {
    final limpo = termo
        .replaceAll('@', '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (limpo.isEmpty) return [];
    final linhas = await _client
        .from('perfis')
        .select('id,nome,usuario,avatar_cor,avatar_url')
        .ilike('usuario', '%${limpo.replaceAll('_', '\\_')}%')
        .order('usuario', ascending: true)
        .limit(30);
    return linhas.map(PerfilResumo.fromMap).toList();
  }

  /// O @ está livre (ou já é meu)? A garantia final é o índice único do banco;
  /// esta consulta só avisa antes de salvar.
  Future<bool> usuarioDisponivel(String usuario) async {
    final linha = await _client
        .from('perfis')
        .select('id')
        .eq('usuario', usuario)
        .neq('id', _meuIdObrigatorio)
        .maybeSingle();
    return linha == null;
  }

  /// Erro por falta de conexão (e não por recusa do servidor). Esses casos não
  /// são falhas: o que a pessoa fez fica na fila e é reenviado depois.
  static bool ehErroDeRede(Object erro) {
    if (erro is SocketException || erro is TimeoutException) return true;
    if (erro is AuthRetryableFetchException) return true;
    final texto = erro.toString();
    return texto.contains('SocketException') ||
        texto.contains('ClientException') ||
        texto.contains('Failed host lookup') ||
        texto.contains('XMLHttpRequest') ||
        texto.contains('Connection closed') ||
        texto.contains('Connection reset') ||
        texto.contains('Connection refused') ||
        texto.contains('Network is unreachable');
  }

  // ------------------------------------------------------------------- erros

  /// Converte erros técnicos em frases para a pessoa, como o AuthService faz.
  static String traduzirErro(Object erro) {
    if (erro is SocialException) return erro.mensagem;
    if (erro is PostgrestException) {
      switch (erro.code) {
        case '23505':
          return 'Esse nome de usuário já está em uso. Escolha outro.';
        case '23514':
          return 'Algum campo está fora do tamanho permitido.';
        case '42501':
          return 'Você não tem permissão para fazer isso.';
        case 'PGRST205':
        case 'PGRST202':
        case '42P01':
          return 'A parte social ainda não foi criada no Supabase. '
              'Rode o arquivo supabase/social_v1.sql.';
      }
      return erro.message;
    }
    if (erro is AuthException) return erro.message;
    final texto = erro.toString();
    if (texto.contains('SocketException') ||
        texto.contains('ClientException') ||
        texto.contains('Failed host lookup')) {
      return 'Sem conexão com a internet. Tente de novo quando estiver online.';
    }
    return 'Não foi possível concluir: $texto';
  }
}
