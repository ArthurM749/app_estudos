import 'package:flutter/material.dart';

import '../theme/app_cores.dart';

const _nomesDosDias = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];
const _inicialDosDias = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

/// Versão pequena e minimalista do gráfico de pontos da semana, feita para o
/// perfil: sem eixos, sem grade, só sete barras finas e uma linha de resumo.
/// Toque numa barra para ver os pontos daquele dia.
///
/// O gráfico grande da Home continua sendo o [GraficoPontosSemana]; este aqui
/// reaproveita as mesmas cores (tokens `grafico*`) para os dois combinarem.
class GraficoSemanaMini extends StatefulWidget {
  /// Pontos de segunda a domingo (7 valores).
  final List<int> pontosPorDia;

  /// 0 = segunda ... 6 = domingo.
  final int indiceHoje;

  const GraficoSemanaMini({
    super.key,
    required this.pontosPorDia,
    required this.indiceHoje,
  });

  @override
  State<GraficoSemanaMini> createState() => _GraficoSemanaMiniState();
}

class _GraficoSemanaMiniState extends State<GraficoSemanaMini> {
  /// Largura máxima: o gráfico não precisa ocupar a tela toda do perfil.
  static const double _larguraMaxima = 240;
  static const double _alturaDasBarras = 44;
  static const double _alturaMinimaDaBarra = 3;

  late int _selecionado = widget.indiceHoje.clamp(0, 6).toInt();

  @override
  void didUpdateWidget(covariant GraficoSemanaMini antigo) {
    super.didUpdateWidget(antigo);
    // Virou o dia (ou a semana) e a pessoa não tinha escolhido outro: acompanha.
    if (antigo.indiceHoje != widget.indiceHoje &&
        _selecionado == antigo.indiceHoje) {
      _selecionado = widget.indiceHoje.clamp(0, 6).toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    final tema = Theme.of(context).textTheme;
    final pontos = widget.pontosPorDia;
    final total = pontos.fold<int>(0, (soma, v) => soma + v);
    final maior = pontos.fold<int>(0, (m, v) => v > m ? v : m);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _larguraMaxima),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_nomesDosDias[_selecionado]}: ${pontos[_selecionado]} pts',
                style: tema.bodySmall?.copyWith(
                  color: tokens.textoPrincipal,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$total na semana',
                style: tema.bodySmall?.copyWith(color: tokens.graficoRotulo),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _Coluna(
                    inicial: _inicialDosDias[i],
                    rotuloAcessivel:
                        '${_nomesDosDias[i]}, ${pontos[i]} pontos',
                    proporcao: maior == 0 ? 0 : pontos[i] / maior,
                    selecionado: i == _selecionado,
                    alturaDasBarras: _alturaDasBarras,
                    alturaMinima: _alturaMinimaDaBarra,
                    aoTocar: () => setState(() => _selecionado = i),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Coluna extends StatelessWidget {
  final String inicial;
  final String rotuloAcessivel;
  final double proporcao;
  final bool selecionado;
  final double alturaDasBarras;
  final double alturaMinima;
  final VoidCallback aoTocar;

  const _Coluna({
    required this.inicial,
    required this.rotuloAcessivel,
    required this.proporcao,
    required this.selecionado,
    required this.alturaDasBarras,
    required this.alturaMinima,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    final altura = alturaMinima + (alturaDasBarras - alturaMinima) * proporcao;

    return Semantics(
      button: true,
      selected: selecionado,
      label: rotuloAcessivel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: aoTocar,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: alturaDasBarras,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: 8,
                  height: altura,
                  decoration: BoxDecoration(
                    color: selecionado
                        ? tokens.graficoBarraSelecionada
                        : tokens.graficoBarra,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              inicial,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                color: selecionado
                    ? tokens.graficoRotuloSelecionado
                    : tokens.graficoRotulo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
