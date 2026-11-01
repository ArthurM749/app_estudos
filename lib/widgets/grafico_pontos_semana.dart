import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const _diasDaSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

/// Gráfico de colunas com os pontos ganhos em cada dia da semana
/// atual (segunda a domingo), com um rótulo acima mostrando o dia
/// selecionado (toque numa coluna pra trocar) e o total da semana —
/// igual ao "Qua: 0 pts" / "25 pts na semana" da referência.
///
/// [pontosPorDia] precisa ter exatamente 7 valores, na mesma ordem
/// dos dias (índice 0 = segunda). [indiceHoje] é o que começa
/// selecionado.
class GraficoPontosSemana extends StatefulWidget {
  final List<int> pontosPorDia;
  final int indiceHoje;

  const GraficoPontosSemana({
    super.key,
    required this.pontosPorDia,
    required this.indiceHoje,
  });

  @override
  State<GraficoPontosSemana> createState() => _GraficoPontosSemanaState();
}

class _GraficoPontosSemanaState extends State<GraficoPontosSemana> {
  late int _indiceSelecionado = widget.indiceHoje;

  @override
  void didUpdateWidget(covariant GraficoPontosSemana oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se o dia de hoje mudou (ex.: virou meia-noite) e a pessoa não
    // tinha escolhido outro dia manualmente, acompanha o novo hoje.
    if (oldWidget.indiceHoje != widget.indiceHoje &&
        _indiceSelecionado == oldWidget.indiceHoje) {
      _indiceSelecionado = widget.indiceHoje;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final totalSemana =
        widget.pontosPorDia.fold<int>(0, (soma, v) => soma + v);
    final maiorValor =
        widget.pontosPorDia.fold<int>(0, (maior, v) => v > maior ? v : maior);
    final double teto = maiorValor == 0 ? 10.0 : maiorValor * 1.25;
    final indiceValido =
        _indiceSelecionado.clamp(0, widget.pontosPorDia.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_diasDaSemana[indiceValido]}: ${widget.pontosPorDia[indiceValido]} pts',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '$totalSemana pts na semana',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cores.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: teto,
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.round()} pts',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                touchCallback: (evento, resposta) {
                  if (!evento.isInterestedForInteractions) return;
                  final indice = resposta?.spot?.touchedBarGroupIndex;
                  if (indice == null || indice < 0) return;
                  setState(() => _indiceSelecionado = indice);
                },
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (valor, meta) {
                      final indice = valor.toInt();
                      if (indice < 0 || indice >= _diasDaSemana.length) {
                        return const SizedBox.shrink();
                      }
                      final selecionado = indice == indiceValido;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _diasDaSemana[indice],
                          style: TextStyle(
                            fontWeight:
                                selecionado ? FontWeight.bold : FontWeight.normal,
                            color: selecionado ? cores.primary : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(7, (indice) {
                final valor = widget.pontosPorDia[indice].toDouble();
                final selecionado = indice == indiceValido;
                return BarChartGroupData(
                  x: indice,
                  barRods: [
                    BarChartRodData(
                      toY: valor,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                      color: selecionado
                          ? cores.primary
                          : cores.primary.withOpacity(0.35),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
