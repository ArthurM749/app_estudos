import 'package:flutter/material.dart';

import '../theme/app_cores.dart';

/// Avatar do usuário: foto, se houver; senão a inicial do nome sobre a cor
/// escolhida. É o único avatar do app — Home, feed, perfil e comentários usam
/// este widget, então cor e foto ficam iguais em todo lugar.
class AvatarUsuario extends StatelessWidget {
  final String nome;

  /// Cor ARGB escolhida no perfil; nula usa a cor padrão do tema.
  final int? cor;

  /// Endereço da foto no Supabase Storage (nulo = sem foto).
  final String? imagemUrl;

  /// Imagem já em memória (pré-visualização antes de salvar). Tem prioridade
  /// sobre [imagemUrl].
  final ImageProvider? imagem;
  final double raio;
  final VoidCallback? aoTocar;

  const AvatarUsuario({
    super.key,
    required this.nome,
    this.cor,
    this.imagemUrl,
    this.imagem,
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

    final foto = imagem ??
        ((imagemUrl != null && imagemUrl!.isNotEmpty)
            ? NetworkImage(imagemUrl!)
            : null);

    final avatar = CircleAvatar(
      radius: raio,
      backgroundColor: fundo,
      // Se a foto não carregar (sem internet), a inicial por baixo aparece.
      foregroundImage: foto,
      onForegroundImageError: foto == null ? null : (_, __) {},
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
