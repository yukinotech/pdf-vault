import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildPdfVaultTheme() {
  const seed = Color(0xFF0E7C86);
  const surface = Color(0xFFF4F0E8);
  const canvas = Color(0xFFFBF7F0);
  const accent = Color(0xFFF0A43A);

  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        surface: surface,
      ).copyWith(
        primary: seed,
        secondary: accent,
        tertiary: const Color(0xFF1A3C5A),
        error: const Color(0xFFB42318),
      );

  final textTheme = GoogleFonts.spaceGroteskTextTheme().copyWith(
    headlineLarge: GoogleFonts.spaceGrotesk(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.05,
      color: colorScheme.onSurface,
    ),
    headlineSmall: GoogleFonts.spaceGrotesk(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
    ),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 14,
      color: colorScheme.onSurfaceVariant,
      height: 1.45,
    ),
    labelLarge: GoogleFonts.dmSans(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: canvas,
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: BorderSide(color: colorScheme.outlineVariant),
        textStyle: textTheme.labelLarge,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
  );
}
