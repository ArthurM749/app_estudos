import 'package:flutter/material.dart';

import '../theme/app_cores.dart';

/// Título de seção com um pequeno sublinhado, no estilo de cabeçalho de caderno.
/// Usado nas telas de perfil para separar as partes sem pesar o visual.
class TituloSecao extends StatelessWidget {
  final String texto;

  const TituloSecao(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texto,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 2,
          decoration: BoxDecoration(
            color: context.coresApp.marcador,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
