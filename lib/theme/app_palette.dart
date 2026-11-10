import 'package:flutter/material.dart';

/// Cores cruas do app — o "estoque de tintas". Aqui só ficam os valores; quem
/// decide qual cor vai em qual componente (botão, gráfico, ícone...) é o
/// `app_cores.dart`. Para trocar a identidade visual inteira, mude estes valores;
/// para trocar só um componente, mude o token dele em `app_cores.dart`.
class AppPalette {
  AppPalette._();

  static const Color lightBackground = Color(0xFFD9D9D9);
  static const Color lightSurface = Color(0xFFF0F0F0);
  static const Color lightCard = Color(0xFFEAEAEA);
  static const Color lightText = Color(0xFF0D0D0D);
  static const Color lightMuted = Color(0xFF737373);
  static const Color lightBorder = Color.fromARGB(255, 185, 184, 184);
  static const Color graphite = Color.fromARGB(255, 17, 17, 17);

  static const Color darkBackground = Color(0xFF0A0B0D);
  static const Color darkSurface = Color(0xFF1A1E26);
  static const Color darkCard = Color(0xFF1A1E26);
  static const Color slateBlue = Color(0xFF536173);
  static const Color paleSlateBlue = Color(0xFF8593A6);
  static const Color darkText = Color(0xFFE2E6EC);
  static const Color darkMuted = Color(0xFF8593A6);
  static const Color darkBorder = Color(0xFF536173);
}
