import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/database_helper.dart';
import '../data/regras_pontos.dart';
import '../models/item.dart';
import '../utils/formatadores.dart';
import '../widgets/cabecalho_da_aba.dart';
import '../widgets/dialogo_projeto.dart';
import '../widgets/erro_de_carregamento.dart';
import '../widgets/grafico_pontos_semana.dart';
import 'anotacao_editor_screen.dart';

/// Tela de Início: saudação com avatar, sequência de dias + pontos
/// de hoje, nível, gráfico semanal interativo e atalhos pros
/// projetos e anotações mais recentes.
class HomeScreen extends StatelessWidget {
  final VoidCallback? aoTocarProjetos;
  final VoidCallback? aoTocarAnotacoes;
  final VoidCallback? aoTocarConfiguracoes;

  const HomeScreen({
    super.key,
    this.aoTocarProjetos,
    this.aoTocarAnotacoes,
    this.aoTocarConfiguracoes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, appState, _) {
            if (appState.carregando) {
              return const Center(child: CircularProgressIndicator());
            }
            if (appState.erro != null) {
              return ErroDeCarregamento(mensagem: appState.erro!);
            }

            final nome = appState.nomeUsuario ?? 'Estudante';
            final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';
            final pontosDentroDoNivel =
                RegrasDePontos.pontosDentroDoNivelAtual(appState.pontosTotais);
            final pontosParaProximo =
                RegrasDePontos.pontosParaProximoNivel(appState.nivel);
            final hoje = DateTime.now();
            final indiceHoje = hoje.weekday - 1;

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                CabecalhoDaAba(
                  titulo: 'Olá, $nome!',
                  subtitulo: formatarDataCompleta(hoje),
                  leading: CircleAvatar(
                    radius: 22,
                    child: Text(
                      inicial,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  aoTocarConfiguracoes: aoTocarConfiguracoes,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: [
                      _CartaoSequenciaEPontosHoje(
                        sequenciaDias: appState.sequenciaDias,
                        pontosHoje: appState.pontosHoje,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Nível ${appState.nivel} · ${RegrasDePontos.tituloDoNivel(appState.nivel)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text('$pontosDentroDoNivel/$pontosParaProximo pts'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pontosParaProximo == 0
                                      ? 0
                                      : pontosDentroDoNivel / pontosParaProximo,
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pontos da semana',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              GraficoPontosSemana(
                                pontosPorDia: appState.pontosPorDia,
                                indiceHoje: indiceHoje,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AnotacaoEditorScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.note_add_outlined),
                              label: const Text('Nova anotação'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => abrirDialogoProjeto(context),
                              icon: const Icon(Icons.create_new_folder_outlined),
                              label: const Text('Novo projeto'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SecaoComVerTudo(
                        titulo: 'Projetos em andamento',
                        aoTocarVerTudo:
                            appState.projetos.isEmpty ? null : aoTocarProjetos,
                      ),
                      const SizedBox(height: 8),
                      if (appState.projetos.isEmpty)
                        const _CartaoVazio(
                          mensagem: 'Nenhum projeto ainda. Crie o primeiro acima.',
                        )
                      else
                        ...appState.projetos.take(3).map((projeto) {
                          final progresso =
                              appState.progressoPorProjeto[projeto.id] ?? 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: Color(projeto.cor)),
                              title: Text(projeto.nome),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progresso / 100,
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              trailing: Text('$progresso%'),
                              onTap: aoTocarProjetos,
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                      _SecaoComVerTudo(
                        titulo: 'Anotações recentes',
                        aoTocarVerTudo: aoTocarAnotacoes,
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<Item>>(
                        future: DatabaseHelper.instance.listarAnotacoesRecentes(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final recentes = snapshot.data!;
                          if (recentes.isEmpty) {
                            return const _CartaoVazio(
                              mensagem:
                                  'Nenhuma anotação ainda. Toque em "Nova anotação" para começar.',
                            );
                          }
                          return Column(
                            children: recentes.map((item) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: Icon(
                                    item.visibilidade == Visibilidade.publica
                                        ? Icons.public
                                        : Icons.lock_outline,
                                    size: 20,
                                  ),
                                  title: Text(item.titulo),
                                  subtitle: item.conteudo.isEmpty
                                      ? null
                                      : Text(
                                          item.conteudo,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AnotacaoEditorScreen(itemExistente: item),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SecaoComVerTudo extends StatelessWidget {
  final String titulo;
  final VoidCallback? aoTocarVerTudo;

  const _SecaoComVerTudo({required this.titulo, this.aoTocarVerTudo});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (aoTocarVerTudo != null)
          TextButton(onPressed: aoTocarVerTudo, child: const Text('Ver todos')),
      ],
    );
  }
}

class _CartaoVazio extends StatelessWidget {
  final String mensagem;
  const _CartaoVazio({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          mensagem,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _CartaoSequenciaEPontosHoje extends StatelessWidget {
  final int sequenciaDias;
  final int pontosHoje;

  const _CartaoSequenciaEPontosHoje({
    required this.sequenciaDias,
    required this.pontosHoje,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      color: cores.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _ValorDoCartao(
                icone: Icons.local_fire_department,
                valor: '$sequenciaDias',
                rotulo: sequenciaDias == 1 ? 'dia seguido' : 'dias seguidos',
                corTexto: cores.onPrimary,
              ),
            ),
            Container(width: 1, height: 36, color: cores.onPrimary.withOpacity(0.3)),
            Expanded(
              child: _ValorDoCartao(
                icone: Icons.bolt,
                valor: '$pontosHoje',
                rotulo: 'pontos hoje',
                corTexto: cores.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValorDoCartao extends StatelessWidget {
  final IconData icone;
  final String valor;
  final String rotulo;
  final Color corTexto;

  const _ValorDoCartao({
    required this.icone,
    required this.valor,
    required this.rotulo,
    required this.corTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icone, color: corTexto),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(color: corTexto, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(rotulo, style: TextStyle(color: corTexto, fontSize: 12)),
      ],
    );
  }
}
