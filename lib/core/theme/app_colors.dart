import 'package:flutter/material.dart';

/// Palette "Haute Couture Éditoriale" — StyleConnect
/// Noir Ébène, Blanc Pur, Ivoire Soie & Or Champagne Brossé
abstract final class AppColors {
  // ── Fonds ──────────────────────────────────────────────────────────────
  /// Fond ivoire soie noble (substitue le bleu froid Material)
  static const Color background           = Color(0xFFFBFBF9);
  static const Color surface              = Color(0xFFFBFBF9);
  static const Color surfaceBright        = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // Blanc pur carte
  static const Color surfaceContainerLow  = Color(0xFFF3F1EC);
  static const Color surfaceContainer     = Color(0xFFEBE8E1);
  static const Color surfaceContainerHigh = Color(0xFFE2DDD4);
  static const Color surfaceContainerHighest = Color(0xFFD9D3C8);
  static const Color surfaceDim           = Color(0xFFCECAC7);

  // ── Texte sur fond ─────────────────────────────────────────────────────
  static const Color onSurface            = Color(0xFF121212); // Noir Ébène
  static const Color onSurfaceVariant     = Color(0xFF63626C); // Ardoise raffinée
  static const Color inverseSurface       = Color(0xFF1C1C1F);
  static const Color inverseOnSurface     = Color(0xFFF7F7F5);

  // ── Contours ────────────────────────────────────────────────────────────
  static const Color outline              = Color(0xFF8A8894);
  static const Color outlineVariant       = Color(0xFFE5E2DA); // Ligne fine 1px couture

  // ── Primaire — Noir Ébène Couture ───────────────────────────────────────
  static const Color primary              = Color(0xFF121212);
  static const Color onPrimary            = Color(0xFFFFFFFF);
  static const Color primaryContainer     = Color(0xFF222227);
  static const Color onPrimaryContainer   = Color(0xFFEAEAEA);
  static const Color inversePrimary       = Color(0xFFFFFFFF);
  static const Color primaryFixed         = Color(0xFFEBEAE6);
  static const Color primaryFixedDim      = Color(0xFFD6D4CD);
  static const Color onPrimaryFixed       = Color(0xFF121212);
  static const Color onPrimaryFixedVariant = Color(0xFF2C2C32);
  static const Color surfaceTint          = Color(0xFFC5A880);

  // ── Secondaire — Cuir & Bronze Chaleureux ──────────────────────────────
  static const Color secondary            = Color(0xFF8A5A36);
  static const Color onSecondary          = Color(0xFFFFFFFF);
  static const Color secondaryContainer   = Color(0xFFF4E8DE);
  static const Color onSecondaryContainer = Color(0xFF432611);
  static const Color secondaryFixed       = Color(0xFFF8ECE2);
  static const Color secondaryFixedDim    = Color(0xFFE8D4C2);
  static const Color onSecondaryFixed     = Color(0xFF301A09);
  static const Color onSecondaryFixedVariant = Color(0xFF6B4223);

  // ── Tertiaire — Or Champagne Brossé ────────────────────────────────────
  static const Color tertiary             = Color(0xFFC5A880); // Or Champagne Brossé
  static const Color onTertiary           = Color(0xFFFFFFFF);
  static const Color tertiaryContainer    = Color(0xFFF7EFE3);
  static const Color onTertiaryContainer  = Color(0xFF533F23);
  static const Color tertiaryFixed        = Color(0xFFFBF4EA);
  static const Color tertiaryFixedDim     = Color(0xFFEAD8C1);
  static const Color onTertiaryFixed      = Color(0xFF382912);
  static const Color onTertiaryFixedVariant = Color(0xFF7A5C2D);

  // ── Erreur ──────────────────────────────────────────────────────────────
  static const Color error                = Color(0xFFB3261E);
  static const Color onError              = Color(0xFFFFFFFF);
  static const Color errorContainer       = Color(0xFFFCE8E6);
  static const Color onErrorContainer     = Color(0xFF601410);

  // ── Statuts commandes (Élégance atelier) ─────────────────────────────────
  static const Color statusPending        = Color(0xFF5E6577); // Ardoise mesure
  static const Color statusPendingBg      = Color(0xFFF0F1F5);
  static const Color statusInProgress     = Color(0xFF96631C); // Caramel chaud confection
  static const Color statusInProgressBg   = Color(0xFFFAF3E8);
  static const Color statusDone           = Color(0xFF1B6B46); // Vert atelier couture
  static const Color statusDoneBg         = Color(0xFFEBF6F0);
  static const Color statusProblem        = Color(0xFFB3261E); // Rouge signalement
  static const Color statusProblemBg      = Color(0xFFFCE8E6);

  // ── Couleurs utilitaires ─────────────────────────────────────────────────
  static const Color success              = Color(0xFF1B6B46);

  // ── Ombres couture (aérées & transparentes) ─────────────────────────────
  static const Color shadowPrimary        = Color(0x0C000000); // 5% noir pur
  static const Color shadowCard           = Color(0x06000000); // 2.5% noir pur

  // ── Dégradés ────────────────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC5A880), Color(0xFFB38E5D)],
  );

  // ── Raccourcis pratiques ─────────────────────────────────────────────────
  static const Color cardSurface          = surfaceContainerLowest;

  /// Or de lecture — variante contrastée pour porter du texte ou des icônes.
  static const Color goldInk              = Color(0xFF7A5C2D);

  static List<BoxShadow> get premiumShadow => [
    BoxShadow(color: shadowPrimary, blurRadius: 20, offset: const Offset(0, 6), spreadRadius: -2),
    BoxShadow(color: shadowCard,    blurRadius:  6, offset: const Offset(0, 2), spreadRadius: 0),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(color: const Color(0x08000000), blurRadius: 8, offset: const Offset(0, 2)),
  ];
}
