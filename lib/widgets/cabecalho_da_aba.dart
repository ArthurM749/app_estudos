import 'package:flutter/material.dart';

/// Cabeçalho padrão das abas principais: título grande + subtítulo
/// opcional à esquerda, ícone de engrenagem à direita (leva pra aba
/// Perfil, onde ficam tema e dados). [leading] é opcional — a tela
/// de Início usa pra colocar o avatar antes do título.
class CabecalhoDaAba extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? leading;
  final VoidCallback? aoTocarConfiguracoes;

  const CabecalhoDaAba({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.leading,
    this.aoTocarConfiguracoes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitulo!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: aoTocarConfiguracoes,
          ),
        ],
      ),
    );
  }
}
