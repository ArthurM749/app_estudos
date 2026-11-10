import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException;

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  User? get usuarioAtual => _client.auth.currentUser;

  Future<AuthResponse> entrar({
    required String email,
    required String senha,
  }) =>
      _client.auth.signInWithPassword(email: email, password: senha);

  Future<AuthResponse> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) =>
      _client.auth.signUp(
        email: email,
        password: senha,
        data: {'nome': nome},
      );

  Future<void> sair() => _client.auth.signOut();

  static String traduzirErro(Object erro) {
    if (erro is AuthException) {
      // O código estável do Supabase vem primeiro; o texto da mensagem muda
      // entre versões, então fica só como reserva.
      switch (erro.code) {
        case 'invalid_credentials':
          return 'Email ou senha incorretos.';
        case 'email_not_confirmed':
          return 'Confirme seu email antes de entrar (veja sua caixa de entrada).';
        case 'user_already_exists':
        case 'email_exists':
          return 'Esse email já tem conta. Use "Entrar".';
        case 'weak_password':
          return 'A senha é fraca demais. Use pelo menos 6 caracteres.';
        case 'over_request_rate_limit':
        case 'over_email_send_rate_limit':
          return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
      }
      final msg = erro.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Email ou senha incorretos.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Confirme seu email antes de entrar (veja sua caixa de entrada).';
      }
      if (msg.contains('already registered')) {
        return 'Esse email já tem conta. Use "Entrar".';
      }
      if (msg.contains('password should be at least')) {
        return 'A senha precisa ter pelo menos 6 caracteres.';
      }
      if (msg.contains('rate limit')) {
        return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
      }
      return erro.message;
    }
    if (erro is SocketException || erro is TimeoutException) {
      return 'Sem conexão com a internet. Tente de novo.';
    }
    return 'Não foi possível concluir: $erro';
  }
}
