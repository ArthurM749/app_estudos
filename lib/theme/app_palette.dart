import 'package:flutter/material.dart';

/// Cores cruas do app — o "estoque de tintas".
class AppPalette {
  AppPalette._();

  // --- TEMA CLARO (Base: #365673, #4D7A8C, #F0E8DF, #D95A2B) ---
  static const Color lightBackground = Color(0xFFF0E8DF); // Fundo principal da paleta
  static const Color lightSurface = Color(0xFFFDFBF7);    // Superfícies claras para destacar do fundo
  static const Color lightCard = Color(0xFFF8F4EC);       // Cartões
  static const Color lightText = Color(0xFF1A2126);       // Letra bem escura para contraste excelente
  static const Color lightMuted = Color(0xFF6B7C87);      // Texto secundário (acinzentado azulado)
  static const Color lightBorder = Color(0xFFD9D0C7);     // Bordas suaves
  static const Color graphite = Color(0xFF365673);        // Azul ardósia escuro (Botões, FAB, destaque forte)

  // --- TEMA ESCURO (Base: #BF0413, #73030D, #204370, #A4B0A2, #0D0D0D, #BF2C2C) ---
  static const Color darkBackground = Color(0xFF0D0D0D);  // Fundo preto puro da paleta
  static const Color darkSurface = Color(0xFF171717);     // Superfícies para destacar do fundo preto
  static const Color darkCard = Color(0xFF1E1E1E);        // Cartões
  static const Color slateBlue = Color(0xFF204370);       // Azul escuro (Botões no tema escuro)
  static const Color paleSlateBlue = Color(0xFF4D7A8C);   // Azul médio/claro para contraste e ícones
  static const Color darkText = Color(0xFFF2F2F2);        // Letra branca/gelo para destacar no preto
  static const Color darkMuted = Color(0xFFA4B0A2);       // Sage green (fornecido) ótimo e confortável para texto secundário
  static const Color darkBorder = Color(0xFF2C2C2C);      // Bordas escuras

  // ===========================================================================
  // CORES VARIADAS PARA PROJETOS E AVATARES (Substituindo os cinzas chatos)
  // Use essas variáveis quando o usuário for escolher a cor de um novo projeto!
  // ===========================================================================
  static const Color projectRed = Color(0xFFBF2C2C);
  static const Color projectOrange = Color(0xFFD95A2B);
  static const Color projectYellow = Color(0xFFE5A91A);
  static const Color projectGreen = Color(0xFF429867);
  static const Color projectTeal = Color(0xFF328C8C);
  static const Color projectBlue = Color(0xFF4D7A8C);
  static const Color projectPurple = Color(0xFF7B52AB);
  static const Color projectPink = Color(0xFFD94876);
}