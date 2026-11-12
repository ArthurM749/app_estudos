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

String formatarDataCompleta(DateTime data) {
  final diaSemana = _diasPorExtenso[data.weekday - 1];
  final mes = _mesesPorExtenso[data.month - 1];
  return '$diaSemana, ${data.day} de $mes';
}

String formatarDataCurta(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}

String formatarMesAno(DateTime data) {
  return '${_mesesPorExtenso[data.month - 1]} de ${data.year}';
}

/// "09/11/2026 · 20:55", no fuso do aparelho (o banco guarda em UTC).
String formatarDataHora(DateTime data) {
  final local = data.toLocal();
  final hora = local.hour.toString().padLeft(2, '0');
  final minuto = local.minute.toString().padLeft(2, '0');
  return '${formatarDataCurta(local)} · $hora:$minuto';
}
