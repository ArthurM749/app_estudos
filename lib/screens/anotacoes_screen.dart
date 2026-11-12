import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/database_helper.dart';
import '../data/social_state.dart';
import '../models/item.dart';
import '../theme/app_cores.dart';
import '../widgets/cabecalho_da_aba.dart';
import 'anotacao_editor_screen.dart';

enum _FiltroProjeto { todas, semProjeto, projeto }

class AnotacoesScreen extends StatefulWidget {
  final VoidCallback? aoTocarConfiguracoes;

  const AnotacoesScreen({super.key, this.aoTocarConfiguracoes});

  @override
  State<AnotacoesScreen> createState() => _AnotacoesScreenState();
}

class _AnotacoesScreenState extends State<AnotacoesScreen> {
  final _buscaController = TextEditingController();
  String _busca = '';
  _FiltroProjeto _filtro = _FiltroProjeto.todas;
  int? _projetoFiltradoId;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<List<Item>> _carregar() {
    return DatabaseHelper.instance.listarAnotacoes(
      apenasSemProjeto: _filtro == _FiltroProjeto.semProjeto,
      projetoId: _filtro == _FiltroProjeto.projeto ? _projetoFiltradoId : null,
      busca: _busca,
    );
  }

  Future<void> _novaAnotacao(BuildContext context) async {
    final criou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AnotacaoEditorScreen(
          projetoIdInicial:
              _filtro == _FiltroProjeto.projeto ? _projetoFiltradoId : null,
        ),
      ),
    );
    if (criou == true && mounted) setState(() {});
  }

  Future<void> _editar(BuildContext context, Item item) async {
    final editou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AnotacaoEditorScreen(itemExistente: item),
      ),
    );
    if (editou == true && mounted) setState(() {});
  }

  Future<void> _excluir(BuildContext context, Item item) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir anotação?'),
        content: Text(
          item.querPublicada
              ? 'Isso vai apagar "${item.titulo}" do aparelho e também a '
                  'publicação no feed (sem internet, ela sai quando voltar). '
                  'Não pode ser desfeito.'
              : 'Isso vai apagar "${item.titulo}" e não pode ser desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;
    // Some do aparelho na hora; a publicação (se houver) sai da nuvem agora ou
    // quando a internet voltar.
    await context
        .read<SocialState>()
        .excluirAnotacao(item, context.read<AppState>());
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final projetos = context.watch<AppState>().projetos;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CabecalhoDaAba(
              titulo: 'Anotações',
              aoTocarConfiguracoes: widget.aoTocarConfiguracoes,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _buscaController,
                decoration: InputDecoration(
                  hintText: 'Buscar anotações...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: _busca.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _buscaController.clear();
                            setState(() => _busca = '');
                          },
                        ),
                ),
                onChanged: (valor) => setState(() => _busca = valor),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _filtro == _FiltroProjeto.todas,
                    onSelected: (_) =>
                        setState(() => _filtro = _FiltroProjeto.todas),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Sem projeto'),
                    selected: _filtro == _FiltroProjeto.semProjeto,
                    onSelected: (_) =>
                        setState(() => _filtro = _FiltroProjeto.semProjeto),
                  ),
                  for (final projeto in projetos) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: CircleAvatar(
                        backgroundColor: Color(projeto.cor),
                        radius: 6,
                      ),
                      label: Text(projeto.nome),
                      selected: _filtro == _FiltroProjeto.projeto &&
                          _projetoFiltradoId == projeto.id,
                      onSelected: (_) => setState(() {
                        _filtro = _FiltroProjeto.projeto;
                        _projetoFiltradoId = projeto.id;
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Item>>(
                future: _carregar(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final anotacoes = snapshot.data!;
                  if (anotacoes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _busca.isEmpty
                              ? 'Nenhuma anotação aqui ainda.'
                              : 'Nada encontrado para "$_busca".',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }
                  final projetosPorId = {for (final p in projetos) p.id: p};
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: anotacoes.length,
                    itemBuilder: (context, indice) {
                      final item = anotacoes[indice];
                      final projetoDoItem = projetosPorId[item.projetoId];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            item.aguardandoEnvio
                                ? Icons.cloud_upload_outlined
                                : (item.querPublicada
                                    ? Icons.public
                                    : Icons.lock_outline),
                            size: 20,
                            color: item.querPublicada
                                ? context.coresApp.iconeDestaque
                                : context.coresApp.iconeSuave,
                          ),
                          title: Text(item.titulo),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.conteudo.isNotEmpty)
                                Text(
                                  item.conteudo,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (projetoDoItem != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 4,
                                        backgroundColor:
                                            Color(projetoDoItem.cor),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        projetoDoItem.nome,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _excluir(context, item),
                          ),
                          onTap: () => _editar(context, item),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _novaAnotacao(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova anotação'),
      ),
    );
  }
}
