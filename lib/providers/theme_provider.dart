import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Mode Tema Default
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Warna Dasar Default (Teal Emerald)
  Color _seedColor = const Color(0xFF00796B);
  Color get seedColor => _seedColor;

  // Pilihan Warna Seeder Presets yang Bervariasi & Elegan
  static const List<Color> colorPresets = [
    // --- Nuansa Islami & Maskulin / Netral ---
    Color(0xFF00796B), // Emerald Teal (Default - Islami Modern)
    Color(0xFF0288D1), // Ocean Blue (Akademik & Keuangan)
    Color(0xFF2E7D32), // Forest Green (Presensi & Lingkungan)
    Color(0xFF37474F), // Slate Grey (Profesional Minimalis)
    Color(0xFFD84315), // Deep Orange (Energetik / Piket)
    Color(0xFF673AB7), // Deep Purple (Kreatif & Elegan)
    // --- Nuansa Feminin & Soft (Cewek / Santriwati) ---
    Color(0xFFE91E63), // Vibrant Pink (Cerah & Energik)
    Color(0xFFEC407A), // Rose Pink (Lembut & Elegan)
    Color(0xFFAB47BC), // Soft Orchid / Magenta (Feminin Modern)
    Color(0xFFF48FB1), // Soft Blush Pink (Pastel Soft)
    Color(0xFFD81B60), // Deep Rose / Berry (Proffesional Feminin)
    Color(0xFF8E24AA), // Soft Violet / Lavender (Calm & Graceful)
    // --- Nuansa Pastel & Earthy (Segar / Warm) ---
    Color(0xFF00ACC1), // Soft Cyan / Mint (Segar & Bersih)
    Color(0xFFFB8C00), // Warm Peach / Amber (Ramah & Hangat)
    Color(0xFF7CB342), // Sage / Olive Green (Calm & Natural)
    Color(0xFF5C6BC0), // Soft Indigo (Akademik Soft)
  ];

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setSeedColor(Color color) {
    _seedColor = color;
    notifyListeners();
  }

  // --- BUILD LIGHT THEME ---
  ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFF1F5F9),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),

      // Card Style Modern
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),

      // Form & Input Style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),

      // Button Styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1E293B),
      ),
    );
  }

  // --- BUILD DARK THEME (DINAMIS MENGIKUTI SEED COLOR) ---
  ThemeData get darkTheme {
    // Generate ColorScheme Gelap berbasis _seedColor
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      
      // Latar Belakang menggunakan surface dim agar senada dengan seed color
      scaffoldBackgroundColor: colorScheme.surfaceDim,

      // Card Style Modern Dinamis
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(76),
            width: 1,
          ),
        ),
      ),

      // Form & Input Style Dinamis
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),

      // Button Styles Dinamis
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: colorScheme.surfaceDim,
        foregroundColor: colorScheme.onSurface,
      ),
    );
  }
}