import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const _diasDaSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

/// Gráfico de colunas com os pontos ganhos em cada dia da semana
/// atual (segunda a domingo).
///
/// [pontosPorDia] precisa ter exatamente 7 valores, na mesma ordem
/// dos dias (índice 0 = segunda). [indiceHoje] destaca a coluna do
/// dia de hoje.
class GraficoPontosSemana extends StatelessWidget {
  final List<int> pontosPorDia;
  final int indiceHoje;

  const GraficoPontosSemana({
    super.key,
    required this.pontosPorDia,
    required this.indiceHoje,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final maiorValor =
        pontosPorDia.fold<int>(0, (maior, v) => v > maior ? v : maior);
    final double teto = maiorValor == 0 ? 10.0 : maiorValor * 1.25;

    return SizedBox(
      height: 180,
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
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  final ehHoje = indice == indiceHoje;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _diasDaSemana[indice],
                      style: TextStyle(
                        fontWeight: ehHoje ? FontWeight.bold : FontWeight.normal,
                        color: ehHoje ? cores.primary : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(7, (indice) {
            final valor = pontosPorDia[indice].toDouble();
            final ehHoje = indice == indiceHoje;
            return BarChartGroupData(
              x: indice,
              barRods: [
                BarChartRodData(
                  toY: valor,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                  color: ehHoje ? cores.primary : cores.primary.withOpacity(0.35),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
