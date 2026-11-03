import '../models/evento_pontos.dart';

class RegrasDePontos {
  RegrasDePontos._();

  static const Map<TipoAcao, int> pontosPorAcao = {
    TipoAcao.criarProjeto: 10,
    TipoAcao.criarAnotacao: 5,
    TipoAcao.concluirTarefa: 10,
    TipoAcao.concluirProjeto: 100,
  };

  static int pontosParaProximoNivel(int nivelAtual) => 100 * nivelAtual;

  static int nivelPara(int pontosTotais) {
    var nivel = 1;
    var restante = pontosTotais;
    while (restante >= pontosParaProximoNivel(nivel)) {
      restante -= pontosParaProximoNivel(nivel);
      nivel++;
    }
    return nivel;
  }

  static int pontosDentroDoNivelAtual(int pontosTotais) {
    var nivel = 1;
    var restante = pontosTotais;
    while (restante >= pontosParaProximoNivel(nivel)) {
      restante -= pontosParaProximoNivel(nivel);
      nivel++;
    }
    return restante;
  }

  static String tituloDoNivel(int nivel) {
    if (nivel <= 2) return 'Iniciante';
    if (nivel <= 4) return 'Aprendiz';
    if (nivel <= 9) return 'Estudioso';
    if (nivel <= 19) return 'Mestre';
    return 'Lenda';
  }
}
