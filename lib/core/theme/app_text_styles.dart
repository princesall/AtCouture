import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typographie Stitch — Manrope (corps) + Hanken Grotesk (labels)
abstract final class AppTextStyles {
  // ── Display ─────────────────────────────────────────────────────────────
  /// 40px / 800 / -0.02em — Titres héros
  static TextStyle get displayLg => GoogleFonts.manrope(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 48 / 40,
    letterSpacing: -0.8,
  );

  // ── Headlines ────────────────────────────────────────────────────────────
  /// 30px / 700 — Titres desktop
  static TextStyle get headlineLg => GoogleFonts.manrope(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 38 / 30,
  );

  /// 24px / 700 — Titres mobile (dashboard greeting, etc.)
  static TextStyle get headlineLgMobile => GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
  );

  /// 22px / 700 — Titres moyens
  static TextStyle get headlineMd => GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 30 / 22,
  );

  /// 18px / 700 — Titres petits
  static TextStyle get headlineSm => GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 26 / 18,
  );

  // ── Titles ───────────────────────────────────────────────────────────────
  /// 20px / 600 — Titres de section
  static TextStyle get titleMd => GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );

  /// 16px / 600 — Sous-titres / noms clients dans les cartes
  static TextStyle get titleSm => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
  );

  // ── Body ─────────────────────────────────────────────────────────────────
  /// 16px / 400 — Texte courant
  static TextStyle get bodyLg => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  /// 14px / 400 — Texte secondaire, descriptions
  static TextStyle get bodySm => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  // ── Labels (Hanken Grotesk) ───────────────────────────────────────────────
  /// 12px / 700 / 0.05em uppercase — Badges, nav labels, tags
  static TextStyle get labelCaps => GoogleFonts.hankenGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 16 / 12,
    letterSpacing: 0.6,
  );

  /// 10px / 700 / 0.06em uppercase — Micro-labels status, prix FCFA
  static TextStyle get labelXs => GoogleFonts.hankenGrotesk(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 14 / 10,
    letterSpacing: 0.6,
  );

  // ── Chiffres clés ─────────────────────────────────────────────────────────
  /// 36px / 800 — Stat cards (14, 28, 8.4M…)
  static TextStyle get statNumber => GoogleFonts.manrope(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 44 / 36,
    letterSpacing: -0.02 * 36,
  );

  /// Prix FCFA — 16px / 600
  static TextStyle get priceLabel => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
  );
}
