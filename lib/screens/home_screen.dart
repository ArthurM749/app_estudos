import 'package:app_estudos/screens/progresso_screen.dart';
import 'package:app_estudos/screens/projetos_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/regras_pontos.dart';
import '../widgets/erro_de_carregamento.dart';
import '../widgets/grafico_pontos_semana.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0 = Semana | 1 = Mês | 2 = Tudo
  int _filtroSelecionado = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.carregando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (appState.erro != null) {
            return ErroDeCarregamento(mensagem: appState.erro!);
          }

          final faltamParaProximoNivel =
              RegrasDePontos.pontosParaProximoNivel(appState.nivel);
          final variacao = appState.pontosHoje - appState.pontosOntem;
          final indiceHoje = DateTime.now().weekday - 1;

          // Título do gráfico muda conforme o filtro
          final tituloGrafico = switch (_filtroSelecionado) {
            0 => 'Pontos da semana',
            1 => 'Pontos do mês',
            _ => 'Pontos totais',
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (appState.nomeUsuario != null) ...[
                Text(
                  'Olá, ${appState.nomeUsuario}!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
              ],

              // ===== CARD SEQUÊNCIA + NÍVEL =====
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Sequência
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sequência',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department,
                                    color: Colors.orange, size: 22),
                                const SizedBox(width: 6),
                                Text(
                                  '${appState.diasSequencia} dias',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Container(
                        height: 45,
                        width: 1,
                        color: Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),

                      // Nível
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nível ${appState.nivel}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text('${appState.pontosTotais} pontos no total'),
                            const SizedBox(height: 2),
                            Text(
                              'Faltam $faltamParaProximoNivel pontos para o próximo nível',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===== BOTÕES DE FILTRO =====
              Row(
                children: [
                  _BotaoFiltro(
                    texto: 'Semana',
                    selecionado: _filtroSelecionado == 0,
                    onTap: () => setState(() => _filtroSelecionado = 0),
                  ),
                  const SizedBox(width: 8),
                  _BotaoFiltro(
                    texto: 'Mês',
                    selecionado: _filtroSelecionado == 1,
                    onTap: () => setState(() => _filtroSelecionado = 1),
                  ),
                  const SizedBox(width: 8),
                  _BotaoFiltro(
                    texto: 'Tudo',
                    selecionado: _filtroSelecionado == 2,
                    onTap: () => setState(() => _filtroSelecionado = 2),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ===== GRÁFICO =====
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tituloGrafico,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),

                      // Por enquanto todos os filtros usam os dados da semana
                      // (quando você tiver dados de mês/tudo no AppState, é só trocar aqui)
                      GraficoPontosSemana(
                        pontosPorDia: appState.pontosPorDia,
                        indiceHoje: indiceHoje,
                        altura: 140,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===== HOJE / ONTEM =====
              Row(
                children: [
                  Expanded(
                    child: _CartaoPontos(
                      titulo: 'Hoje',
                      valor: appState.pontosHoje,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CartaoPontos(
                      titulo: 'Ontem',
                      valor: appState.pontosOntem,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Variação
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    variacao >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: variacao >= 0 ? Colors.green : Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    variacao == 0
                        ? 'Igual a ontem'
                        : '${variacao > 0 ? '+' : ''}$variacao em relação a ontem',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ===== ESTA SEMANA =====
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProgressoScreen()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 231, 235, 243),
                    border: Border.all(
                      color: const Color.fromARGB(255, 75, 73, 133),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.date_range),
                    title: const Text(
                      'Esta semana',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '${appState.pontosSemana} pts',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ===== PROJETOS ATIVOS =====
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProjetosScreen()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 224, 198),
                    border: Border.all(
                      color: const Color(0xFFC56F29),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text(
                      'Projetos ativos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '${appState.projetos.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BotaoFiltro extends StatelessWidget {
  final String texto;
  final bool selecionado;
  final VoidCallback onTap;

  const _BotaoFiltro({
    required this.texto,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selecionado
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              texto,
              style: TextStyle(
                color: selecionado ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaoPontos extends StatelessWidget {
  final String titulo;
  final int valor;

  const _CartaoPontos({
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(titulo, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '$valor',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}