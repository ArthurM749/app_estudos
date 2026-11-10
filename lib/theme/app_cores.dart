import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Painel de cores do app: UM token por função visual, em vez de um token por
/// cor. Assim dá para mudar, por exemplo, só o botão de perigo ou só as colunas
/// do gráfico sem mexer no resto — e várias funções podem apontar para a mesma
/// cor da [AppPalette] (é só repetir o valor).
///
/// Como usar:
///  * Para mudar uma cor: edite o valor em [AppCores.claro] ou [AppCores.escuro]
///    (no fim deste arquivo). O `app_theme.dart` lê tudo daqui.
///  * Num widget: `final cores = context.coresApp;` e depois `cores.curtida`.
///  * Para criar um token novo: declare o campo, o parâmetro do construtor e os
///    dois valores (claro e escuro).
///
/// Foi escolhido um objeto simples (e não ThemeExtension) para não precisar de
/// copyWith/lerp em ~100 campos; o tema claro/escuro é escolhido pelo
/// `Theme.of(context).brightness`.
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

  // ---- Fundos e superfícies ----
  /// Fundo de todas as telas (Scaffold).
  final Color fundoApp;
  /// Barras e painéis um degrau acima do fundo.
  final Color superficie;
  /// Fundo dos Card (projetos, estatísticas, publicações...).
  final Color cartao;
  /// Contorno fino dos cartões.
  final Color cartaoBorda;
  /// Fundo de diálogos (AlertDialog).
  final Color dialogoFundo;
  /// Linhas divisórias discretas.
  final Color divisor;
  /// Fundo da AppBar das telas secundárias.
  final Color appBarFundo;
  /// Título e ícones da AppBar.
  final Color appBarTexto;

  // ---- Navegação inferior ----
  /// Fundo da barra de abas.
  final Color navegacaoFundo;
  /// Pílula atrás do ícone da aba selecionada.
  final Color navegacaoIndicador;
  /// Ícone e rótulo da aba selecionada.
  final Color navegacaoItemAtivo;
  /// Ícone e rótulo das outras abas.
  final Color navegacaoItemInativo;

  // ---- Texto ----
  /// Texto de leitura.
  final Color textoPrincipal;
  /// Subtítulos, datas, legendas.
  final Color textoSecundario;
  /// Dicas, placeholders e itens inativos.
  final Color textoSuave;
  /// Contornos que precisam aparecer mais (ColorScheme.outline).
  final Color bordaForte;

  // ---- Botões ----
  /// FilledButton: fundo.
  final Color botaoPrimarioFundo;
  /// FilledButton: texto e ícone.
  final Color botaoPrimarioTexto;
  /// FilledButton desabilitado: fundo.
  final Color botaoDesabilitadoFundo;
  /// FilledButton desabilitado: texto.
  final Color botaoDesabilitadoTexto;
  /// OutlinedButton: texto e ícone.
  final Color botaoSecundarioTexto;
  /// OutlinedButton: contorno.
  final Color botaoSecundarioBorda;
  /// TextButton (Cancelar, links).
  final Color botaoTextoCor;
  /// Botão de ação destrutiva (Apagar tudo, Excluir): fundo.
  final Color botaoPerigoFundo;
  /// Botão destrutivo: texto.
  final Color botaoPerigoTexto;
  /// Botão destrutivo discreto (aviso antes do diálogo): fundo.
  final Color botaoPerigoSuaveFundo;
  /// Botão destrutivo discreto: texto.
  final Color botaoPerigoSuaveTexto;
  /// Botão flutuante (+): fundo.
  final Color fabFundo;
  /// Botão flutuante (+): ícone.
  final Color fabIcone;

  // ---- Campos de texto ----
  /// Fundo dos TextField.
  final Color campoFundo;
  /// Contorno em repouso.
  final Color campoBorda;
  /// Contorno com o campo focado.
  final Color campoBordaFoco;
  /// Rótulo e hint.
  final Color campoRotulo;
  /// Cursor e alças de seleção.
  final Color cursor;
  /// Fundo do texto selecionado.
  final Color selecaoTexto;

  // ---- Progresso e slider ----
  /// Barra de progresso: parte preenchida.
  final Color progressoAtivo;
  /// Barra de progresso: trilho.
  final Color progressoTrilho;
  /// Slider: parte ativa.
  final Color sliderAtivo;
  /// Slider: trilho.
  final Color sliderTrilho;
  /// Slider: bolinha.
  final Color sliderBolinha;
  /// Slider: halo ao tocar.
  final Color sliderOverlay;

  // ---- Gráficos (fl_chart) ----
  /// Colunas dos dias não selecionados.
  final Color graficoBarra;
  /// Coluna do dia selecionado.
  final Color graficoBarraSelecionada;
  /// Números do eixo e legendas.
  final Color graficoRotulo;
  /// Rótulo do dia selecionado.
  final Color graficoRotuloSelecionado;
  /// Balão ao tocar numa coluna.
  final Color graficoTooltipFundo;
  /// Texto do balão.
  final Color graficoTooltipTexto;

  // ---- Ícones ----
  /// Ícones comuns.
  final Color iconePadrao;
  /// Ícones de destaque (cabeçalhos, atalhos).
  final Color iconeDestaque;
  /// Ícones secundários (ações de cartão).
  final Color iconeSuave;

  // ---- Chips e controles (switch, radio) ----
  /// Chip não selecionado.
  final Color chipFundo;
  /// Chip selecionado.
  final Color chipFundoSelecionado;
  /// Texto do chip.
  final Color chipTexto;
  /// Texto e check do chip selecionado.
  final Color chipTextoSelecionado;
  /// Contorno do chip.
  final Color chipBorda;
  /// Switch ligado / radio marcado.
  final Color controleAtivo;
  /// Bolinha do switch ligado.
  final Color controleAtivoSobre;
  /// Contorno do switch/radio desligado.
  final Color controleInativoBorda;
  /// Trilho do switch desligado.
  final Color controleInativoTrilho;
  /// Bolinha do switch desligado.
  final Color controleInativoBolinha;

  // ---- Abas do feed ----
  /// Rótulo da aba selecionada.
  final Color abaAtiva;
  /// Rótulo das outras abas.
  final Color abaInativa;
  /// Sublinhado da aba selecionada.
  final Color abaIndicador;

  // ---- Feedback ----
  /// SnackBar: fundo.
  final Color snackbarFundo;
  /// SnackBar: texto.
  final Color snackbarTexto;
  /// Tooltip: fundo.
  final Color tooltipFundo;
  /// Tooltip: texto.
  final Color tooltipTexto;
  /// Erros e avisos de perigo (ColorScheme.error).
  final Color perigo;
  /// Texto sobre a cor de perigo.
  final Color perigoSobre;
  /// Confirmações.
  final Color sucesso;

  // ---- Conquistas ----
  /// Cartão de conquista desbloqueada.
  final Color conquistaFundo;
  /// Ícone da conquista desbloqueada.
  final Color conquistaIcone;
  /// Nome da conquista desbloqueada.
  final Color conquistaTexto;
  /// Cartão de conquista bloqueada.
  final Color conquistaBloqueadaFundo;
  /// Ícone da conquista bloqueada.
  final Color conquistaBloqueadaIcone;
  /// Nome da conquista bloqueada.
  final Color conquistaBloqueadaTexto;

  // ---- Parte social ----
  /// Coração de curtida ativo.
  final Color curtida;
  /// Selo de atividade compartilhada (projeto, conquista...).
  final Color emblemaFundo;
  /// Texto do selo.
  final Color emblemaTexto;
  /// Ícone do selo.
  final Color emblemaIcone;
  /// Avatar sem cor escolhida.
  final Color avatarFundo;
  /// Inicial do avatar sem cor escolhida.
  final Color avatarTexto;
  /// Sublinhado curto dos títulos de seção.
  final Color marcador;

  /// Botão de ação destrutiva (ex.: confirmar "Apagar tudo").
  ButtonStyle get estiloBotaoPerigo => FilledButton.styleFrom(
        backgroundColor: botaoPerigoFundo,
        foregroundColor: botaoPerigoTexto,
      );

  /// Versão discreta, para o botão que só abre o diálogo de confirmação.
  ButtonStyle get estiloBotaoPerigoSuave => FilledButton.styleFrom(
        backgroundColor: botaoPerigoSuaveFundo,
        foregroundColor: botaoPerigoSuaveTexto,
      );

  /// Tema claro (cinza e grafite).
  static const claro = AppCores(
    // Fundos e superfícies
    fundoApp: AppPalette.lightBackground,
    superficie: AppPalette.lightSurface,
    cartao: AppPalette.lightSurface,
    cartaoBorda: AppPalette.lightBorder,
    dialogoFundo: AppPalette.lightSurface,
    divisor: AppPalette.lightBorder,
    appBarFundo: AppPalette.lightBackground,
    appBarTexto: AppPalette.lightText,
    // Navegação inferior
    navegacaoFundo: AppPalette.lightSurface,
    navegacaoIndicador: AppPalette.lightBackground,
    navegacaoItemAtivo: AppPalette.graphite,
    navegacaoItemInativo: AppPalette.lightMuted,
    // Texto
    textoPrincipal: AppPalette.lightText,
    textoSecundario: Color(0xFF404040),
    textoSuave: AppPalette.lightMuted,
    bordaForte: AppPalette.lightMuted,
    // Botões
    botaoPrimarioFundo: AppPalette.graphite,
    botaoPrimarioTexto: AppPalette.lightSurface,
    botaoDesabilitadoFundo: AppPalette.lightBorder,
    botaoDesabilitadoTexto: AppPalette.lightMuted,
    botaoSecundarioTexto: AppPalette.graphite,
    botaoSecundarioBorda: AppPalette.lightMuted,
    botaoTextoCor: AppPalette.graphite,
    botaoPerigoFundo: Color(0xFFA33A3A),
    botaoPerigoTexto: AppPalette.lightSurface,
    botaoPerigoSuaveFundo: Color(0xFFE6D0D0),
    botaoPerigoSuaveTexto: Color(0xFF5C1F1F),
    fabFundo: AppPalette.lightBorder,
    fabIcone: AppPalette.lightText,
    // Campos de texto
    campoFundo: AppPalette.lightSurface,
    campoBorda: AppPalette.lightBorder,
    campoBordaFoco: AppPalette.graphite,
    campoRotulo: AppPalette.lightMuted,
    cursor: AppPalette.graphite,
    selecaoTexto: Color(0x55404040),
    // Progresso e slider
    progressoAtivo: AppPalette.graphite,
    progressoTrilho: AppPalette.lightBorder,
    sliderAtivo: AppPalette.graphite,
    sliderTrilho: AppPalette.lightBorder,
    sliderBolinha: AppPalette.graphite,
    sliderOverlay: Color(0x1F404040),
    // Gráficos (fl_chart)
    graficoBarra: AppPalette.lightMuted,
    graficoBarraSelecionada: AppPalette.graphite,
    graficoRotulo: Color(0xFF404040),
    graficoRotuloSelecionado: AppPalette.graphite,
    graficoTooltipFundo: AppPalette.graphite,
    graficoTooltipTexto: AppPalette.lightSurface,
    // Ícones
    iconePadrao: AppPalette.lightText,
    iconeDestaque: AppPalette.graphite,
    iconeSuave: AppPalette.lightMuted,
    // Chips e controles (switch, radio)
    chipFundo: AppPalette.lightSurface,
    chipFundoSelecionado: AppPalette.graphite,
    chipTexto: AppPalette.lightText,
    chipTextoSelecionado: AppPalette.lightSurface,
    chipBorda: AppPalette.lightBorder,
    controleAtivo: AppPalette.graphite,
    controleAtivoSobre: AppPalette.lightSurface,
    controleInativoBorda: AppPalette.lightMuted,
    controleInativoTrilho: AppPalette.lightBorder,
    controleInativoBolinha: AppPalette.lightMuted,
    // Abas do feed
    abaAtiva: AppPalette.graphite,
    abaInativa: AppPalette.lightMuted,
    abaIndicador: AppPalette.graphite,
    // Feedback
    snackbarFundo: AppPalette.graphite,
    snackbarTexto: AppPalette.lightSurface,
    tooltipFundo: AppPalette.graphite,
    tooltipTexto: AppPalette.lightSurface,
    perigo: Color(0xFFA33A3A),
    perigoSobre: AppPalette.lightSurface,
    sucesso: Color(0xFF3F6B4F),
    // Conquistas
    conquistaFundo: AppPalette.lightBorder,
    conquistaIcone: AppPalette.lightText,
    conquistaTexto: AppPalette.lightText,
    conquistaBloqueadaFundo: AppPalette.lightSurface,
    conquistaBloqueadaIcone: AppPalette.lightMuted,
    conquistaBloqueadaTexto: AppPalette.lightMuted,
    // Parte social
    curtida: Color(0xFFA33A3A),
    emblemaFundo: AppPalette.lightBackground,
    emblemaTexto: AppPalette.lightText,
    emblemaIcone: AppPalette.graphite,
    avatarFundo: AppPalette.lightMuted,
    avatarTexto: AppPalette.lightSurface,
    marcador: AppPalette.graphite,
  );

  /// Tema escuro (azul-ardósia).
  static const escuro = AppCores(
    // Fundos e superfícies
    fundoApp: AppPalette.darkBackground,
    superficie: AppPalette.darkSurface,
    cartao: AppPalette.darkCard,
    cartaoBorda: Color(0x59536173) /* slateBlue a 35% */,
    dialogoFundo: AppPalette.darkSurface,
    divisor: Color(0x59536173) /* slateBlue a 35% */,
    appBarFundo: AppPalette.darkBackground,
    appBarTexto: AppPalette.darkText,
    // Navegação inferior
    navegacaoFundo: AppPalette.darkBackground,
    navegacaoIndicador: AppPalette.darkSurface,
    navegacaoItemAtivo: AppPalette.darkText,
    navegacaoItemInativo: AppPalette.darkMuted,
    // Texto
    textoPrincipal: AppPalette.darkText,
    textoSecundario: AppPalette.darkMuted,
    textoSuave: AppPalette.darkMuted,
    bordaForte: AppPalette.slateBlue,
    // Botões
    botaoPrimarioFundo: AppPalette.darkText,
    botaoPrimarioTexto: AppPalette.darkBackground,
    botaoDesabilitadoFundo: AppPalette.darkBorder,
    botaoDesabilitadoTexto: AppPalette.darkMuted,
    botaoSecundarioTexto: AppPalette.darkText,
    botaoSecundarioBorda: AppPalette.slateBlue,
    botaoTextoCor: AppPalette.darkMuted,
    botaoPerigoFundo: Color(0xFFD98A8A),
    botaoPerigoTexto: AppPalette.darkBackground,
    botaoPerigoSuaveFundo: Color(0xFF3A2427),
    botaoPerigoSuaveTexto: Color(0xFFF0C9C9),
    fabFundo: AppPalette.slateBlue,
    fabIcone: AppPalette.darkText,
    // Campos de texto
    campoFundo: AppPalette.darkCard,
    campoBorda: AppPalette.darkBorder,
    campoBordaFoco: AppPalette.paleSlateBlue,
    campoRotulo: AppPalette.darkMuted,
    cursor: AppPalette.paleSlateBlue,
    selecaoTexto: Color(0x558593A6),
    // Progresso e slider
    progressoAtivo: AppPalette.paleSlateBlue,
    progressoTrilho: AppPalette.slateBlue,
    sliderAtivo: AppPalette.paleSlateBlue,
    sliderTrilho: AppPalette.slateBlue,
    sliderBolinha: AppPalette.paleSlateBlue,
    sliderOverlay: Color(0x338593A6),
    // Gráficos (fl_chart)
    graficoBarra: AppPalette.slateBlue,
    graficoBarraSelecionada: AppPalette.paleSlateBlue,
    graficoRotulo: AppPalette.darkMuted,
    graficoRotuloSelecionado: AppPalette.paleSlateBlue,
    graficoTooltipFundo: AppPalette.darkText,
    graficoTooltipTexto: AppPalette.darkBackground,
    // Ícones
    iconePadrao: AppPalette.darkText,
    iconeDestaque: AppPalette.paleSlateBlue,
    iconeSuave: AppPalette.darkMuted,
    // Chips e controles (switch, radio)
    chipFundo: AppPalette.darkCard,
    chipFundoSelecionado: AppPalette.slateBlue,
    chipTexto: AppPalette.darkText,
    chipTextoSelecionado: AppPalette.darkText,
    chipBorda: AppPalette.darkBorder,
    controleAtivo: AppPalette.paleSlateBlue,
    controleAtivoSobre: AppPalette.darkBackground,
    controleInativoBorda: AppPalette.slateBlue,
    controleInativoTrilho: AppPalette.darkBackground,
    controleInativoBolinha: AppPalette.darkMuted,
    // Abas do feed
    abaAtiva: AppPalette.darkText,
    abaInativa: AppPalette.darkMuted,
    abaIndicador: AppPalette.paleSlateBlue,
    // Feedback
    snackbarFundo: AppPalette.darkText,
    snackbarTexto: AppPalette.darkBackground,
    tooltipFundo: AppPalette.darkText,
    tooltipTexto: AppPalette.darkBackground,
    perigo: Color(0xFFD98A8A),
    perigoSobre: AppPalette.darkBackground,
    sucesso: Color(0xFF8FBF9F),
    // Conquistas
    conquistaFundo: AppPalette.slateBlue,
    conquistaIcone: AppPalette.darkText,
    conquistaTexto: AppPalette.darkText,
    conquistaBloqueadaFundo: AppPalette.darkSurface,
    conquistaBloqueadaIcone: AppPalette.slateBlue,
    conquistaBloqueadaTexto: AppPalette.darkMuted,
    // Parte social
    curtida: Color(0xFFD98A8A),
    emblemaFundo: AppPalette.darkBackground,
    emblemaTexto: AppPalette.darkText,
    emblemaIcone: AppPalette.paleSlateBlue,
    avatarFundo: AppPalette.slateBlue,
    avatarTexto: AppPalette.darkText,
    marcador: AppPalette.paleSlateBlue,
  );

}

extension AppCoresNoContexto on BuildContext {
  /// Tokens de cor do tema atual (claro ou escuro).
  AppCores get coresApp => Theme.of(this).brightness == Brightness.dark
      ? AppCores.escuro
      : AppCores.claro;
}

