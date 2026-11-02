import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'data/app_state.dart';
import 'screens/porta_de_entrada.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const AppEstudos());
}

/// Raiz do app. Nome provisório — o grupo ainda não bateu o martelo
/// no nome final (ver "Riscos e decisões em aberto" no documento).
class AppEstudos extends StatelessWidget {
  const AppEstudos({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..carregar(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'App de Estudos',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorSchemeSeed: Colors.indigo,
              brightness: Brightness.light,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorSchemeSeed: Colors.indigo,
              brightness: Brightness.dark,
              useMaterial3: true,
            ),
            themeMode: appState.tema,
            home: const PortaDeEntrada(),
          );
        },
      ),
    );
  }
}
