import 'package:flutter/material.dart';

import '../data/social_service.dart';
import '../models/perfil_social.dart';
import '../theme/app_cores.dart';
import '../widgets/avatar_usuario.dart';
import 'perfil_publico_screen.dart';

enum ModoLista { seguidores, seguindo, busca }

/// Lista de pessoas: quem segue o perfil, quem ele segue, ou o resultado de
/// uma busca por nome/@usuario.
class ListaPessoasScreen extends StatefulWidget {
  final ModoLista modo;

  /// Dono da lista (obrigatório em seguidores/seguindo).
  final String? usuarioId;

  const ListaPessoasScreen({super.key, required this.modo, this.usuarioId})
      : assert(modo == ModoLista.busca || usuarioId != null);

  @override
  State<ListaPessoasScreen> createState() => _ListaPessoasScreenState();
}

class _ListaPessoasScreenState extends State<ListaPessoasScreen> {
  final _buscaController = TextEditingController();

  List<PerfilResumo> _pessoas = [];
  bool _carregando = false;
  bool _buscou = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    if (widget.modo != ModoLista.busca) _carregar();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final servico = SocialService.instance;
      final lista = switch (widget.modo) {
        ModoLista.seguidores => await servico.listarSeguidores(widget.usuarioId!),
        ModoLista.seguindo => await servico.listarSeguindo(widget.usuarioId!),
        ModoLista.busca => await servico.buscarPessoas(_buscaController.text),
      };
      if (!mounted) return;
      setState(() {
        _pessoas = lista;
        _carregando = false;
        _buscou = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = SocialService.traduzirErro(e);
        _carregando = false;
      });
    }
  }

  String get _titulo {
    switch (widget.modo) {
      case ModoLista.seguidores:
        return 'Seguidores';
      case ModoLista.seguindo:
        return 'Seguindo';
      case ModoLista.busca:
        return 'Buscar pessoas';
    }
  }

  String get _mensagemVazia {
    switch (widget.modo) {
      case ModoLista.seguidores:
        return 'Ninguém segue este perfil ainda.';
      case ModoLista.seguindo:
        return 'Este perfil ainda não segue ninguém.';
      case ModoLista.busca:
        return _buscou
            ? 'Ninguém encontrado. Tente outro nome ou @usuário.'
            : 'Digite pelo menos 2 letras do nome ou do @usuário.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.coresApp;
    return Scaffold(
      appBar: AppBar(title: Text(_titulo)),
      body: Column(
        children: [
          if (widget.modo == ModoLista.busca)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _buscaController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _carregar(),
                decoration: InputDecoration(
                  hintText: 'Nome ou @usuário',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  suffixIcon: IconButton(
                    tooltip: 'Buscar',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _carregar,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_erro!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: tokens.perigo)),
                        ),
                      )
                    : _pessoas.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _mensagemVazia,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: tokens.textoSecundario),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _pessoas.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, indice) {
                              final pessoa = _pessoas[indice];
                              return ListTile(
                                leading: AvatarUsuario(
                                  nome: pessoa.nome,
                                  cor: pessoa.avatarCor,
                                ),
                                title: Text(pessoa.nome),
                                subtitle: pessoa.usuario != null
                                    ? Text('@${pessoa.usuario}')
                                    : null,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PerfilPublicoScreen(
                                        usuarioId: pessoa.id),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
