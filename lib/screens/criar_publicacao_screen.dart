import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/regras_pontos.dart';
import '../data/social_service.dart';
import '../data/social_state.dart';
import '../models/conquista.dart';
import '../models/projeto.dart';
import '../models/publicacao.dart';
import '../theme/app_cores.dart';
import '../utils/mensagens.dart';
import '../widgets/cartao_publicacao.dart' show iconeDaPublicacao;
import 'anotacao_editor_screen.dart';

/// Ponto único para publicar algo na comunidade. Cinco caminhos:
///  - Texto ou anotação: abre o mesmo editor das Anotações (uma anotação é
///    privada até a pessoa publicá-la lá, com confirmação);
///  - Conquista, projeto concluído, sequência e evolução: compartilham uma
///    atividade de estudo. Nada sai sem a pessoa conferir e confirmar.
class CriarPublicacaoScreen extends StatefulWidget {
  const CriarPublicacaoScreen({super.key});

  @override
  State<CriarPublicacaoScreen> createState() => _CriarPublicacaoScreenState();
}

class _CriarPublicacaoScreenState extends State<CriarPublicacaoScreen> {
  final _mensagemController = TextEditingController();

  /// Nulo = ainda escolhendo o que compartilhar.
  TipoPublicacao? _tipo;
  Projeto? _projetoEscolhido;
  String? _conquistaEscolhida;
  bool _enviando = false;

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  void _escolher(TipoPublicacao tipo) {
    if (tipo == TipoPublicacao.texto) {
      // Mesmo editor das Anotações: não existe um segundo "editor de post".
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AnotacaoEditorScreen()),
      );
      return;
    }
    setState(() {
      _tipo = tipo;
      _projetoEscolhido = null;
      _conquistaEscolhida = null;
      _mensagemController.clear();
    });
  }

  bool _atividadeCompleta() {
    switch (_tipo) {
      case TipoPublicacao.projetoConcluido:
        return _projetoEscolhido != null;
      case TipoPublicacao.conquista:
        return _conquistaEscolhida != null;
      case TipoPublicacao.sequencia:
      case TipoPublicacao.evolucao:
        return true;
      case TipoPublicacao.texto:
      case null:
        return false;
    }
  }

  /// Título que fica gravado na publicação (é o que a pesquisa do feed acha).
  String _tituloPublico(AppState app) {
    switch (_tipo!) {
      case TipoPublicacao.projetoConcluido:
        return 'Projeto concluído: ${_projetoEscolhido!.nome}';
      case TipoPublicacao.conquista:
        final c = conquistasDisponiveis
            .firstWhere((c) => c.id == _conquistaEscolhida);
        return 'Conquista desbloqueada: ${c.nome}';
      case TipoPublicacao.sequencia:
        return 'Sequência de ${app.sequenciaDias} dias';
      case TipoPublicacao.evolucao:
        return 'Evolução: nível ${app.nivel}';
      case TipoPublicacao.texto:
        return '';
    }
  }

  /// Texto do emblema (título e detalhe) que aparece no cartão do feed.
  Map<String, dynamic> _meta(AppState app) {
    switch (_tipo!) {
      case TipoPublicacao.projetoConcluido:
        return {
          'titulo': _projetoEscolhido!.nome,
          'detalhe': 'Projeto concluído · 100%',
        };
      case TipoPublicacao.conquista:
        final conquista = conquistasDisponiveis
            .firstWhere((c) => c.id == _conquistaEscolhida);
        return {
          'titulo': conquista.nome,
          'detalhe': conquista.descricao,
          'conquista_id': conquista.id,
        };
      case TipoPublicacao.sequencia:
        return {
          'titulo': '${app.sequenciaDias} dias seguidos',
          'detalhe': 'Sequência de estudos',
        };
      case TipoPublicacao.evolucao:
        return {
          'titulo':
              'Nível ${app.nivel} · ${RegrasDePontos.tituloDoNivel(app.nivel)}',
          'detalhe': '${app.pontosTotais} pontos no total',
        };
      case TipoPublicacao.texto:
        return {};
    }
  }

  String _textoPadrao() {
    switch (_tipo!) {
      case TipoPublicacao.projetoConcluido:
        return 'Concluí um projeto!';
      case TipoPublicacao.conquista:
        return 'Desbloqueei uma conquista!';
      case TipoPublicacao.sequencia:
        return 'Mantendo o ritmo de estudos.';
      case TipoPublicacao.evolucao:
        return 'Evoluindo nos estudos.';
      case TipoPublicacao.texto:
        return '';
    }
  }

  Future<void> _publicar() async {
    if (_enviando || !_atividadeCompleta()) return;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Compartilhar no feed?'),
        content: const Text(
          'Essa atividade vai aparecer no feed e no seu perfil para todas as '
          'pessoas do app. Você pode apagá-la depois pelo menu da publicação.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Compartilhar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    final app = context.read<AppState>();
    final social = context.read<SocialState>();
    final digitado = _mensagemController.text.trim();

    setState(() => _enviando = true);
    try {
      final enviada = await social.publicar(
        titulo: _tituloPublico(app),
        conteudo: digitado.isEmpty ? _textoPadrao() : digitado,
        tipo: _tipo!,
        meta: _meta(app),
      );
      if (!mounted) return;
      if (!enviada) {
        // Sem internet: ficou guardada no aparelho e sai sozinha depois.
        mostrarMensagem(context,
            'Salvo no aparelho. Será publicado quando houver internet.');
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarMensagem(context, SocialService.traduzirErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return PopScope(
      // No segundo passo, voltar leva à lista de opções em vez de sair da tela.
      canPop: _tipo == null,
      onPopInvokedWithResult: (jaSaiu, _) {
        if (!jaSaiu) setState(() => _tipo = null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tipo == null ? 'Nova publicação' : _tituloDoPasso()),
        ),
        body: _tipo == null ? _opcoes(app) : _passoDaAtividade(app),
      ),
    );
  }

  String _tituloDoPasso() {
    switch (_tipo!) {
      case TipoPublicacao.projetoConcluido:
        return 'Projeto concluído';
      case TipoPublicacao.conquista:
        return 'Conquista desbloqueada';
      case TipoPublicacao.sequencia:
        return 'Sequência de dias';
      case TipoPublicacao.evolucao:
        return 'Evolução nos estudos';
      case TipoPublicacao.texto:
        return 'Nova publicação';
    }
  }

  // ------------------------------------------------------------ 1º passo

  Widget _opcoes(AppState app) {
    final tokens = context.coresApp;
    final temProjetoConcluido = app.projetos
        .any((p) => (app.progressoPorProjeto[p.id] ?? 0) >= 100);
    final temConquista = app.conquistasDesbloqueadas.isNotEmpty;

    Widget opcao({
      required IconData icone,
      required String titulo,
      required String descricao,
      required TipoPublicacao tipo,
      bool habilitada = true,
    }) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          enabled: habilitada,
          leading: Icon(icone,
              color: habilitada ? tokens.iconeDestaque : tokens.iconeSuave),
          title: Text(titulo),
          subtitle: Text(descricao),
          trailing: const Icon(Icons.chevron_right),
          onTap: habilitada ? () => _escolher(tipo) : null,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'O que você quer publicar? Nada vai para o feed sem a sua '
          'confirmação.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: tokens.textoSecundario),
        ),
        const SizedBox(height: 16),
        opcao(
          icone: Icons.edit_note,
          titulo: 'Texto ou anotação',
          descricao: 'Escreva um artigo, uma ideia ou algo que aprendeu. '
              'Abre o editor de anotações.',
          tipo: TipoPublicacao.texto,
        ),
        opcao(
          icone: iconeDaPublicacao(TipoPublicacao.conquista, null),
          titulo: 'Conquista desbloqueada',
          descricao: temConquista
              ? 'Mostre uma conquista que você ganhou.'
              : 'Você ainda não desbloqueou conquistas.',
          tipo: TipoPublicacao.conquista,
          habilitada: temConquista,
        ),
        opcao(
          icone: iconeDaPublicacao(TipoPublicacao.projetoConcluido, null),
          titulo: 'Projeto concluído',
          descricao: temProjetoConcluido
              ? 'Compartilhe um projeto que chegou a 100%.'
              : 'Nenhum projeto chegou a 100% ainda.',
          tipo: TipoPublicacao.projetoConcluido,
          habilitada: temProjetoConcluido,
        ),
        opcao(
          icone: iconeDaPublicacao(TipoPublicacao.sequencia, null),
          titulo: 'Sequência de dias',
          descricao: app.sequenciaDias > 0
              ? '${app.sequenciaDias} dias seguidos estudando.'
              : 'Estude hoje para começar uma sequência.',
          tipo: TipoPublicacao.sequencia,
          habilitada: app.sequenciaDias > 0,
        ),
        opcao(
          icone: iconeDaPublicacao(TipoPublicacao.evolucao, null),
          titulo: 'Evolução nos estudos',
          descricao:
              'Nível ${app.nivel} · ${app.pontosTotais} pontos no total.',
          tipo: TipoPublicacao.evolucao,
        ),
      ],
    );
  }

  // ------------------------------------------------------------ 2º passo

  Widget _passoDaAtividade(AppState app) {
    final tokens = context.coresApp;
    final tema = Theme.of(context).textTheme;
    final projetosConcluidos = app.projetos
        .where((p) => (app.progressoPorProjeto[p.id] ?? 0) >= 100)
        .toList();
    final conquistasLiberadas = conquistasDisponiveis
        .where((c) => app.conquistasDesbloqueadas.contains(c.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_tipo == TipoPublicacao.projetoConcluido) ...[
          Text('Qual projeto?', style: tema.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final projeto in projetosConcluidos)
                ChoiceChip(
                  label: Text(projeto.nome),
                  selected: _projetoEscolhido?.id == projeto.id,
                  onSelected: (_) =>
                      setState(() => _projetoEscolhido = projeto),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_tipo == TipoPublicacao.conquista) ...[
          Text('Qual conquista?', style: tema.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final conquista in conquistasLiberadas)
                ChoiceChip(
                  label: Text(conquista.nome),
                  selected: _conquistaEscolhida == conquista.id,
                  onSelected: (_) =>
                      setState(() => _conquistaEscolhida = conquista.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_atividadeCompleta()) ...[
          Text('Como vai aparecer', style: tema.titleSmall),
          const SizedBox(height: 8),
          _Previa(
            icone: iconeDaPublicacao(_tipo!, _conquistaEscolhida),
            titulo: _meta(app)['titulo'] as String,
            detalhe: _meta(app)['detalhe'] as String,
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _mensagemController,
          maxLines: 4,
          minLines: 2,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Quer dizer algo? (opcional)',
            hintText: _textoPadrao(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Só o que aparece acima é compartilhado — suas tarefas e anotações '
          'continuam privadas.',
          style: tema.bodySmall?.copyWith(color: tokens.textoSecundario),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: (_atividadeCompleta() && !_enviando) ? _publicar : null,
          icon: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: const Text('Compartilhar'),
        ),
      ],
    );
  }
}

/// Pré-visualização do emblema da atividade, igual ao do cartão do feed.
class _Previa extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String detalhe;

  const _Previa({
    required this.icone,
    required this.titulo,
    required this.detalhe,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    final tema = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.emblemaFundo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icone, color: tokens.emblemaIcone, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: tema.titleSmall?.copyWith(
                    color: tokens.emblemaTexto,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  detalhe,
                  style: tema.bodySmall?.copyWith(color: tokens.emblemaTexto),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
