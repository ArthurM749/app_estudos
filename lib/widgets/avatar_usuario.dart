import 'package:flutter/material.dart';

import '../theme/app_cores.dart';

/// Avatar com a inicial do nome. A foto fica para uma próxima fase (exigiria o
/// Storage do Supabase); por enquanto a pessoa escolhe uma cor.
class AvatarUsuario extends StatelessWidget {
  final String nome;

  /// Cor ARGB escolhida no perfil; nula usa a cor padrão do tema.
  final int? cor;
  final double raio;
  final VoidCallback? aoTocar;

  const AvatarUsuario({
    super.key,
    required this.nome,
    this.cor,
    this.raio = 20,
    this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    final fundo = cor != null ? Color(cor!) : tokens.avatarFundo;
    // Mesmo critério do seletor de cor dos projetos: texto escuro em fundo claro.
    final textoSobreFundo = cor != null
        ? (fundo.computeLuminance() > 0.45 ? Colors.black : Colors.white)
        : tokens.avatarTexto;
    final nomeLimpo = nome.trim();
    final inicial = nomeLimpo.isEmpty ? '?' : nomeLimpo[0].toUpperCase();

    final avatar = CircleAvatar(
      radius: raio,
      backgroundColor: fundo,
      child: Text(
        inicial,
        style: TextStyle(
          color: textoSobreFundo,
          fontWeight: FontWeight.bold,
          fontSize: raio * 0.9,
        ),
      ),
    );

    if (aoTocar == null) return avatar;
    return GestureDetector(onTap: aoTocar, child: avatar);
  }
}
