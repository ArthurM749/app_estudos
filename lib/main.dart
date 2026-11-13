import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'data/app_state.dart';
import 'data/social_state.dart';
import 'screens/porta_de_entrada.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    // Sem rede (ou configuração errada) o app ainda abre: a parte offline não
    // depende do Supabase. Login e feed é que ficam indisponíveis.
    debugPrint('Falha ao iniciar o Supabase: $e');
  }
  runApp(const AppEstudos());
}

class AppEstudos extends StatelessWidget {
  const AppEstudos({super.key});

  @override
  Widget build(BuildContext context) {
    // O SocialState é separado do AppState: a parte social depende de internet e
    // pode falhar sem afetar nada do que funciona offline.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..carregar()),
        ChangeNotifierProvider(create: (_) => SocialState()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'QuestNoter',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: appState.tema,
            home: const PortaDeEntrada(),
          );
        },
      ),
    );
  }
}
