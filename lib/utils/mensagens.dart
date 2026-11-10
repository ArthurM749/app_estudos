import 'package:flutter/material.dart';

/// Mostra uma mensagem rápida na parte de baixo da tela. Seguro de chamar
/// depois de um `await`: se a tela já saiu, não faz nada.
void mostrarMensagem(BuildContext context, String texto) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}
