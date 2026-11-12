import 'package:flutter/material.dart';

class CabecalhoDaAba extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? leading;
  final VoidCallback? aoTocarConfiguracoes;

  /// Botões extras ao lado da engrenagem (ex.: busca de pessoas no feed).
  final List<Widget> acoes;

  const CabecalhoDaAba({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.leading,
    this.aoTocarConfiguracoes,
    this.acoes = const [],
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
          ...acoes,
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: aoTocarConfiguracoes,
          ),
        ],
      ),
    );
  }
}
