import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_cores.dart';

const _diasDaSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

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

    if (oldWidget.indiceHoje != widget.indiceHoje &&
        _indiceSelecionado == oldWidget.indiceHoje) {
      _indiceSelecionado = widget.indiceHoje;
    }
  }

  int _intervaloLimpo(int maiorValor) {
    const candidatos = [5, 10, 20, 25, 50, 100, 200, 250, 500, 1000];
    final alvo = maiorValor * 1.25;
    for (final candidato in candidatos) {
      if (candidato * 5 >= alvo) return candidato;
    }
    return 1000;
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.coresApp;
    final totalSemana = widget.pontosPorDia.fold<int>(0, (soma, v) => soma + v);
    final maiorValor =
        widget.pontosPorDia.fold<int>(0, (maior, v) => v > maior ? v : maior);

    final intervalo = _intervaloLimpo(maiorValor);
    final double teto = maiorValor == 0
        ? intervalo.toDouble()
        : (((maiorValor * 1.25) / intervalo).ceil() * intervalo).toDouble();
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
                    color: cores.graficoRotulo,
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
                  getTooltipColor: (_) => cores.graficoTooltipFundo,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.round()} pts',
                      TextStyle(
                        color: cores.graficoTooltipTexto,
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
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: intervalo.toDouble(),
                    getTitlesWidget: (valor, meta) {
                      return Text(
                        valor.round().toString(),
                        style: TextStyle(
                            color: cores.graficoRotulo, fontSize: 11),
                      );
                    },
                  ),
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
                            fontWeight: selecionado
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selecionado
                                ? cores.graficoRotuloSelecionado
                                : cores.graficoRotulo,
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
                          ? cores.graficoBarraSelecionada
                          : cores.graficoBarra,
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
