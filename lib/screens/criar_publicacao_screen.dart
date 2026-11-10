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
import '../widgets/titulo_secao.dart';

/// Nova publicação. Texto livre e, se a pessoa quiser, uma atividade de estudo
/// anexada. Nada aqui é publicado sem ela tocar em "Publicar": as atividades
/// só aparecem como opções, nunca saem sozinhas.
class CriarPublicacaoScreen extends StatefulWidget {
  const CriarPublicacaoScreen({super.key});

  @override
  State<CriarPublicacaoScreen> createState() => _CriarPublicacaoScreenState();
}

class _CriarPublicacaoScreenState extends State<CriarPublicacaoScreen> {
  final _textoController = TextEditingController();

  TipoPublicacao _tipo = TipoPublicacao.texto;
  Projeto? _projetoEscolhido;
  String? _conquistaEscolhida;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _textoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  bool _atividadeCompleta() {
    switch (_tipo) {
      case TipoPublicacao.texto:
        return true;
      case TipoPublicacao.projetoConcluido:
        return _projetoEscolhido != null;
      case TipoPublicacao.conquista:
        return _conquistaEscolhida != null;
      case TipoPublicacao.sequencia:
      case TipoPublicacao.evolucao:
        return true;
    }
  }

  bool _podePublicar() {
    if (_enviando || !_atividadeCompleta()) return false;
    return _tipo != TipoPublicacao.texto ||
        _textoController.text.trim().isNotEmpty;
  }

  Map<String, dynamic> _meta(AppState app) {
    switch (_tipo) {
      case TipoPublicacao.texto:
        return {};
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
    }
  }

  String _textoPadrao() {
    switch (_tipo) {
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
    if (!_podePublicar()) return;
    final app = context.read<AppState>();
    final social = context.read<SocialState>();
    final digitado = _textoController.text.trim();
    final conteudo = digitado.isEmpty ? _textoPadrao() : digitado;
    final meta = _meta(app);

    setState(() => _enviando = true);
    try {
      await social.publicar(conteudo: conteudo, tipo: _tipo, meta: meta);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarMensagem(context, SocialService.traduzirErro(e));
    }
  }

  void _trocarTipo(TipoPublicacao tipo) {
    setState(() {
      _tipo = tipo;
      _projetoEscolhido = null;
      _conquistaEscolhida = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tokens = context.coresApp;

    final projetosConcluidos = app.projetos
        .where((p) => (app.progressoPorProjeto[p.id] ?? 0) >= 100)
        .toList();
    final conquistasLiberadas = conquistasDisponiveis
        .where((c) => app.conquistasDesbloqueadas.contains(c.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nova publicação')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _textoController,
            maxLines: 6,
            minLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'O que você estudou ou aprendeu hoje?',
            ),
          ),
          const SizedBox(height: 16),
          const TituloSecao('Compartilhar uma atividade'),
          const SizedBox(height: 8),
          Text(
            'Opcional. Só o que você escolher aqui é publicado — nada do seu '
            'estudo vai para o feed sozinho.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: tokens.textoSecundario),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Só texto'),
                selected: _tipo == TipoPublicacao.texto,
                onSelected: (_) => _trocarTipo(TipoPublicacao.texto),
              ),
              ChoiceChip(
                label: const Text('Projeto concluído'),
                selected: _tipo == TipoPublicacao.projetoConcluido,
                onSelected: projetosConcluidos.isEmpty
                    ? null
                    : (_) => _trocarTipo(TipoPublicacao.projetoConcluido),
              ),
              ChoiceChip(
                label: const Text('Conquista'),
                selected: _tipo == TipoPublicacao.conquista,
                onSelected: conquistasLiberadas.isEmpty
                    ? null
                    : (_) => _trocarTipo(TipoPublicacao.conquista),
              ),
              ChoiceChip(
                label: const Text('Sequência'),
                selected: _tipo == TipoPublicacao.sequencia,
                onSelected: app.sequenciaDias <= 0
                    ? null
                    : (_) => _trocarTipo(TipoPublicacao.sequencia),
              ),
              ChoiceChip(
                label: const Text('Evolução'),
                selected: _tipo == TipoPublicacao.evolucao,
                onSelected: (_) => _trocarTipo(TipoPublicacao.evolucao),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._detalhesDaAtividade(app, projetosConcluidos, conquistasLiberadas),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _podePublicar() ? _publicar : null,
            icon: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  List<Widget> _detalhesDaAtividade(
    AppState app,
    List<Projeto> projetosConcluidos,
    List<Conquista> conquistasLiberadas,
  ) {
    final estiloLegenda = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: context.coresApp.textoSecundario);

    switch (_tipo) {
      case TipoPublicacao.texto:
        return const [];
      case TipoPublicacao.projetoConcluido:
        return [
          Text('Qual projeto?', style: estiloLegenda),
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
        ];
      case TipoPublicacao.conquista:
        return [
          Text('Qual conquista?', style: estiloLegenda),
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
        ];
      case TipoPublicacao.sequencia:
        return [
          Text('Será publicado: ${app.sequenciaDias} dias seguidos estudando.',
              style: estiloLegenda),
        ];
      case TipoPublicacao.evolucao:
        return [
          Text(
            'Será publicado: nível ${app.nivel} e ${app.pontosTotais} pontos.',
            style: estiloLegenda,
          ),
        ];
    }
  }
}
