import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Voice — Vedic Oasis Design System
/// Colors, typography, and component styles extracted from Stitch MCP screens.
class AppTheme {
  AppTheme._();

  // ── Brand Colors (from Stitch design system) ──────────────────────

  // Primary — Warm Saffron
  static const Color primary = Color(0xFF855300);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFF59E0B);
  static const Color onPrimaryContainer = Color(0xFF613B00);

  // Secondary — Forest Green
  static const Color secondary = Color(0xFF1B6D24);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFA0F399);
  static const Color onSecondaryContainer = Color(0xFF217128);

  // Tertiary — Warm Coral
  static const Color tertiary = Color(0xFFA33D23);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFF9479);
  static const Color onTertiaryContainer = Color(0xFF7F230B);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Surfaces
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceVariant = Color(0xFFD9E3F4);
  static const Color onSurface = Color(0xFF121C28);
  static const Color onSurfaceVariant = Color(0xFF534434);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDFE9FA);
  static const Color surfaceContainerHighest = Color(0xFFD9E3F4);
  static const Color surfaceContainerLow = Color(0xFFEEF4FF);
  static const Color background = Color(0xFFF8F9FF);
  static const Color onBackground = Color(0xFF121C28);

  // Outlines
  static const Color outline = Color(0xFF867461);
  static const Color outlineVariant = Color(0xFFD8C3AD);

  // ── Light Color Scheme ────────────────────────────────────────────

  static ColorScheme get lightColorScheme => const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      );

  // ── Text Theme (Inter — from Stitch) ──────────────────────────────

  static TextTheme get _textTheme => TextTheme(
        // display-lg: 40px / 48px / 700 / -0.02em
        displayLarge: GoogleFonts.inter(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          height: 48 / 40,
          letterSpacing: -0.8,
        ),
        // headline-lg: 28px / 36px / 600 / -0.01em
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 36 / 28,
          letterSpacing: -0.28,
        ),
        // headline-lg-mobile: 24px / 32px / 600
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 32 / 24,
        ),
        // title-lg: 20px / 28px / 600
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 28 / 20,
        ),
        // body-lg: 16px / 24px / 400
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 24 / 16,
        ),
        // body-md: 14px / 20px / 400
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 20 / 14,
        ),
        // label-lg: 14px / 20px / 500 / 0.1px
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 20 / 14,
          letterSpacing: 0.1,
        ),
        // label-sm: 11px / 16px / 500 / 0.5px
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 16 / 11,
          letterSpacing: 0.5,
        ),
      );

  // ── ThemeData ─────────────────────────────────────────────────────

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        textTheme: _textTheme,
        scaffoldBackgroundColor: background,

        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: primary,
          ),
          iconTheme: const IconThemeData(color: onSurfaceVariant),
        ),

        // Cards — 16px/20px radius, soft elevation
        cardTheme: CardThemeData(
          color: surfaceContainerLowest,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
        ),

        // Chips — pill shape for filter chips
        chipTheme: ChipThemeData(
          backgroundColor: surfaceContainerLowest,
          selectedColor: primaryContainer,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          side: const BorderSide(color: outlineVariant),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),

        // FloatingActionButton — 16px radius, saffron
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimaryContainer,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),

        // Input fields — outlined with 16px radius
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceContainerLowest,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryContainer, width: 2),
          ),
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: onSurfaceVariant,
          ),
        ),

        // BottomNav — matches Stitch design
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surfaceContainerLowest,
          selectedItemColor: onPrimaryContainer,
          unselectedItemColor: onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),

        // Elevated buttons — primary style
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: onPrimary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Outlined buttons
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: onSurface,
            minimumSize: const Size(0, 56),
            side: const BorderSide(color: outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: outlineVariant,
          thickness: 1,
          space: 0,
        ),
      );

  // ── Shadows (matching Stitch "shadow-soft" and "shadow-floating") ─

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
