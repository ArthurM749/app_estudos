import '../models/evento_pontos.dart';

/// Regras de pontuação e nível, num lugar só para o grupo poder
/// calibrar sem procurar espalhado pelo código.
///
/// Valores iniciais propostos no documento de ideia — ajustem à
/// vontade.
class RegrasDePontos {
  RegrasDePontos._();

  static const Map<TipoAcao, int> pontosPorAcao = {
    TipoAcao.criarAnotacao: 10,
    TipoAcao.concluirTarefa: 5,
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
}
