import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/auth_service.dart';
import '../data/social_state.dart';
import '../widgets/dialogo_projeto.dart';

import 'anotacao_editor_screen.dart';
import 'configuracoes_screen.dart';
import 'estudos_screen.dart';
import 'feed_screen.dart';
import 'home_screen.dart';
import 'perfil_screen.dart';

const _abaInicio = 0;
const _abaFeed = 1;
const _abaEstudos = 2;
const _abaPerfil = 3;

class NavegacaoPrincipal extends StatefulWidget {
  const NavegacaoPrincipal({super.key});

  @override
  State<NavegacaoPrincipal> createState() => _NavegacaoPrincipalState();
}

class _NavegacaoPrincipalState extends State<NavegacaoPrincipal>
    with WidgetsBindingObserver {
  int _abaAtual = _abaInicio;
  int _abaEstudosInicial = 0;

  // Mantém a estratégia original: o feed só é construído quando é aberto.
  // Assim, a tela existente continua responsável por buscar as publicações.
  bool _feedJaAberto = false;
  bool _perfilJaAberto = false;

  Timer? _relogioDaFila;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || AuthService.instance.usuarioAtual == null) return;
      context.read<SocialState>().carregarMeuPerfil().catchError((_) {});
      _enviarPendencias();
    });

    // Preserva o reenvio automático das ações feitas offline.
    _relogioDaFila =
        Timer.periodic(const Duration(seconds: 45), (_) => _enviarPendencias());
  }

  @override
  void dispose() {
    _relogioDaFila?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) _enviarPendencias();
  }

  void _enviarPendencias() {
    if (!mounted || AuthService.instance.usuarioAtual == null) return;
    context.read<SocialState>().processarFila().catchError((_) {
      return const ResultadoFila();
    });
  }

  void _irPara(int aba) {
    setState(() {
      _abaAtual = aba;
      if (aba == _abaFeed) _feedJaAberto = true;
      if (aba == _abaPerfil) _perfilJaAberto = true;
    });
  }

  void _abrirEstudos(int aba) {
    setState(() {
      _abaEstudosInicial = aba;
      _abaAtual = _abaEstudos;
    });
  }

  void _abrirConfiguracoes() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()),
    );
  }

  void _abrirCriacao() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (contextModal) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('Criar projeto'),
              onTap: () {
                Navigator.of(contextModal).pop();
                abrirDialogoProjeto(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Criar anotação'),
              onTap: () {
                Navigator.of(contextModal).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AnotacaoEditorScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telas = [
      HomeScreen(
        aoTocarProjetos: () => _abrirEstudos(0),
        aoTocarAnotacoes: () => _abrirEstudos(1),
        aoTocarConfiguracoes: _abrirConfiguracoes,
      ),
      _feedJaAberto
          ? FeedScreen(aoTocarConfiguracoes: _abrirConfiguracoes)
          : const SizedBox.shrink(),
      EstudosScreen(
        key: ValueKey(_abaEstudosInicial),
        abaInicial: _abaEstudosInicial,
        aoTocarConfiguracoes: _abrirConfiguracoes,
      ),
      _perfilJaAberto
          ? PerfilScreen(
              aoTocarConfiguracoes: _abrirConfiguracoes,
            )
          : const SizedBox.shrink(),
    ];

    return Scaffold(
      body: IndexedStack(index: _abaAtual, children: telas),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Transform.translate(
        // Desce mais 4 px em relação ao ajuste anterior (12 px).
        offset: const Offset(0, 16),
        child: FloatingActionButton(
          onPressed: _abrirCriacao,
          tooltip: 'Criar projeto ou anotação',
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _ItemNavegacao(
                icone: Icons.home_outlined,
                iconeSelecionado: Icons.home,
                titulo: 'Início',
                selecionado: _abaAtual == _abaInicio,
                aoTocar: () => _irPara(_abaInicio),
              ),
              _ItemNavegacao(
                icone: Icons.dynamic_feed_outlined,
                iconeSelecionado: Icons.dynamic_feed,
                titulo: 'Feed',
                selecionado: _abaAtual == _abaFeed,
                aoTocar: () => _irPara(_abaFeed),
              ),
              const SizedBox(width: 64),
              _ItemNavegacao(
                icone: Icons.menu_book_outlined,
                iconeSelecionado: Icons.menu_book,
                titulo: 'Estudos',
                selecionado: _abaAtual == _abaEstudos,
                aoTocar: () => _irPara(_abaEstudos),
              ),
              _ItemNavegacao(
                icone: Icons.person_outline,
                iconeSelecionado: Icons.person,
                titulo: 'Perfil',
                selecionado: _abaAtual == _abaPerfil,
                aoTocar: () => _irPara(_abaPerfil),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemNavegacao extends StatelessWidget {
  final IconData icone;
  final IconData iconeSelecionado;
  final String titulo;
  final bool selecionado;
  final VoidCallback aoTocar;

  const _ItemNavegacao({
    required this.icone,
    required this.iconeSelecionado,
    required this.titulo,
    required this.selecionado,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final cor = selecionado ? cores.primary : cores.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selecionado ? iconeSelecionado : icone,
                color: cor,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                titulo,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cor,
                      fontWeight:
                          selecionado ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
