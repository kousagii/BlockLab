import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF2858C6),
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFFAAC7FF) : const Color(0xFF2858C6),
          onPrimary: dark ? const Color(0xFF092A62) : Colors.white,
          surface: dark ? const Color(0xFF172338) : Colors.white,
          onSurface: dark ? const Color(0xFFE8EEF8) : const Color(0xFF18243A),
          onSurfaceVariant: dark
              ? const Color(0xFFB7C4D9)
              : const Color(0xFF52617A),
          outlineVariant: dark
              ? const Color(0xFF34445E)
              : const Color(0xFFD9E1EF),
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF101A2B)
          : const Color(0xFFF6F8FC),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        bodyLarge: TextStyle(fontSize: 17, height: 1.5),
        bodyMedium: TextStyle(fontSize: 16, height: 1.45),
        bodySmall: TextStyle(fontSize: 13, height: 1.4),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? const Color(0xFF101A2B)
            : const Color(0xFFF6F8FC),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(side: BorderSide(color: scheme.outlineVariant)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 24),
    );
  }
}
