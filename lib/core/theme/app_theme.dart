import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system for Guardian Circle.
///
/// The theme is designed for clear readability:
/// - Dark text on light backgrounds
/// - Large, accessible text
/// - Clear buttons and input fields
/// - Consistent cards and app bars
class AppTheme {
  AppTheme._();

  // Main Guardian Circle colors
  static const Color primary = Color(0xFF1F3A5F);
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

    // ------------------------------------------------------------
    // TEXT THEME
    // ------------------------------------------------------------
    //
    // Explicit colors are used here so text never becomes
    // white/light on a white background.
    //
    final textTheme = GoogleFonts.interTextTheme(
      base.textTheme,
    ).copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),

      headlineMedium: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),

      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),

      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),

      bodyLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: Colors.black87,
      ),

      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: Colors.black87,
      ),

      labelLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );

    return base.copyWith(
      // ------------------------------------------------------------
      // GLOBAL TEXT
      // ------------------------------------------------------------
      textTheme: textTheme,

      // ------------------------------------------------------------
      // APP BAR
      // ------------------------------------------------------------
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),

      // ------------------------------------------------------------
      // CARDS
      // ------------------------------------------------------------
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFFE7E9EC),
          ),
        ),
      ),

      // ------------------------------------------------------------
      // INPUT FIELDS
      // ------------------------------------------------------------
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(
          color: Colors.black54,
        ),

        floatingLabelStyle: TextStyle(
          color: primary,
        ),

        hintStyle: TextStyle(
          color: Colors.black45,
        ),

        border: OutlineInputBorder(),

        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFFCBD2DA),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: primary,
            width: 2,
          ),
        ),
      ),

      // ------------------------------------------------------------
      // ELEVATED BUTTONS
      // ------------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          textStyle: textTheme.labelLarge,

          foregroundColor: Colors.white,
          backgroundColor: primary,
        ),
      ),

      // ------------------------------------------------------------
      // OUTLINED BUTTONS
      // ------------------------------------------------------------
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          side: const BorderSide(
            color: Color(0xFFCBD2DA),
            width: 1.5,
          ),

          textStyle: textTheme.labelLarge,

          foregroundColor: primary,
        ),
      ),

      // ------------------------------------------------------------
      // ICONS
      // ------------------------------------------------------------
      iconTheme: const IconThemeData(
        color: Colors.black87,
      ),
    );
  }
}