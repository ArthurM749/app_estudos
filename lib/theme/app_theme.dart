import 'package:flutter/material.dart';

import 'app_cores.dart';

// Reexporta para que quem já importava `AppPalette` daqui continue funcionando.
export 'app_palette.dart';

/// Monta o [ThemeData] a partir dos tokens de [AppCores]. Este arquivo não tem
/// nenhuma cor escrita à mão: para mudar o visual, mexa em `app_cores.dart`.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _construir(AppCores.claro, Brightness.light);
  static ThemeData get dark => _construir(AppCores.escuro, Brightness.dark);

  static ThemeData _construir(AppCores c, Brightness brilho) {
    // Todos os papéis do ColorScheme são preenchidos de propósito. Quando um
    // papel fica de fora, o Material 3 completa com o roxo/rosa padrão dele —
    // foi assim que o botão "Apagar todos os dados" ficou rosado sem ninguém
    // ter escolhido essa cor.
    final esquema = ColorScheme(
      brightness: brilho,
      primary: c.botaoPrimarioFundo,
      onPrimary: c.botaoPrimarioTexto,
      primaryContainer: c.fabFundo,
      onPrimaryContainer: c.fabIcone,
      secondary: c.textoSuave,
      onSecondary: c.botaoPrimarioTexto,
      secondaryContainer: c.emblemaFundo,
      onSecondaryContainer: c.emblemaTexto,
      tertiary: c.iconeDestaque,
      onTertiary: c.botaoPrimarioTexto,
      tertiaryContainer: c.emblemaFundo,
      onTertiaryContainer: c.emblemaTexto,
      error: c.perigo,
      onError: c.perigoSobre,
      errorContainer: c.botaoPerigoSuaveFundo,
      onErrorContainer: c.botaoPerigoSuaveTexto,
      surface: c.superficie,
      onSurface: c.textoPrincipal,
      onSurfaceVariant: c.textoSecundario,
      surfaceDim: c.fundoApp,
      surfaceBright: c.superficie,
      // O Card do Material 3 usa surfaceContainerLow e o AlertDialog usa
      // surfaceContainerHigh como cor de fundo.
      surfaceContainerLowest: c.fundoApp,
      surfaceContainerLow: c.cartao,
      surfaceContainer: c.superficie,
      surfaceContainerHigh: c.dialogoFundo,
      surfaceContainerHighest: c.campoFundo,
      outline: c.bordaForte,
      outlineVariant: c.cartaoBorda,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: c.snackbarFundo,
      onInverseSurface: c.snackbarTexto,
      inversePrimary: c.iconeDestaque,
      // Sem "tint": o Material 3 pintaria cartões elevados com essa cor.
      surfaceTint: Colors.transparent,
    );

    final raio14 = BorderRadius.circular(14);

    return ThemeData(
      useMaterial3: true,
      brightness: brilho,
      colorScheme: esquema,
      scaffoldBackgroundColor: c.fundoApp,
      canvasColor: c.fundoApp,
      cardColor: c.cartao,
      shadowColor: Colors.black,
      iconTheme: IconThemeData(color: c.iconePadrao),
      appBarTheme: AppBarTheme(
        backgroundColor: c.appBarFundo,
        foregroundColor: c.appBarTexto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.navegacaoFundo,
        indicatorColor: c.navegacaoIndicador,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((estados) {
          final selecionada = estados.contains(WidgetState.selected);
          return TextStyle(
            color: selecionada ? c.navegacaoItemAtivo : c.navegacaoItemInativo,
            fontWeight: selecionada ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((estados) {
          final selecionada = estados.contains(WidgetState.selected);
          return IconThemeData(
            color: selecionada ? c.navegacaoItemAtivo : c.navegacaoItemInativo,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.botaoPrimarioFundo,
          foregroundColor: c.botaoPrimarioTexto,
          disabledBackgroundColor: c.botaoDesabilitadoFundo,
          disabledForegroundColor: c.botaoDesabilitadoTexto,
          shape: RoundedRectangleBorder(borderRadius: raio14),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.botaoSecundarioTexto,
          side: BorderSide(color: c.botaoSecundarioBorda),
          shape: RoundedRectangleBorder(borderRadius: raio14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.botaoTextoCor),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.iconePadrao),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.fabFundo,
        foregroundColor: c.fabIcone,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.campoFundo,
        labelStyle: TextStyle(color: c.campoRotulo),
        hintStyle: TextStyle(color: c.campoRotulo),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: raio14,
          borderSide: BorderSide(color: c.campoBorda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: raio14,
          borderSide: BorderSide(color: c.campoBorda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: raio14,
          borderSide: BorderSide(color: c.campoBordaFoco, width: 1.6),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.divisor, thickness: 0.7, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.progressoAtivo,
        linearTrackColor: c.progressoTrilho,
        circularTrackColor: c.progressoTrilho,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.sliderAtivo,
        inactiveTrackColor: c.sliderTrilho,
        thumbColor: c.sliderBolinha,
        overlayColor: c.sliderOverlay,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.cursor,
        selectionColor: c.selecaoTexto,
        selectionHandleColor: c.cursor,
      ),
      cardTheme: CardThemeData(
        color: c.cartao,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: raio14,
          side: BorderSide(color: c.cartaoBorda, width: 0.8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.dialogoFundo,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.snackbarFundo,
        contentTextStyle: TextStyle(color: c.snackbarTexto),
        actionTextColor: c.snackbarTexto,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.chipFundo,
        selectedColor: c.chipFundoSelecionado,
        checkmarkColor: c.chipTextoSelecionado,
        side: BorderSide(color: c.chipBorda),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: WidgetStateTextStyle.resolveWith((estados) {
          final selecionado = estados.contains(WidgetState.selected);
          return TextStyle(
            color: selecionado ? c.chipTextoSelecionado : c.chipTexto,
            fontWeight: selecionado ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((estados) {
          return estados.contains(WidgetState.selected)
              ? c.controleAtivoSobre
              : c.controleInativoBolinha;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((estados) {
          return estados.contains(WidgetState.selected)
              ? c.controleAtivo
              : c.controleInativoTrilho;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((estados) {
          return estados.contains(WidgetState.selected)
              ? Colors.transparent
              : c.controleInativoBorda;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((estados) {
          return estados.contains(WidgetState.selected)
              ? c.controleAtivo
              : c.controleInativoBorda;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((estados) {
          return estados.contains(WidgetState.selected)
              ? c.controleAtivo
              : Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(c.controleAtivoSobre),
        side: BorderSide(color: c.controleInativoBorda, width: 1.5),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.iconePadrao,
        textColor: c.textoPrincipal,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.tooltipFundo,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: c.tooltipTexto, fontSize: 12),
      ),
    );
  }
}
