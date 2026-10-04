import 'package:flutter/material.dart';

abstract final class ProviderTheme {
  static const muted = Color(0xFF64748B);
  static const teal = Color(0xFF0F766E);
  static const surface = Color(0xFFFFFFFF);
  static const navy = Color(0xFF0F172A);
  static const body = Color(0xFF111827);
  static const background = Color(0xFFF8FAFC);
  static const tealLight = Color(0xFFE6F6F4);
  static const border = Color(0xFFE2E8F0);
  static const orangeBorder = Color(0xFFFED7AA);
  static const warningBackground = Color(0xFFFFF7ED);
  static const grey = Color(0xFF6B7280);
  static const orange = Color(0xFFC2410C);
  static const green = Color(0xFF15803D);
  static const red = Color(0xFFB91C1C);

  static ThemeData get data => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: teal,
      primary: teal,
      surface: surface,
      error: red,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: navy,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: navy,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: navy,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(color: body, fontSize: 14),
      bodySmall: TextStyle(color: muted, fontSize: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: navy,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: navy,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: tealLight,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, color: muted),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: border),
  );
}
