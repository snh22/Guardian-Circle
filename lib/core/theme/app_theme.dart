import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system. Tuned for two audiences at once: stressed
/// caregivers who need to parse status in under a second, and (in the
/// companion-app parts of the same codebase) elderly users who need large,
/// unambiguous touch targets.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1F3A5F); // deep steady blue
  static const Color surface = Color(0xFFF7F8FA);
  static const Color onSurfaceMuted = Color(0xFF5B6472);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surface,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      // Deliberately large defaults — accessibility over density.
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w400, height: 1.4),
      bodyMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, height: 1.4),
      labelLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE7E9EC)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56), // large tap target
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: Color(0xFFCBD2DA), width: 1.5),
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }
}