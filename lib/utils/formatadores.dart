const _diasPorExtenso = [
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
  'domingo',
];

const _mesesPorExtenso = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// "quinta-feira, 29 de outubro"
String formatarDataCompleta(DateTime data) {
  final diaSemana = _diasPorExtenso[data.weekday - 1];
  final mes = _mesesPorExtenso[data.month - 1];
  return '$diaSemana, ${data.day} de $mes';
}

/// "29/10/2026"
String formatarDataCurta(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}

/// "outubro de 2026"
String formatarMesAno(DateTime data) {
  return '${_mesesPorExtenso[data.month - 1]} de ${data.year}';
}
