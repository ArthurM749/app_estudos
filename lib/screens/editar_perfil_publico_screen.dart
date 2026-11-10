import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/social_service.dart';
import '../data/social_state.dart';
import '../models/conquista.dart';
import '../models/perfil_social.dart';
import '../theme/app_cores.dart';
import '../utils/mensagens.dart';
import '../widgets/dialogo_projeto.dart' show coresDeProjeto;
import '../widgets/titulo_secao.dart';

final _padraoUsuario = RegExp(r'^[a-z0-9_]{3,20}$');

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
  bool _mostrarPontos = false;
  bool _mostrarSequencia = false;
  bool _mostrarEstatisticas = false;
  bool _mostrarConquistas = false;
  bool _mostrarProjetos = false;
  Set<String> _conquistasDestaque = {};
  Set<int> _projetosEscolhidos = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
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
        _bioController.text = perfil.bio;
        _avatarCor = perfil.avatarCor;
        _mostrarPontos = perfil.mostrarPontos;
        _mostrarSequencia = perfil.mostrarSequencia;
        _mostrarEstatisticas = perfil.mostrarEstatisticas;
        _mostrarConquistas = perfil.mostrarConquistas;
        _mostrarProjetos = perfil.mostrarProjetos;
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

  Future<void> _salvar() async {
    if (_formKey.currentState?.validate() != true || _salvando) return;
    final app = context.read<AppState>();
    final social = context.read<SocialState>();

    final usuario = _usuarioController.text.trim().toLowerCase();
    // Só conquistas que a pessoa realmente desbloqueou podem ser destacadas.
    final destaque = _conquistasDestaque
        .where(app.conquistasDesbloqueadas.contains)
        .toList();

    final perfil = PerfilEditavel(
      nome: _nomeController.text.trim(),
      usuario: usuario.isEmpty ? null : usuario,
      bio: _bioController.text.trim(),
      avatarCor: _avatarCor,
      mostrarPontos: _mostrarPontos,
      mostrarSequencia: _mostrarSequencia,
      mostrarEstatisticas: _mostrarEstatisticas,
      mostrarConquistas: _mostrarConquistas,
      mostrarProjetos: _mostrarProjetos,
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
            decoration: const InputDecoration(
              labelText: 'Nome de usuário (opcional)',
              prefixText: '@',
              helperText: 'Letras minúsculas, números e _ (3 a 20 caracteres)',
            ),
            validator: (v) {
              final texto = (v ?? '').trim().toLowerCase();
              if (texto.isEmpty) return null;
              return _padraoUsuario.hasMatch(texto)
                  ? null
                  : 'Use 3 a 20 letras minúsculas, números ou _';
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
          Text('Cor do avatar', style: legenda),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              GestureDetector(
                onTap: () => setState(() => _avatarCor = null),
                child: CircleAvatar(
                  radius: _avatarCor == null ? 18 : 14,
                  backgroundColor: tokens.avatarFundo,
                  child: _avatarCor == null
                      ? Icon(Icons.check, size: 16, color: tokens.avatarTexto)
                      : null,
                ),
              ),
              for (final cor in coresDeProjeto)
                GestureDetector(
                  onTap: () => setState(() => _avatarCor = cor.toARGB32()),
                  child: CircleAvatar(
                    radius: _avatarCor == cor.toARGB32() ? 18 : 14,
                    backgroundColor: cor,
                    child: _avatarCor == cor.toARGB32()
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: cor.computeLuminance() > 0.45
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          const TituloSecao('O que os outros podem ver'),
          const SizedBox(height: 4),
          Text(
            'Tudo começa desligado. Seu nome e sua descrição são sempre '
            'públicos; o resto só aparece se você ligar. Tarefas e anotações '
            'nunca são enviadas.',
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
