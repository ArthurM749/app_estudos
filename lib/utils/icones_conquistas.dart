import 'package:flutter/material.dart';

/// Ícone de cada conquista. Fica num lugar só porque a tela de Perfil e os
/// cartões do feed (conquistas compartilhadas) usam os mesmos ícones.
const Map<String, IconData> iconesConquistas = {
  'primeira_anotacao': Icons.edit_note,
  'arquiteto': Icons.architecture,
  'maos_a_obra': Icons.handyman,
  'biblioteca': Icons.menu_book,
  'nivel_5': Icons.military_tech,
  'nivel_10': Icons.workspace_premium,
  'aquecendo': Icons.local_fire_department,
  'semana_perfeita': Icons.event_available,
  'centenario': Icons.star,
  'estudioso': Icons.school,
  'dedicado': Icons.emoji_events,
};

IconData iconeDaConquista(String? id) =>
    iconesConquistas[id] ?? Icons.emoji_events_outlined;
