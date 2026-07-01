import 'package:flutter/material.dart';

/// Palette "Indigo-Or-Terre" — Design system Stitch StyleConnect
/// Remplace l'ancienne palette or/noir de AppColors
abstract final class AppColors {
  // ── Fonds ──────────────────────────────────────────────────────────────
  static const Color background           = Color(0xFFF7F9FF);
  static const Color surface              = Color(0xFFF7F9FF);
  static const Color surfaceBright        = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow  = Color(0xFFF1F4FB);
  static const Color surfaceContainer     = Color(0xFFEBEEF5);
  static const Color surfaceContainerHigh = Color(0xFFE5E8EF);
  static const Color surfaceContainerHighest = Color(0xFFDFE2E9);
  static const Color surfaceDim           = Color(0xFFD7DAE1);

  // ── Texte sur fond ─────────────────────────────────────────────────────
  static const Color onSurface            = Color(0xFF181C21);
  static const Color onSurfaceVariant     = Color(0xFF454650);
  static const Color inverseSurface       = Color(0xFF2D3136);
  static const Color inverseOnSurface     = Color(0xFFEEF1F8);

  // ── Contours ────────────────────────────────────────────────────────────
  static const Color outline              = Color(0xFF767681);
  static const Color outlineVariant       = Color(0xFFC6C5D1);

  // ── Primaire — Indigo Profond ───────────────────────────────────────────
  static const Color primary              = Color(0xFF131F5D);
  static const Color onPrimary            = Color(0xFFFFFFFF);
  static const Color primaryContainer     = Color(0xFF2B3674);
  static const Color onPrimaryContainer   = Color(0xFF97A1E7);
  static const Color inversePrimary       = Color(0xFFBAC3FF);
  static const Color primaryFixed         = Color(0xFFDEE0FF);
  static const Color primaryFixedDim      = Color(0xFFBAC3FF);
  static const Color onPrimaryFixed       = Color(0xFF061353);
  static const Color onPrimaryFixedVariant = Color(0xFF374280);
  static const Color surfaceTint          = Color(0xFF4F5A9A);

  // ── Secondaire — Terre Cuite (Terracotta) ──────────────────────────────
  static const Color secondary            = Color(0xFF94492C);
  static const Color onSecondary          = Color(0xFFFFFFFF);
  static const Color secondaryContainer   = Color(0xFFFE9D7A);
  static const Color onSecondaryContainer = Color(0xFF773318);
  static const Color secondaryFixed       = Color(0xFFFFDBCF);
  static const Color secondaryFixedDim    = Color(0xFFFFB59B);
  static const Color onSecondaryFixed     = Color(0xFF380D00);
  static const Color onSecondaryFixedVariant = Color(0xFF763217);

  // ── Tertiaire — Or Royal ────────────────────────────────────────────────
  static const Color tertiary             = Color(0xFF735C00);
  static const Color onTertiary           = Color(0xFFFFFFFF);
  static const Color tertiaryContainer    = Color(0xFFCCA730);
  static const Color onTertiaryContainer  = Color(0xFF4F3E00);
  static const Color tertiaryFixed        = Color(0xFFFFE088);
  static const Color tertiaryFixedDim     = Color(0xFFE9C349);
  static const Color onTertiaryFixed      = Color(0xFF241A00);
  static const Color onTertiaryFixedVariant = Color(0xFF574500);

  // ── Erreur ──────────────────────────────────────────────────────────────
  static const Color error                = Color(0xFFBA1A1A);
  static const Color onError              = Color(0xFFFFFFFF);
  static const Color errorContainer       = Color(0xFFFFDAD6);
  static const Color onErrorContainer     = Color(0xFF93000A);

  // ── Statuts commandes ───────────────────────────────────────────────────
  static const Color statusPending        = Color(0xFF4F5A9A); // Indigo soft
  static const Color statusPendingBg      = Color(0xFFDEE0FF);
  static const Color statusInProgress     = Color(0xFFFF9500);
  static const Color statusInProgressBg   = Color(0xFFFFEDD5);
  static const Color statusDone           = Color(0xFF34C759);
  static const Color statusDoneBg         = Color(0xFFDCFCE7);
  static const Color statusProblem        = Color(0xFFBA1A1A);
  static const Color statusProblemBg      = Color(0xFFFFDAD6);

  // ── Ombres premium ──────────────────────────────────────────────────────
  static const Color shadowPrimary        = Color(0x102B3674); // rgba(43,54,116,.06)
  static const Color shadowCard           = Color(0x0A2B3674); // rgba(43,54,116,.04)

  // ── Dégradés ────────────────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tertiaryFixed, tertiaryContainer],
  );

  // ── Raccourcis pratiques ─────────────────────────────────────────────────
  /// Fond blanc pur pour les cartes
  static const Color cardSurface          = surfaceContainerLowest;

  /// Ombre douce pour les cartes — BoxShadow à utiliser avec spread/blur
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(color: shadowPrimary, blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -4),
    BoxShadow(color: shadowCard,    blurRadius:  8, offset: const Offset(0, 4), spreadRadius: -4),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(color: const Color(0x0D000000), blurRadius: 8, offset: const Offset(0, 2)),
  ];
}
