import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_state.dart';
import 'screens/porta_de_entrada.dart';

void main() {
  runApp(const AppEstudos());
}

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
            themeMode: appState.tema,
            theme: _temaClaro(),
            darkTheme: _temaEscuro(),
            home: const PortaDeEntrada(),
          );
        },
      ),
    );
  }

  ThemeData _temaClaro() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  ThemeData _temaEscuro() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8B9CFF),
        secondary: Color(0xFF8B9CFF),
        surface: Color(0xFF1C1C1E),
        background: Color(0xFF000000),
        onPrimary: Colors.white,
        onSurface: Color(0xFFE5E5EA),
        onBackground: Color(0xFFE5E5EA),
      ),
      scaffoldBackgroundColor: const Color(0xFF000000),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF1C1C1E),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF000000),
        foregroundColor: Color(0xFFE5E5EA),
      ),
      dividerColor: const Color(0xFF2C2C2E),
    );
  }
}