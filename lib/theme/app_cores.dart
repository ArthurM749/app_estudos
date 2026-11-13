import 'package:flutter/material.dart';
import 'app_palette.dart';

class AppCores {
  const AppCores({
    required this.fundoApp,
    required this.superficie,
    required this.cartao,
    required this.cartaoBorda,
    required this.dialogoFundo,
    required this.divisor,
    required this.appBarFundo,
    required this.appBarTexto,
    required this.navegacaoFundo,
    required this.navegacaoIndicador,
    required this.navegacaoItemAtivo,
    required this.navegacaoItemInativo,
    required this.textoPrincipal,
    required this.textoSecundario,
    required this.textoSuave,
    required this.bordaForte,
    required this.botaoPrimarioFundo,
    required this.botaoPrimarioTexto,
    required this.botaoDesabilitadoFundo,
    required this.botaoDesabilitadoTexto,
    required this.botaoSecundarioTexto,
    required this.botaoSecundarioBorda,
    required this.botaoTextoCor,
    required this.botaoPerigoFundo,
    required this.botaoPerigoTexto,
    required this.botaoPerigoSuaveFundo,
    required this.botaoPerigoSuaveTexto,
    required this.fabFundo,
    required this.fabIcone,
    required this.campoFundo,
    required this.campoBorda,
    required this.campoBordaFoco,
    required this.campoRotulo,
    required this.cursor,
    required this.selecaoTexto,
    required this.progressoAtivo,
    required this.progressoTrilho,
    required this.sliderAtivo,
    required this.sliderTrilho,
    required this.sliderBolinha,
    required this.sliderOverlay,
    required this.graficoBarra,
    required this.graficoBarraSelecionada,
    required this.graficoRotulo,
    required this.graficoRotuloSelecionado,
    required this.graficoTooltipFundo,
    required this.graficoTooltipTexto,
    required this.iconePadrao,
    required this.iconeDestaque,
    required this.iconeSuave,
    required this.chipFundo,
    required this.chipFundoSelecionado,
    required this.chipTexto,
    required this.chipTextoSelecionado,
    required this.chipBorda,
    required this.controleAtivo,
    required this.controleAtivoSobre,
    required this.controleInativoBorda,
    required this.controleInativoTrilho,
    required this.controleInativoBolinha,
    required this.abaAtiva,
    required this.abaInativa,
    required this.abaIndicador,
    required this.snackbarFundo,
    required this.snackbarTexto,
    required this.tooltipFundo,
    required this.tooltipTexto,
    required this.perigo,
    required this.perigoSobre,
    required this.sucesso,
    required this.conquistaFundo,
    required this.conquistaIcone,
    required this.conquistaTexto,
    required this.conquistaBloqueadaFundo,
    required this.conquistaBloqueadaIcone,
    required this.conquistaBloqueadaTexto,
    required this.curtida,
    required this.emblemaFundo,
    required this.emblemaTexto,
    required this.emblemaIcone,
    required this.avatarFundo,
    required this.avatarTexto,
    required this.marcador,
  });

  // (Todas as variáveis finais mantidas idênticas...)
  final Color fundoApp;
  final Color superficie;
  final Color cartao;
  final Color cartaoBorda;
  final Color dialogoFundo;
  final Color divisor;
  final Color appBarFundo;
  final Color appBarTexto;
  final Color navegacaoFundo;
  final Color navegacaoIndicador;
  final Color navegacaoItemAtivo;
  final Color navegacaoItemInativo;
  final Color textoPrincipal;
  final Color textoSecundario;
  final Color textoSuave;
  final Color bordaForte;
  final Color botaoPrimarioFundo;
  final Color botaoPrimarioTexto;
  final Color botaoDesabilitadoFundo;
  final Color botaoDesabilitadoTexto;
  final Color botaoSecundarioTexto;
  final Color botaoSecundarioBorda;
  final Color botaoTextoCor;
  final Color botaoPerigoFundo;
  final Color botaoPerigoTexto;
  final Color botaoPerigoSuaveFundo;
  final Color botaoPerigoSuaveTexto;
  final Color fabFundo;
  final Color fabIcone;
  final Color campoFundo;
  final Color campoBorda;
  final Color campoBordaFoco;
  final Color campoRotulo;
  final Color cursor;
  final Color selecaoTexto;
  final Color progressoAtivo;
  final Color progressoTrilho;
  final Color sliderAtivo;
  final Color sliderTrilho;
  final Color sliderBolinha;
  final Color sliderOverlay;
  final Color graficoBarra;
  final Color graficoBarraSelecionada;
  final Color graficoRotulo;
  final Color graficoRotuloSelecionado;
  final Color graficoTooltipFundo;
  final Color graficoTooltipTexto;
  final Color iconePadrao;
  final Color iconeDestaque;
  final Color iconeSuave;
  final Color chipFundo;
  final Color chipFundoSelecionado;
  final Color chipTexto;
  final Color chipTextoSelecionado;
  final Color chipBorda;
  final Color controleAtivo;
  final Color controleAtivoSobre;
  final Color controleInativoBorda;
  final Color controleInativoTrilho;
  final Color controleInativoBolinha;
  final Color abaAtiva;
  final Color abaInativa;
  final Color abaIndicador;
  final Color snackbarFundo;
  final Color snackbarTexto;
  final Color tooltipFundo;
  final Color tooltipTexto;
  final Color perigo;
  final Color perigoSobre;
  final Color sucesso;
  final Color conquistaFundo;
  final Color conquistaIcone;
  final Color conquistaTexto;
  final Color conquistaBloqueadaFundo;
  final Color conquistaBloqueadaIcone;
  final Color conquistaBloqueadaTexto;
  final Color curtida;
  final Color emblemaFundo;
  final Color emblemaTexto;
  final Color emblemaIcone;
  final Color avatarFundo;
  final Color avatarTexto;
  final Color marcador;

  ButtonStyle get estiloBotaoPerigo => FilledButton.styleFrom(
        backgroundColor: botaoPerigoFundo,
        foregroundColor: botaoPerigoTexto,
      );

  ButtonStyle get estiloBotaoPerigoSuave => FilledButton.styleFrom(
        backgroundColor: botaoPerigoSuaveFundo,
        foregroundColor: botaoPerigoSuaveTexto,
      );

  /// --- TEMA CLARO ---
  static const claro = AppCores(
    fundoApp: AppPalette.lightBackground,
    superficie: AppPalette.lightSurface,
    cartao: AppPalette.lightCard,
    cartaoBorda: AppPalette.lightBorder,
    dialogoFundo: AppPalette.lightSurface,
    divisor: AppPalette.lightBorder,
    appBarFundo: AppPalette.lightBackground,
    appBarTexto: AppPalette.lightText,
    
    navegacaoFundo: AppPalette.lightSurface,
    navegacaoIndicador: Color(0xFFE0D8CF),
    navegacaoItemAtivo: AppPalette.lightText,
    navegacaoItemInativo: AppPalette.lightMuted,
    
    textoPrincipal: AppPalette.lightText,
    textoSecundario: Color(0xFF4A5C68),
    textoSuave: AppPalette.lightMuted,
    bordaForte: Color(0xFFB0A8A0),
    
    // Alto contraste garantido: Fundo escuro (#365673) com texto Branco
    botaoPrimarioFundo: AppPalette.graphite, 
    botaoPrimarioTexto: Color(0xFFFFFFFF),
    botaoDesabilitadoFundo: Color(0xFFDCD6D0),
    botaoDesabilitadoTexto: AppPalette.lightMuted,
    botaoSecundarioTexto: AppPalette.graphite,
    botaoSecundarioBorda: AppPalette.graphite,
    botaoTextoCor: AppPalette.graphite,
    
    botaoPerigoFundo: Color(0xFFD95A2B),
    botaoPerigoTexto: Color(0xFFFFFFFF),
    botaoPerigoSuaveFundo: Color(0xFFF9EAE5),
    botaoPerigoSuaveTexto: Color(0xFFD95A2B),
    
    // FAB com contraste perfeito
    fabFundo: AppPalette.graphite,
    fabIcone: Color(0xFFFFFFFF),
    
    campoFundo: AppPalette.lightSurface,
    campoBorda: AppPalette.lightBorder,
    campoBordaFoco: AppPalette.graphite,
    campoRotulo: AppPalette.lightMuted,
    cursor: AppPalette.graphite,
    selecaoTexto: Color(0x354D7A8C),
    
    progressoAtivo: Color(0xFF4D7A8C),
    progressoTrilho: Color(0xFFD9D0C7),
    sliderAtivo: Color(0xFF4D7A8C),
    sliderTrilho: Color(0xFFD9D0C7),
    sliderBolinha: Color(0xFF4D7A8C),
    sliderOverlay: Color(0x1F4D7A8C),
    
    // Gráficos usam a cor Laranja da paleta (#D95A2B)
    graficoBarra: AppPalette.lightBorder,
    graficoBarraSelecionada: Color(0xFFD95A2B),
    graficoRotulo: AppPalette.lightMuted,
    graficoRotuloSelecionado: Color(0xFFD95A2B),
    graficoTooltipFundo: AppPalette.lightText,
    graficoTooltipTexto: Color(0xFFFFFFFF),
    
    iconePadrao: AppPalette.lightText,
    iconeDestaque: Color(0xFF4D7A8C),
    iconeSuave: AppPalette.lightMuted,
    
    chipFundo: AppPalette.lightCard,
    chipFundoSelecionado: Color(0xFFE5EEF2),
    chipTexto: AppPalette.lightText,
    chipTextoSelecionado: AppPalette.graphite,
    chipBorda: AppPalette.lightBorder,
    
    controleAtivo: Color(0xFF4D7A8C),
    controleAtivoSobre: Color(0xFFFFFFFF),
    controleInativoBorda: Color(0xFFB0A8A0),
    controleInativoTrilho: Color(0xFFD9D0C7),
    controleInativoBolinha: AppPalette.lightMuted,
    
    abaAtiva: AppPalette.graphite,
    abaInativa: AppPalette.lightMuted,
    abaIndicador: AppPalette.graphite,
    
    snackbarFundo: AppPalette.lightText,
    snackbarTexto: Color(0xFFFFFFFF),
    tooltipFundo: AppPalette.lightText,
    tooltipTexto: Color(0xFFFFFFFF),
    
    perigo: Color(0xFFD95A2B),
    perigoSobre: Color(0xFFFFFFFF),
    sucesso: Color(0xFF429867),
    
    conquistaFundo: Color.fromARGB(255, 231, 194, 114),
    conquistaIcone: Color.fromARGB(255, 209, 145, 7),
    conquistaTexto: Color.fromARGB(255, 48, 47, 47),
    conquistaBloqueadaFundo: AppPalette.lightCard,
    conquistaBloqueadaIcone: AppPalette.lightMuted,
    conquistaBloqueadaTexto: AppPalette.lightMuted,
    
    curtida: Color(0xFFD95A2B),
    emblemaFundo: Color(0xFFE5EEF2),
    emblemaTexto: AppPalette.graphite,
    emblemaIcone: Color(0xFF4D7A8C),
    avatarFundo: AppPalette.lightBorder,
    avatarTexto: AppPalette.lightText,
    marcador: Color(0xFFD95A2B),
  );

  /// --- TEMA ESCURO ---
  static const escuro = AppCores(
    fundoApp: AppPalette.darkBackground,
    superficie: AppPalette.darkSurface,
    cartao: AppPalette.darkCard,
    cartaoBorda: AppPalette.darkBorder,
    dialogoFundo: AppPalette.darkSurface,
    divisor: AppPalette.darkBorder,
    appBarFundo: AppPalette.darkBackground,
    appBarTexto: AppPalette.darkText,
    
    navegacaoFundo: AppPalette.darkBackground,
    navegacaoIndicador: AppPalette.slateBlue,
    navegacaoItemAtivo: Color(0xFFFFFFFF),
    navegacaoItemInativo: AppPalette.darkMuted,
    
    textoPrincipal: AppPalette.darkText,
    textoSecundario: Color(0xFFC4CEC3),
    textoSuave: AppPalette.darkMuted,
    bordaForte: Color(0xFF3F3F3F),
    
    // Contraste: Fundo Azul (#204370) com Ícone/Texto Branco
    botaoPrimarioFundo: AppPalette.slateBlue,
    botaoPrimarioTexto: Color(0xFFFFFFFF),
    botaoDesabilitadoFundo: Color(0xFF1E1E1E),
    botaoDesabilitadoTexto: Color(0xFF5A5A5A),
    botaoSecundarioTexto: AppPalette.darkText,
    botaoSecundarioBorda: AppPalette.slateBlue,
    botaoTextoCor: AppPalette.paleSlateBlue,
    
    botaoPerigoFundo: Color(0xFFBF0413),
    botaoPerigoTexto: Color(0xFFFFFFFF),
    botaoPerigoSuaveFundo: Color(0xFF73030D),
    botaoPerigoSuaveTexto: Color(0xFFF29D9D),
    
    // FAB com destaque usando vermelho vibrante da paleta
    fabFundo: Color.fromARGB(255, 182, 67, 32),
    fabIcone: Color(0xFFFFFFFF),
    
    campoFundo: AppPalette.darkSurface,
    campoBorda: AppPalette.darkBorder,
    campoBordaFoco: AppPalette.paleSlateBlue,
    campoRotulo: AppPalette.darkMuted,
    cursor: AppPalette.paleSlateBlue,
    selecaoTexto: Color(0x454D7A8C),
    
    progressoAtivo: AppPalette.paleSlateBlue,
    progressoTrilho: Color(0xFF2C2C2C),
    sliderAtivo: AppPalette.paleSlateBlue,
    sliderTrilho: Color(0xFF2C2C2C),
    sliderBolinha: AppPalette.paleSlateBlue,
    sliderOverlay: Color(0x2F4D7A8C),
    
    // Gráficos ganham o vermelho suave gamificado
    graficoBarra: AppPalette.darkBorder,
    graficoBarraSelecionada: Color(0xFFBF2C2C),
    graficoRotulo: AppPalette.darkMuted,
    graficoRotuloSelecionado: Color(0xFFBF2C2C),
    graficoTooltipFundo: Color(0xFF2C2C2C),
    graficoTooltipTexto: Color(0xFFFFFFFF),
    
    iconePadrao: AppPalette.darkText,
    iconeDestaque: AppPalette.paleSlateBlue,
    iconeSuave: AppPalette.darkMuted,
    
    chipFundo: AppPalette.darkCard,
    chipFundoSelecionado: AppPalette.slateBlue,
    chipTexto: AppPalette.darkText,
    chipTextoSelecionado: Color(0xFFFFFFFF),
    chipBorda: AppPalette.darkBorder,
    
    controleAtivo: AppPalette.paleSlateBlue,
    controleAtivoSobre: Color(0xFFFFFFFF),
    controleInativoBorda: Color(0xFF3F3F3F),
    controleInativoTrilho: Color(0xFF2C2C2C),
    controleInativoBolinha: AppPalette.darkMuted,
    
    abaAtiva: AppPalette.darkText,
    abaInativa: AppPalette.darkMuted,
    abaIndicador: AppPalette.paleSlateBlue,
    
    snackbarFundo: Color(0xFF2C2C2C),
    snackbarTexto: Color(0xFFFFFFFF),
    tooltipFundo: Color(0xFF2C2C2C),
    tooltipTexto: Color(0xFFFFFFFF),
    
    perigo: Color(0xFFBF0413),
    perigoSobre: Color(0xFFFFFFFF),
    sucesso: Color(0xFF429867),
    
    conquistaFundo: Color.fromARGB(255, 216, 194, 166),
    conquistaIcone: Color.fromARGB(255, 207, 161, 9),
    conquistaTexto: Color.fromARGB(255, 59, 59, 59),
    conquistaBloqueadaFundo: AppPalette.darkSurface,
    conquistaBloqueadaIcone: Color(0xFF2C2C2C),
    conquistaBloqueadaTexto: AppPalette.darkMuted,
    
    curtida: Color.fromARGB(255, 241, 37, 54),
    emblemaFundo: AppPalette.slateBlue,
    emblemaTexto: Color(0xFFFFFFFF),
    emblemaIcone: AppPalette.paleSlateBlue,
    avatarFundo: Color(0xFF2C2C2C),
    avatarTexto: AppPalette.darkText,
    marcador: Color(0xFFBF2C2C),
  );
}

extension AppCoresNoContexto on BuildContext {
  AppCores get coresApp => Theme.of(this).brightness == Brightness.dark
      ? AppCores.escuro
      : AppCores.claro;
}
