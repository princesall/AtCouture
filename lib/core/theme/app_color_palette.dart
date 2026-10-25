import 'package:flutter/material.dart';

/// Contrat commun aux palettes claire et sombre — mêmes noms de champs que
/// AppColors pour une utilisation fluide via `context.colors.x`.
abstract class AppColorPalette {
  // ── Fonds ──────────────────────────────────────────────────────────────
  Color get background;
  Color get surface;
  Color get surfaceBright;
  Color get surfaceContainerLowest;
  Color get surfaceContainerLow;
  Color get surfaceContainer;
  Color get surfaceContainerHigh;
  Color get surfaceContainerHighest;
  Color get surfaceDim;

  // ── Texte sur fond ─────────────────────────────────────────────────────
  Color get onSurface;
  Color get onSurfaceVariant;
  Color get inverseSurface;
  Color get inverseOnSurface;

  // ── Contours ────────────────────────────────────────────────────────────
  Color get outline;
  Color get outlineVariant;

  // ── Primaire — Noir Ébène ───────────────────────────────────────────────
  Color get primary;
  Color get onPrimary;
  Color get primaryContainer;
  Color get onPrimaryContainer;
  Color get inversePrimary;
  Color get primaryFixed;
  Color get primaryFixedDim;
  Color get onPrimaryFixed;
  Color get onPrimaryFixedVariant;
  Color get surfaceTint;

  // ── Secondaire — Cuir & Bronze ──────────────────────────────────────────
  Color get secondary;
  Color get onSecondary;
  Color get secondaryContainer;
  Color get onSecondaryContainer;
  Color get secondaryFixed;
  Color get secondaryFixedDim;
  Color get onSecondaryFixed;
  Color get onSecondaryFixedVariant;

  // ── Tertiaire — Or Champagne Brossé ────────────────────────────────────
  Color get tertiary;
  Color get onTertiary;
  Color get tertiaryContainer;
  Color get onTertiaryContainer;
  Color get tertiaryFixed;
  Color get tertiaryFixedDim;
  Color get onTertiaryFixed;
  Color get onTertiaryFixedVariant;

  // ── Erreur ──────────────────────────────────────────────────────────────
  Color get error;
  Color get onError;
  Color get errorContainer;
  Color get onErrorContainer;

  // ── Statuts commandes (Atelier haute couture) ───────────────────────────
  Color get statusPending;
  Color get statusPendingBg;
  Color get statusInProgress;
  Color get statusInProgressBg;
  Color get statusDone;
  Color get statusDoneBg;
  Color get statusProblem;
  Color get statusProblemBg;

  // ── Utilitaires ───────────────────────────────────────────────────────────
  Color get success;
  Color get cardSurface;

  /// Or de lecture — variante d'or suffisamment contrastée pour porter du
  /// texte ou des icônes (l'or champagne [tertiary] est réservé à la
  /// décoration : bordures, dégradés, aplats).
  Color get goldInk;

  // ── Dégradés & ombres ─────────────────────────────────────────────────────
  LinearGradient get heroGradient;
  LinearGradient get goldGradient;
  List<BoxShadow> get premiumShadow;
  List<BoxShadow> get softShadow;
}

/// Palette Claire "Haute Couture Éditoriale" (Ivoire Soie & Noir Ébène)
class AppColorsLight implements AppColorPalette {
  const AppColorsLight();

  @override
  Color get background => const Color(0xFFFBFBF9);
  @override
  Color get surface => const Color(0xFFFBFBF9);
  @override
  Color get surfaceBright => const Color(0xFFFFFFFF);
  @override
  Color get surfaceContainerLowest => const Color(0xFFFFFFFF);
  @override
  Color get surfaceContainerLow => const Color(0xFFF3F1EC);
  @override
  Color get surfaceContainer => const Color(0xFFEBE8E1);
  @override
  Color get surfaceContainerHigh => const Color(0xFFE2DDD4);
  @override
  Color get surfaceContainerHighest => const Color(0xFFD9D3C8);
  @override
  Color get surfaceDim => const Color(0xFFCECAC7);

  @override
  Color get onSurface => const Color(0xFF121212);
  @override
  Color get onSurfaceVariant => const Color(0xFF63626C);
  @override
  Color get inverseSurface => const Color(0xFF1C1C1F);
  @override
  Color get inverseOnSurface => const Color(0xFFF7F7F5);

  @override
  Color get outline => const Color(0xFF8A8894);
  @override
  Color get outlineVariant => const Color(0xFFE5E2DA);

  @override
  Color get primary => const Color(0xFF121212);
  @override
  Color get onPrimary => const Color(0xFFFFFFFF);
  @override
  Color get primaryContainer => const Color(0xFF222227);
  @override
  Color get onPrimaryContainer => const Color(0xFFEAEAEA);
  @override
  Color get inversePrimary => const Color(0xFFFFFFFF);
  @override
  Color get primaryFixed => const Color(0xFFEBEAE6);
  @override
  Color get primaryFixedDim => const Color(0xFFD6D4CD);
  @override
  Color get onPrimaryFixed => const Color(0xFF121212);
  @override
  Color get onPrimaryFixedVariant => const Color(0xFF2C2C32);
  @override
  Color get surfaceTint => const Color(0xFFC5A880);

  @override
  Color get secondary => const Color(0xFF8A5A36);
  @override
  Color get onSecondary => const Color(0xFFFFFFFF);
  @override
  Color get secondaryContainer => const Color(0xFFF4E8DE);
  @override
  Color get onSecondaryContainer => const Color(0xFF432611);
  @override
  Color get secondaryFixed => const Color(0xFFF8ECE2);
  @override
  Color get secondaryFixedDim => const Color(0xFFE8D4C2);
  @override
  Color get onSecondaryFixed => const Color(0xFF301A09);
  @override
  Color get onSecondaryFixedVariant => const Color(0xFF6B4223);

  @override
  Color get tertiary => const Color(0xFFC5A880);
  @override
  Color get onTertiary => const Color(0xFFFFFFFF);
  @override
  Color get tertiaryContainer => const Color(0xFFF7EFE3);
  @override
  Color get onTertiaryContainer => const Color(0xFF533F23);
  @override
  Color get tertiaryFixed => const Color(0xFFFBF4EA);
  @override
  Color get tertiaryFixedDim => const Color(0xFFEAD8C1);
  @override
  Color get onTertiaryFixed => const Color(0xFF382912);
  @override
  Color get onTertiaryFixedVariant => const Color(0xFF7A5C2D);

  @override
  Color get error => const Color(0xFFB3261E);
  @override
  Color get onError => const Color(0xFFFFFFFF);
  @override
  Color get errorContainer => const Color(0xFFFCE8E6);
  @override
  Color get onErrorContainer => const Color(0xFF601410);

  @override
  Color get statusPending => const Color(0xFF5E6577);
  @override
  Color get statusPendingBg => const Color(0xFFF0F1F5);
  @override
  Color get statusInProgress => const Color(0xFF96631C);
  @override
  Color get statusInProgressBg => const Color(0xFFFAF3E8);
  @override
  Color get statusDone => const Color(0xFF1B6B46);
  @override
  Color get statusDoneBg => const Color(0xFFEBF6F0);
  @override
  Color get statusProblem => const Color(0xFFB3261E);
  @override
  Color get statusProblemBg => const Color(0xFFFCE8E6);

  @override
  Color get success => const Color(0xFF1B6B46);
  @override
  Color get cardSurface => surfaceContainerLowest;
  @override
  Color get goldInk => const Color(0xFF7A5C2D);

  @override
  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryContainer],
      );

  @override
  LinearGradient get goldGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC5A880), Color(0xFFB38E5D)],
      );

  @override
  List<BoxShadow> get premiumShadow => [
        const BoxShadow(color: Color(0x0C000000), blurRadius: 20, offset: Offset(0, 6), spreadRadius: -2),
        const BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2), spreadRadius: 0),
      ];

  @override
  List<BoxShadow> get softShadow => [
        const BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
      ];
}

/// Palette Sombre "Haute Couture Nocturne" (Onyx & Or Lumineux)
class AppColorsDark implements AppColorPalette {
  const AppColorsDark();

  @override
  Color get background => const Color(0xFF0E0E11);
  @override
  Color get surface => const Color(0xFF0E0E11);
  @override
  Color get surfaceBright => const Color(0xFF1E1E24);
  @override
  Color get surfaceContainerLowest => const Color(0xFF151518);
  @override
  Color get surfaceContainerLow => const Color(0xFF1A1A1E);
  @override
  Color get surfaceContainer => const Color(0xFF222227);
  @override
  Color get surfaceContainerHigh => const Color(0xFF2B2B32);
  @override
  Color get surfaceContainerHighest => const Color(0xFF35353D);
  @override
  Color get surfaceDim => const Color(0xFF09090B);

  @override
  Color get onSurface => const Color(0xFFF7F7F5);
  @override
  Color get onSurfaceVariant => const Color(0xFFA1A1AA);
  @override
  Color get inverseSurface => const Color(0xFFF7F7F5);
  @override
  Color get inverseOnSurface => const Color(0xFF121214);

  @override
  Color get outline => const Color(0xFF71717A);
  @override
  Color get outlineVariant => const Color(0xFF27272A);

  @override
  Color get primary => const Color(0xFFF7F7F5);
  @override
  Color get onPrimary => const Color(0xFF121214);
  @override
  Color get primaryContainer => const Color(0xFF24242A);
  @override
  Color get onPrimaryContainer => const Color(0xFFFFFFFF);
  @override
  Color get inversePrimary => const Color(0xFF121214);
  @override
  Color get primaryFixed => const Color(0xFFEBEAE6);
  @override
  Color get primaryFixedDim => const Color(0xFFD6D4CD);
  @override
  Color get onPrimaryFixed => const Color(0xFF121214);
  @override
  Color get onPrimaryFixedVariant => const Color(0xFF2C2C32);
  @override
  Color get surfaceTint => const Color(0xFFD4AF37);

  @override
  Color get secondary => const Color(0xFFD49B6A);
  @override
  Color get onSecondary => const Color(0xFF351B06);
  @override
  Color get secondaryContainer => const Color(0xFF4E2C0F);
  @override
  Color get onSecondaryContainer => const Color(0xFFF8ECE2);
  @override
  Color get secondaryFixed => const Color(0xFFF8ECE2);
  @override
  Color get secondaryFixedDim => const Color(0xFFE8D4C2);
  @override
  Color get onSecondaryFixed => const Color(0xFF301A09);
  @override
  Color get onSecondaryFixedVariant => const Color(0xFF6B4223);

  @override
  Color get tertiary => const Color(0xFFD4AF37);
  @override
  Color get onTertiary => const Color(0xFF2E2204);
  @override
  Color get tertiaryContainer => const Color(0xFF4A380A);
  @override
  Color get onTertiaryContainer => const Color(0xFFFBF4EA);
  @override
  Color get tertiaryFixed => const Color(0xFFFBF4EA);
  @override
  Color get tertiaryFixedDim => const Color(0xFFEAD8C1);
  @override
  Color get onTertiaryFixed => const Color(0xFF382912);
  @override
  Color get onTertiaryFixedVariant => const Color(0xFF7A5C2D);

  @override
  Color get error => const Color(0xFFFFB4AB);
  @override
  Color get onError => const Color(0xFF690005);
  @override
  Color get errorContainer => const Color(0xFF93000A);
  @override
  Color get onErrorContainer => const Color(0xFFFFDAD6);

  @override
  Color get statusPending => const Color(0xFFB0B7C6);
  @override
  Color get statusPendingBg => const Color(0xFF222630);
  @override
  Color get statusInProgress => const Color(0xFFFFC078);
  @override
  Color get statusInProgressBg => const Color(0xFF38240D);
  @override
  Color get statusDone => const Color(0xFF6EDB8F);
  @override
  Color get statusDoneBg => const Color(0xFF10331A);
  @override
  Color get statusProblem => const Color(0xFFFFB4AB);
  @override
  Color get statusProblemBg => const Color(0xFF44120F);

  @override
  Color get success => const Color(0xFF6EDB8F);
  @override
  Color get cardSurface => surfaceContainerLowest;
  @override
  Color get goldInk => const Color(0xFFD4AF37);

  @override
  LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF222227), Color(0xFF141416)],
      );

  @override
  LinearGradient get goldGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE5C365), Color(0xFFB38E5D)],
      );

  @override
  List<BoxShadow> get premiumShadow => [
        const BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 6), spreadRadius: -2),
        const BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2), spreadRadius: 0),
      ];

  @override
  List<BoxShadow> get softShadow => [
        const BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
      ];
}
