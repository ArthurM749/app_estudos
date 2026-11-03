import 'package:flutter/material.dart';

class AppPalette {
  AppPalette._();

  static const Color lightBackground = Color(0xFFD9D9D9);
  static const Color lightSurface = Color(0xFFF0F0F0);
  static const Color lightCard = Color(0xFFEAEAEA);
  static const Color lightText = Color(0xFF0D0D0D);
  static const Color lightMuted = Color(0xFF737373);
  static const Color lightBorder = Color.fromARGB(255, 185, 184, 184);
  static const Color graphite = Color.fromARGB(255, 17, 17, 17);

  static const Color darkBackground = Color(0xFF0A0B0D);
  static const Color darkSurface = Color(0xFF1A1E26);
  static const Color darkCard = Color(0xFF1A1E26);
  static const Color slateBlue = Color(0xFF536173);
  static const Color paleSlateBlue = Color(0xFF8593A6);
  static const Color darkText = Color(0xFFE2E6EC);
  static const Color darkMuted = Color(0xFF8593A6);
  static const Color darkBorder = Color(0xFF536173);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colors = ColorScheme.light(
      primary: AppPalette.graphite,
      onPrimary: AppPalette.lightSurface,
      primaryContainer: AppPalette.lightBorder,
      onPrimaryContainer: AppPalette.lightText,
      secondary: AppPalette.lightMuted,
      onSecondary: AppPalette.lightSurface,
      secondaryContainer: AppPalette.lightBackground,
      onSecondaryContainer: AppPalette.lightText,
      tertiary: AppPalette.graphite,
      onTertiary: AppPalette.lightSurface,
      error: AppPalette.graphite,
      onError: AppPalette.lightSurface,
      surface: AppPalette.lightSurface,
      onSurface: AppPalette.lightText,
      onSurfaceVariant: AppPalette.graphite,
      outline: AppPalette.lightMuted,
      outlineVariant: AppPalette.lightBorder,
      inverseSurface: AppPalette.graphite,
      onInverseSurface: AppPalette.lightSurface,
      inversePrimary: AppPalette.lightBackground,
      surfaceTint: AppPalette.graphite,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colors,
      scaffoldBackgroundColor: AppPalette.lightBackground,
      canvasColor: AppPalette.lightBackground,
      cardColor: AppPalette.lightCard,
      dividerColor: AppPalette.lightBorder.withOpacity(0.65),
      shadowColor: const Color(0x22000000),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.lightBackground,
        foregroundColor: AppPalette.lightText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppPalette.lightSurface,
        indicatorColor: AppPalette.lightBackground,
        elevation: 0,
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>((states) {
          final selected = states.contains(MaterialState.selected);
          return TextStyle(
            color: selected ? AppPalette.graphite : AppPalette.lightMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith<IconThemeData?>((states) {
          final selected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: selected ? AppPalette.graphite : AppPalette.lightMuted,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.graphite,
          foregroundColor: AppPalette.lightSurface,
          disabledBackgroundColor: AppPalette.lightBorder,
          disabledForegroundColor: AppPalette.lightMuted,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.graphite,
          side: const BorderSide(color: AppPalette.lightMuted),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.lightSurface,
        labelStyle: const TextStyle(color: AppPalette.lightMuted),
        hintStyle: const TextStyle(color: AppPalette.lightMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.graphite, width: 1.6),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.lightBorder,
        thickness: 0.7,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.graphite,
        linearTrackColor: AppPalette.lightBorder,
        circularTrackColor: AppPalette.lightBorder,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppPalette.graphite,
        inactiveTrackColor: AppPalette.lightBorder,
        thumbColor: AppPalette.graphite,
        overlayColor: Color(0x1F404040),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppPalette.graphite,
        selectionColor: Color(0x55404040),
        selectionHandleColor: AppPalette.graphite,
      ),
    );
  }

  static ThemeData get dark {
    const colors = ColorScheme.dark(
      primary: AppPalette.darkText,
      onPrimary: AppPalette.darkBackground,
      primaryContainer: AppPalette.darkSurface,
      onPrimaryContainer: AppPalette.darkText,
      secondary: AppPalette.slateBlue,
      onSecondary: AppPalette.darkText,
      secondaryContainer: AppPalette.darkSurface,
      onSecondaryContainer: AppPalette.darkText,
      tertiary: AppPalette.paleSlateBlue,
      onTertiary: AppPalette.darkBackground,
      error: AppPalette.paleSlateBlue,
      onError: AppPalette.darkBackground,
      surface: AppPalette.darkSurface,
      onSurface: AppPalette.darkText,
      onSurfaceVariant: AppPalette.darkMuted,
      outline: AppPalette.slateBlue,
      outlineVariant: AppPalette.slateBlue,
      inverseSurface: AppPalette.darkText,
      onInverseSurface: AppPalette.darkBackground,
      inversePrimary: AppPalette.paleSlateBlue,
      surfaceTint: AppPalette.darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colors,
      scaffoldBackgroundColor: AppPalette.darkBackground,
      canvasColor: AppPalette.darkBackground,
      cardColor: AppPalette.darkCard,
      dividerColor: AppPalette.darkBorder.withOpacity(0.35),
      shadowColor: const Color(0x99000000),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.darkBackground,
        foregroundColor: AppPalette.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppPalette.darkBackground,
        indicatorColor: AppPalette.darkSurface,
        elevation: 0,
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>((states) {
          final selected = states.contains(MaterialState.selected);
          return TextStyle(
            color: selected ? AppPalette.darkText : AppPalette.darkMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith<IconThemeData?>((states) {
          final selected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: selected ? AppPalette.darkText : AppPalette.darkMuted,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.darkText,
          foregroundColor: AppPalette.darkBackground,
          disabledBackgroundColor: AppPalette.darkBorder,
          disabledForegroundColor: AppPalette.darkMuted,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.darkText,
          side: const BorderSide(color: AppPalette.slateBlue),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppPalette.darkMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.darkCard,
        labelStyle: const TextStyle(color: AppPalette.darkMuted),
        hintStyle: const TextStyle(color: AppPalette.darkMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppPalette.paleSlateBlue, width: 1.6),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppPalette.darkBorder.withOpacity(0.35),
        thickness: 0.7,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.paleSlateBlue,
        linearTrackColor: AppPalette.slateBlue,
        circularTrackColor: AppPalette.slateBlue,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppPalette.paleSlateBlue,
        inactiveTrackColor: AppPalette.slateBlue,
        thumbColor: AppPalette.paleSlateBlue,
        overlayColor: Color(0x338593A6),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppPalette.paleSlateBlue,
        selectionColor: Color(0x558593A6),
        selectionHandleColor: AppPalette.paleSlateBlue,
      ),
    );
  }
}
