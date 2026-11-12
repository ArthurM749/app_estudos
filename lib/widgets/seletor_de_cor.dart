import 'package:flutter/material.dart';

import '../theme/app_cores.dart';
import '../theme/cores_de_escolha.dart';

/// Linha de bolinhas para escolher uma cor. Usada no projeto e no perfil.
///
/// [corAtual] é o valor ARGB escolhido (ou nulo). Se ele não estiver na lista
/// de opções (ex.: projeto antigo com uma cor que saiu da paleta), aparece como
/// "Atual" no começo para não ser perdido sem querer.
/// [permitirPadrao] mostra a opção "padrão do tema" (valor nulo), usada no avatar.
class SeletorDeCor extends StatelessWidget {
  final int? corAtual;
  final ValueChanged<int?> aoEscolher;
  final bool permitirPadrao;

  const SeletorDeCor({
    super.key,
    required this.corAtual,
    required this.aoEscolher,
    this.permitirPadrao = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    final foraDaLista = corAtual != null &&
        !opcoesDeCor.any((o) => o.cor.toARGB32() == corAtual);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (permitirPadrao)
          _Bolinha(
            nome: 'Padrão',
            cor: tokens.avatarFundo,
            selecionada: corAtual == null,
            aoTocar: () => aoEscolher(null),
          ),
        if (foraDaLista)
          _Bolinha(
            nome: 'Atual',
            cor: Color(corAtual!),
            selecionada: true,
            aoTocar: () => aoEscolher(corAtual),
          ),
        for (final opcao in opcoesDeCor)
          _Bolinha(
            nome: opcao.nome,
            cor: opcao.cor,
            selecionada: corAtual == opcao.cor.toARGB32(),
            aoTocar: () => aoEscolher(opcao.cor.toARGB32()),
          ),
      ],
    );
  }
}

class _Bolinha extends StatelessWidget {
  final String nome;
  final Color cor;
  final bool selecionada;
  final VoidCallback aoTocar;

  const _Bolinha({
    required this.nome,
    required this.cor,
    required this.selecionada,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    return Tooltip(
      message: nome,
      child: GestureDetector(
        onTap: aoTocar,
        child: Container(
          width: selecionada ? 40 : 34,
          height: selecionada ? 40 : 34,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
            // Borda sempre visível: sem ela o branco some no tema claro e o
            // preto some no tema escuro.
            border: Border.all(
              color: selecionada ? tokens.textoPrincipal : tokens.bordaForte,
              width: selecionada ? 2.5 : 1,
            ),
          ),
          child: selecionada
              ? Icon(
                  Icons.check,
                  size: 18,
                  color: cor.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}
