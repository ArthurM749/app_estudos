import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Uma cor que a pessoa pode escolher (projeto ou avatar), com nome para
/// leitores de tela e dica de toque.
class OpcaoDeCor {
  final String nome;
  final Color cor;

  const OpcaoDeCor(this.nome, this.cor);
}

/// Cores oferecidas ao criar um projeto e ao escolher a cor do perfil.
/// Para trocar, adicionar ou remover uma cor basta mexer nesta lista: os dois
/// seletores usam a mesma. As cores já gravadas continuam valendo (o app guarda
/// o valor da cor, não o nome).
///
/// O azul é próprio (mais vivo que o `projectBlue` da paleta, que é um azul
/// acinzentado e ficava parecido com o turquesa).
const opcoesDeCor = <OpcaoDeCor>[
  OpcaoDeCor('Azul', Color(0xFF2F6BD8)),
  OpcaoDeCor('Vermelho', AppPalette.projectRed),
  OpcaoDeCor('Amarelo', AppPalette.projectYellow),
  OpcaoDeCor('Verde', AppPalette.projectGreen),
  OpcaoDeCor('Laranja', AppPalette.projectOrange),
  OpcaoDeCor('Roxo', AppPalette.projectPurple),
  OpcaoDeCor('Rosa', AppPalette.projectPink),
  OpcaoDeCor('Turquesa', AppPalette.projectTeal),
  OpcaoDeCor('Marrom', Color(0xFF8B5E3C)),
  OpcaoDeCor('Cinza', Color(0xFF8A8F98)),
  OpcaoDeCor('Branco', Color(0xFFFFFFFF)),
  OpcaoDeCor('Preto', Color(0xFF111111)),
];
