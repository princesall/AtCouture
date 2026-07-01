import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        // Primaire — Indigo
        primary:              AppColors.primary,
        onPrimary:            AppColors.onPrimary,
        primaryContainer:     AppColors.primaryContainer,
        onPrimaryContainer:   AppColors.onPrimaryContainer,
        // Secondaire — Terracotta
        secondary:            AppColors.secondary,
        onSecondary:          AppColors.onSecondary,
        secondaryContainer:   AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        // Tertiaire — Or
        tertiary:             AppColors.tertiary,
        onTertiary:           AppColors.onTertiary,
        tertiaryContainer:    AppColors.tertiaryContainer,
        onTertiaryContainer:  AppColors.onTertiaryContainer,
        // Erreur
        error:                AppColors.error,
        onError:              AppColors.onError,
        errorContainer:       AppColors.errorContainer,
        onErrorContainer:     AppColors.onErrorContainer,
        // Surfaces
        surface:              AppColors.surface,
        onSurface:            AppColors.onSurface,
        onSurfaceVariant:     AppColors.onSurfaceVariant,
        outline:              AppColors.outline,
        outlineVariant:       AppColors.outlineVariant,
        inverseSurface:       AppColors.inverseSurface,
        onInverseSurface:     AppColors.inverseOnSurface,
        inversePrimary:       AppColors.inversePrimary,
        surfaceTint:          AppColors.surfaceTint,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primary),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceContainerLowest),
        ),
        margin: EdgeInsets.zero,
      ),
      // ── ElevatedButton — Indigo primary ──────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
      // ── OutlinedButton — Ghost terracotta ────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondary,
          side: const BorderSide(color: AppColors.secondary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
      // ── TextButton ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          textStyle: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
      // ── InputDecoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5), width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: GoogleFonts.manrope(
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.hankenGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      // ── BottomNavigationBar ──────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        selectedLabelStyle: GoogleFonts.hankenGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        unselectedLabelStyle: GoogleFonts.hankenGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 0.5,
        space: 0,
      ),
      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        labelStyle: GoogleFonts.hankenGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inverseSurface,
        contentTextStyle: GoogleFonts.manrope(
          color: AppColors.inverseOnSurface,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
