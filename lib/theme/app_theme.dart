import 'package:flutter/material.dart';

class AppTheme {
  // Available color palettes seeds
  static const List<Map<String, dynamic>> palettes = [
    {
      'name': 'Kampüs Klasik',
      'seed': Color(0xFF1E3A8A), // Indigo
      'secondary': Color(0xFF0D9488), // Teal
    },
    {
      'name': 'Zümrüt Ormanı',
      'seed': Color(0xFF065F46), // Emerald
      'secondary': Color(0xFF10B981), // Mint Green
    },
    {
      'name': 'Derin Okyanus',
      'seed': Color(0xFF0284C7), // Light Blue
      'secondary': Color(0xFF0891B2), // Cyan
    },
    {
      'name': 'Lavanta Bahçesi',
      'seed': Color(0xFF6D28D9), // Purple
      'secondary': Color(0xFFDB2777), // Pink
    },
  ];

  static ThemeData buildTheme({
    required bool isDark,
    required int paletteIndex,
  }) {
    final palette = palettes[
      paletteIndex >= 0 && paletteIndex < palettes.length ? paletteIndex : 0
    ];
    final seedColor = palette['seed'] as Color;
    final secondaryColor = palette['secondary'] as Color;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      secondary: secondaryColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark 
          ? colorScheme.surface
          : Colors.grey.shade50, // Slightly off-white soft background
      
      cardTheme: CardThemeData(
        elevation: isDark ? 2 : 1,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}
