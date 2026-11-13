import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/social_service.dart';
import '../data/social_state.dart';
import '../models/conquista.dart';
import '../models/perfil_social.dart';
import '../theme/app_cores.dart';
import '../utils/mensagens.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/seletor_de_cor.dart';
import '../widgets/titulo_secao.dart';

final _padraoUsuario = RegExp(r'^[a-z0-9_]{3,20}$');

enum _EstadoUsuario { neutro, verificando, livre, ocupado }

/// Edição do meu perfil público: nome, @usuário, bio, cor do avatar e, o mais
/// importante, o que fica visível para os outros. Tudo começa privado.
class EditarPerfilPublicoScreen extends StatefulWidget {
  const EditarPerfilPublicoScreen({super.key});

  @override
  State<EditarPerfilPublicoScreen> createState() =>
      _EditarPerfilPublicoScreenState();
}

class _EditarPerfilPublicoScreenState extends State<EditarPerfilPublicoScreen> {
  static const _maximoConquistasDestaque = 6;

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _bioController = TextEditingController();

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  int? _avatarCor;
  String? _avatarUrl;

  // Foto escolhida agora (só é enviada ao tocar em Salvar) ou pedido de remoção.
  Uint8List? _novaFoto;
  String _extensaoFoto = 'jpg';
  bool _removerFoto = false;

  // @usuário: o app confere se está livre enquanto a pessoa digita.
  String? _usuarioOriginal;
  Timer? _esperaUsuario;
  _EstadoUsuario _estadoUsuario = _EstadoUsuario.neutro;

  bool _mostrarPontos = false;
  bool _mostrarSequencia = false;
  bool _mostrarEstatisticas = false;
  bool _mostrarConquistas = false;
  bool _mostrarProjetos = false;
  bool _mostrarGraficoSemana = true;
  Set<String> _conquistasDestaque = {};
  Set<int> _projetosEscolhidos = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _esperaUsuario?.cancel();
    _nomeController.dispose();
    _usuarioController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final social = context.read<SocialState>();
    try {
      // Garante que a linha do perfil existe antes de editar (contas antigas).
      await SocialService.instance.garantirPerfil(
        nome: context.read<AppState>().nomeUsuario ?? 'Estudante',
      );
      await social.carregarMeuPerfil();
      final perfil = social.meuPerfil;
      if (!mounted) return;
      if (perfil == null) {
        setState(() {
          _erro = 'Não encontrei seu perfil no Supabase.';
          _carregando = false;
        });
        return;
      }
      setState(() {
        _nomeController.text = perfil.nome;
        _usuarioController.text = perfil.usuario ?? '';
        _usuarioOriginal = perfil.usuario;
        _bioController.text = perfil.bio;
        _avatarCor = perfil.avatarCor;
        _avatarUrl = perfil.avatarUrl;
        _mostrarPontos = perfil.mostrarPontos;
        _mostrarSequencia = perfil.mostrarSequencia;
        _mostrarEstatisticas = perfil.mostrarEstatisticas;
        _mostrarConquistas = perfil.mostrarConquistas;
        _mostrarProjetos = perfil.mostrarProjetos;
        _mostrarGraficoSemana = perfil.mostrarGraficoSemana;
        _conquistasDestaque = perfil.conquistasDestaque.toSet();
        _projetosEscolhidos = {...social.projetosPublicados};
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = SocialService.traduzirErro(e);
        _carregando = false;
      });
    }
  }

  /// Confere (com uma pequena espera após parar de digitar) se o @ está livre.
  void _aoMudarUsuario(String texto) {
    _esperaUsuario?.cancel();
    final usuario = texto.trim().toLowerCase();
    if (usuario == _usuarioOriginal ||
        !_padraoUsuario.hasMatch(usuario)) {
      setState(() => _estadoUsuario = _EstadoUsuario.neutro);
      return;
    }
    setState(() => _estadoUsuario = _EstadoUsuario.verificando);
    _esperaUsuario = Timer(const Duration(milliseconds: 500), () async {
      try {
        final livre = await SocialService.instance.usuarioDisponivel(usuario);
        if (!mounted || _usuarioController.text.trim().toLowerCase() != usuario) {
          return;
        }
        setState(() => _estadoUsuario =
            livre ? _EstadoUsuario.livre : _EstadoUsuario.ocupado);
      } catch (_) {
        // Sem internet: não bloqueia; o banco confere de novo ao salvar.
        if (mounted) setState(() => _estadoUsuario = _EstadoUsuario.neutro);
      }
    });
  }

  Future<void> _salvar() async {
    if (_formKey.currentState?.validate() != true || _salvando) return;
    final app = context.read<AppState>();
    final social = context.read<SocialState>();

    final usuario = _usuarioController.text.trim().toLowerCase();
    if (usuario != _usuarioOriginal) {
      // Confere de novo na hora de salvar (alguém pode ter pegado o @ agora).
      try {
        if (!await SocialService.instance.usuarioDisponivel(usuario)) {
          if (!mounted) return;
          setState(() => _estadoUsuario = _EstadoUsuario.ocupado);
          _formKey.currentState?.validate();
          return;
        }
      } catch (_) {
        // Falha de rede: segue; o índice único do banco é a garantia final.
      }
    }
    // Só conquistas que a pessoa realmente desbloqueou podem ser destacadas.
    final destaque = _conquistasDestaque
        .where(app.conquistasDesbloqueadas.contains)
        .toList();

    final perfil = PerfilEditavel(
      nome: _nomeController.text.trim(),
      usuario: usuario,
      bio: _bioController.text.trim(),
      avatarCor: _avatarCor,
      avatarUrl: _avatarUrl,
      mostrarPontos: _mostrarPontos,
      mostrarSequencia: _mostrarSequencia,
      mostrarEstatisticas: _mostrarEstatisticas,
      mostrarConquistas: _mostrarConquistas,
      mostrarProjetos: _mostrarProjetos,
      mostrarGraficoSemana: _mostrarGraficoSemana,
      conquistasDestaque: destaque,
    );

    setState(() => _salvando = true);
    try {
      await social.salvarMeuPerfil(
        perfil: perfil,
        // Com "mostrar projetos" desligado, a política do banco já esconde os
        // cartões; a escolha é mantida para quando a pessoa ligar de novo.
        projetosEscolhidos: _projetosEscolhidos,
        app: app,
        novaFoto: _novaFoto,
        extensaoFoto: _extensaoFoto,
        removerFoto: _removerFoto,
      );
      await app.atualizarNome(perfil.nome);
      await social.sincronizar(app, forcar: true);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      mostrarMensagem(context, SocialService.traduzirErro(e));
    }
  }

  static const _tamanhoMaximoFoto = 2 * 1024 * 1024; // 2 MB, igual ao bucket

  Future<void> _escolherFoto() async {
    try {
      // No celular a própria galeria já reduz a imagem (512 px). No Windows o
      // seletor não reduz, por isso o limite de tamanho logo abaixo.
      final arquivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (arquivo == null) return;
      final bytes = await arquivo.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _tamanhoMaximoFoto) {
        mostrarMensagem(context, 'Imagem grande demais. Escolha uma de até 2 MB.');
        return;
      }
      final nome = arquivo.name.toLowerCase();
      setState(() {
        _novaFoto = bytes;
        _extensaoFoto = nome.endsWith('.png')
            ? 'png'
            : nome.endsWith('.webp')
                ? 'webp'
                : 'jpg';
        _removerFoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      mostrarMensagem(context, 'Não foi possível abrir a imagem: $e');
    }
  }

  void _removerFotoAtual() {
    setState(() {
      _novaFoto = null;
      _removerFoto = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil público')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_erro!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _carregar,
                          child: const Text('Tentar de novo'),
                        ),
                      ],
                    ),
                  ),
                )
              : _formulario(context),
    );
  }

  Widget _formulario(BuildContext context) {
    final app = context.watch<AppState>();
    final tokens = context.coresApp;
    final legenda = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: tokens.textoSecundario);

    final liberadas = conquistasDisponiveis
        .where((c) => app.conquistasDesbloqueadas.contains(c.id))
        .toList();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TituloSecao('Identidade'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nomeController,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _usuarioController,
            maxLength: 20,
            autocorrect: false,
            onChanged: _aoMudarUsuario,
            decoration: InputDecoration(
              labelText: 'Nome de usuário (@)',
              prefixText: '@',
              helperText: switch (_estadoUsuario) {
                _EstadoUsuario.verificando => 'Conferindo se está livre...',
                _EstadoUsuario.livre => 'Disponível ✓',
                _ => 'Letras minúsculas, números e _ (3 a 20). Precisa ser '
                    'único.',
              },
            ),
            validator: (v) {
              final texto = (v ?? '').trim().toLowerCase();
              if (texto.isEmpty) return 'Escolha um @ para o seu perfil';
              if (!_padraoUsuario.hasMatch(texto)) {
                return 'Use 3 a 20 letras minúsculas, números ou _';
              }
              if (texto != _usuarioOriginal &&
                  _estadoUsuario == _EstadoUsuario.ocupado) {
                return 'Esse @ já está em uso. Tente outro.';
              }
              return null;
            },
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _bioController,
            maxLength: 160,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              hintText: 'Conte em uma frase o que você estuda',
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          Text('Foto e cor do avatar', style: legenda),
          const SizedBox(height: 12),
          Row(
            children: [
              AvatarUsuario(
                nome: _nomeController.text,
                cor: _avatarCor,
                imagem: _novaFoto != null ? MemoryImage(_novaFoto!) : null,
                imagemUrl: _removerFoto ? null : _avatarUrl,
                raio: 36,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _escolherFoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Escolher foto'),
                    ),
                    if (_novaFoto != null ||
                        (_avatarUrl != null && !_removerFoto))
                      TextButton(
                        onPressed: _removerFotoAtual,
                        child: const Text('Remover foto'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Sem foto, o avatar usa a inicial do nome sobre esta cor:',
              style: legenda),
          const SizedBox(height: 10),
          SeletorDeCor(
            corAtual: _avatarCor,
            permitirPadrao: true,
            aoEscolher: (cor) => setState(() => _avatarCor = cor),
          ),
          const SizedBox(height: 28),
          const TituloSecao('O que os outros podem ver'),
          const SizedBox(height: 4),
          Text(
            'Quase tudo começa desligado (só o gráfico da semana vem ligado). '
            'Seu nome e sua descrição são sempre públicos; o resto só aparece '
            'se você ligar. Tarefas e anotações nunca são enviadas.',
            style: legenda,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pontos e nível'),
            value: _mostrarPontos,
            onChanged: (v) => setState(() => _mostrarPontos = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Gráfico de pontos da semana'),
            subtitle: const Text('Pequeno gráfico de segunda a domingo'),
            value: _mostrarGraficoSemana,
            onChanged: (v) => setState(() => _mostrarGraficoSemana = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sequência de dias'),
            value: _mostrarSequencia,
            onChanged: (v) => setState(() => _mostrarSequencia = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Estatísticas de estudo'),
            subtitle: const Text(
                'Quantidade de anotações, tarefas e projetos concluídos'),
            value: _mostrarEstatisticas,
            onChanged: (v) => setState(() => _mostrarEstatisticas = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Conquistas em destaque'),
            value: _mostrarConquistas,
            onChanged: (v) => setState(() => _mostrarConquistas = v),
          ),
          if (_mostrarConquistas) ...[
            const SizedBox(height: 4),
            if (liberadas.isEmpty)
              Text('Você ainda não desbloqueou conquistas.', style: legenda)
            else ...[
              Text(
                'Escolha até $_maximoConquistasDestaque para destacar:',
                style: legenda,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final Conquista c in liberadas)
                    FilterChip(
                      label: Text(c.nome),
                      selected: _conquistasDestaque.contains(c.id),
                      onSelected: (marcou) => setState(() {
                        if (!marcou) {
                          _conquistasDestaque.remove(c.id);
                        } else if (_conquistasDestaque.length <
                            _maximoConquistasDestaque) {
                          _conquistasDestaque.add(c.id);
                        }
                      }),
                    ),
                ],
              ),
            ],
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Projetos escolhidos'),
            subtitle: const Text('Só nome, cor e progresso — sem tarefas'),
            value: _mostrarProjetos,
            onChanged: (v) => setState(() => _mostrarProjetos = v),
          ),
          if (_mostrarProjetos) ...[
            if (app.projetos.isEmpty)
              Text('Você ainda não criou projetos.', style: legenda)
            else
              for (final projeto in app.projetos)
                if (projeto.id != null)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(projeto.nome),
                    value: _projetosEscolhidos.contains(projeto.id),
                    onChanged: (marcou) => setState(() {
                      if (marcou == true) {
                        _projetosEscolhidos.add(projeto.id!);
                      } else {
                        _projetosEscolhidos.remove(projeto.id);
                      }
                    }),
                  ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
