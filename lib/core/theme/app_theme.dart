import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_color_palette.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(const AppColorsLight(), Brightness.light);
  static ThemeData get dark => _build(const AppColorsDark(), Brightness.dark);

  static ThemeData _build(AppColorPalette c, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary:              c.primary,
        onPrimary:            c.onPrimary,
        primaryContainer:     c.primaryContainer,
        onPrimaryContainer:   c.onPrimaryContainer,
        secondary:            c.secondary,
        onSecondary:          c.onSecondary,
        secondaryContainer:   c.secondaryContainer,
        onSecondaryContainer: c.onSecondaryContainer,
        tertiary:             c.tertiary,
        onTertiary:           c.onTertiary,
        tertiaryContainer:    c.tertiaryContainer,
        onTertiaryContainer:  c.onTertiaryContainer,
        error:                c.error,
        onError:              c.onError,
        errorContainer:       c.errorContainer,
        onErrorContainer:     c.onErrorContainer,
        surface:              c.surface,
        onSurface:            c.onSurface,
        onSurfaceVariant:     c.onSurfaceVariant,
        outline:              c.outline,
        outlineVariant:       c.outlineVariant,
        inverseSurface:       c.inverseSurface,
        onInverseSurface:     c.inverseOnSurface,
        inversePrimary:       c.inversePrimary,
        surfaceTint:          c.surfaceTint,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      textTheme: AppTextStyles.textThemeFor(c.onSurface, c.onSurfaceVariant),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: c.onSurface),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: c.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.outlineVariant, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.onSurface,
          side: BorderSide(color: c.outlineVariant, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.goldInk,
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.outlineVariant, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.outlineVariant, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.error, width: 1),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: c.onSurfaceVariant.withValues(alpha: 0.7),
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: c.onSurfaceVariant,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surfaceContainerLowest,
        elevation: 0,
        selectedItemColor: c.primary,
        unselectedItemColor: c.onSurfaceVariant,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: c.outlineVariant,
        thickness: 0.8,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceContainerLow,
        labelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: c.outlineVariant, width: 0.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.inverseSurface,
        contentTextStyle: GoogleFonts.inter(
          color: c.inverseOnSurface,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
