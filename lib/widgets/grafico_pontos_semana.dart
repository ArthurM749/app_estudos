import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficoPontosSemana extends StatelessWidget {
  final List<int> pontosPorDia;
  final int indiceHoje;
  final double altura;

  const GraficoPontosSemana({
    super.key,
    required this.pontosPorDia,
    required this.indiceHoje,
    this.altura = 180, // altura padrão
  });

  @override
  Widget build(BuildContext context) {
    final maxY = (pontosPorDia.reduce((a, b) => a > b ? a : b) + 20).toDouble();

    return SizedBox(
      height: altura,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY < 50 ? 50 : maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dias[value.toInt()],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: value.toInt() == indiceHoje
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: value.toInt() == indiceHoje
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade600,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            final isHoje = i == indiceHoje;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: pontosPorDia[i].toDouble(),
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  color: isHoje
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}