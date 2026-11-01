import '../models/evento_pontos.dart';

/// Regras de pontuação e nível, num lugar só para o grupo poder
/// calibrar sem procurar espalhado pelo código.
///
/// Valores iniciais propostos no documento de ideia — ajustem à
/// vontade.
class RegrasDePontos {
  RegrasDePontos._();

  static const Map<TipoAcao, int> pontosPorAcao = {
    TipoAcao.criarProjeto: 10,
    TipoAcao.criarAnotacao: 5,
    TipoAcao.concluirTarefa: 10,
    // Bônus por terminar um projeto inteiro (chegar a 100%), além
    // dos pontos que cada tarefa já deu no caminho.
    TipoAcao.concluirProjeto: 100,
  };

  /// Pontos necessários para passar do nível [nivelAtual] para o
  /// próximo: 100 * nivelAtual (nível 2 pede 100, nível 3 pede mais
  /// 200, e assim por diante).
  static int pontosParaProximoNivel(int nivelAtual) => 100 * nivelAtual;

  /// Calcula o nível atual a partir do total de pontos acumulados.
  static int nivelPara(int pontosTotais) {
    var nivel = 1;
    var restante = pontosTotais;
    while (restante >= pontosParaProximoNivel(nivel)) {
      restante -= pontosParaProximoNivel(nivel);
      nivel++;
    }
    return nivel;
  }

  /// Quantos pontos já foram acumulados DENTRO do nível atual (o "x"
  /// de "x/100 pts" na barra de progresso do nível).
  static int pontosDentroDoNivelAtual(int pontosTotais) {
    var nivel = 1;
    var restante = pontosTotais;
    while (restante >= pontosParaProximoNivel(nivel)) {
      restante -= pontosParaProximoNivel(nivel);
      nivel++;
    }
    return restante;
  }

  /// Nome amigável do nível, só decoração.
  static String tituloDoNivel(int nivel) {
    if (nivel <= 2) return 'Iniciante';
    if (nivel <= 4) return 'Aprendiz';
    if (nivel <= 9) return 'Estudioso';
    if (nivel <= 19) return 'Mestre';
    return 'Lenda';
  }
}
