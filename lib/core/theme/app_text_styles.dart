import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typographie "Haute Couture Éditoriale" — StyleConnect
/// Playfair Display (Titres & Prestige) + Inter (Corps, Données & Précision)
abstract final class AppTextStyles {
  // ── Display ─────────────────────────────────────────────────────────────
  /// 36px / 700 / -0.02em — Titres héros éditoriaux
  static TextStyle get displayLg => GoogleFonts.playfairDisplay(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
    letterSpacing: -0.5,
  );

  // ── Headlines ────────────────────────────────────────────────────────────
  /// 28px / 700 — Titres d'écrans majeurs
  static TextStyle get headlineLg => GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    letterSpacing: -0.3,
  );

  /// 24px / 700 — Titres mobile (dashboard greeting, etc.)
  static TextStyle get headlineLgMobile => GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    letterSpacing: -0.2,
  );

  /// 20px / 700 — Titres moyens
  static TextStyle get headlineMd => GoogleFonts.playfairDisplay(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 28 / 20,
  );

  /// 18px / 600 — Titres petits
  static TextStyle get headlineSm => GoogleFonts.playfairDisplay(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 26 / 18,
  );

  // ── Titles (Inter) ───────────────────────────────────────────────────────
  /// 18px / 700 — Titres de sections (Commandes Récentes, Priorités...)
  static TextStyle get titleMd => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 26 / 18,
    letterSpacing: -0.2,
  );

  /// 15px / 600 — Noms clients dans les cartes
  static TextStyle get titleSm => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 22 / 15,
  );

  // ── Body ─────────────────────────────────────────────────────────────────
  /// 15px / 400 — Texte courant
  static TextStyle get bodyLg => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
  );

  /// 13px / 400 — Texte secondaire, descriptions
  static TextStyle get bodySm => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
  );

  // ── Labels ───────────────────────────────────────────────────────────────
  /// 11px / 700 / 0.08em uppercase — Badges, boutons, tags statutaires
  static TextStyle get labelCaps => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 14 / 11,
    letterSpacing: 0.8,
  );

  /// 10px / 700 / 0.08em uppercase — Micro-labels status, tags
  static TextStyle get labelXs => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 12 / 10,
    letterSpacing: 0.8,
  );

  // ── Chiffres clés (Atelier Metrics) ───────────────────────────────────────
  /// 32px / 800 — Bento Stat cards
  static TextStyle get statNumber => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 38 / 32,
    letterSpacing: -0.5,
  );

  /// Prix FCFA — 15px / 700
  static TextStyle get priceLabel => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 22 / 15,
  );

  // ── Thème global ─────────────────────────────────────────────────────────
  /// TextTheme complet pour [ThemeData].
  ///
  /// Sans lui, tout widget qui lit `Theme.of(context).textTheme.*` retombe sur
  /// la police par défaut (Roboto) et sort de la charte. Les échelles
  /// reprennent celles des getters ci-dessus pour ne rien changer à l'existant.
  static TextTheme textThemeFor(Color onSurface, Color onSurfaceVariant) =>
      TextTheme(
        displayLarge: displayLg.copyWith(color: onSurface),
        displayMedium: displayLg.copyWith(color: onSurface),
        displaySmall: headlineLg.copyWith(color: onSurface),
        headlineLarge: headlineLg.copyWith(color: onSurface),
        headlineMedium: headlineLgMobile.copyWith(color: onSurface),
        headlineSmall: headlineSm.copyWith(color: onSurface),
        titleLarge: titleMd.copyWith(color: onSurface),
        titleMedium: titleSm.copyWith(color: onSurface),
        titleSmall: titleSm.copyWith(color: onSurfaceVariant),
        bodyLarge: bodyLg.copyWith(color: onSurface),
        bodyMedium: bodyLg.copyWith(color: onSurfaceVariant),
        bodySmall: bodySm.copyWith(color: onSurfaceVariant),
        labelLarge: labelCaps.copyWith(color: onSurface),
        labelMedium: labelCaps.copyWith(color: onSurfaceVariant),
        labelSmall: labelXs.copyWith(color: onSurfaceVariant),
      );
}
