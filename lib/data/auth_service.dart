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
    return 'Não foi possível concluir: $erro';
  }
}
