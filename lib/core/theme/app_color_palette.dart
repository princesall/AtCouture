import 'package:flutter/material.dart';

/// Contrat commun aux palettes claire et sombre — mêmes noms de champs que
/// l'ancien AppColors statique (voir app_colors.dart) pour que la migration
/// écran par écran soit un simple remplacement `AppColors.x` → `context.colors.x`.
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

  // ── Primaire — Indigo ───────────────────────────────────────────────────
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

  // ── Secondaire — Terracotta ─────────────────────────────────────────────
  Color get secondary;
  Color get onSecondary;
  Color get secondaryContainer;
  Color get onSecondaryContainer;
  Color get secondaryFixed;
  Color get secondaryFixedDim;
  Color get onSecondaryFixed;
  Color get onSecondaryFixedVariant;

  // ── Tertiaire — Or ──────────────────────────────────────────────────────
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

  // ── Statuts commandes ───────────────────────────────────────────────────
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

  // ── Dégradés & ombres ─────────────────────────────────────────────────────
  LinearGradient get heroGradient;
  LinearGradient get goldGradient;
  List<BoxShadow> get premiumShadow;
  List<BoxShadow> get softShadow;
}

class AppColorsLight implements AppColorPalette {
  const AppColorsLight();

  @override
  Color get background => const Color(0xFFF7F9FF);
  @override
  Color get surface => const Color(0xFFF7F9FF);
  @override
  Color get surfaceBright => const Color(0xFFF7F9FF);
  @override
  Color get surfaceContainerLowest => const Color(0xFFFFFFFF);
  @override
  Color get surfaceContainerLow => const Color(0xFFF1F4FB);
  @override
  Color get surfaceContainer => const Color(0xFFEBEEF5);
  @override
  Color get surfaceContainerHigh => const Color(0xFFE5E8EF);
  @override
  Color get surfaceContainerHighest => const Color(0xFFDFE2E9);
  @override
  Color get surfaceDim => const Color(0xFFD7DAE1);

  @override
  Color get onSurface => const Color(0xFF181C21);
  @override
  Color get onSurfaceVariant => const Color(0xFF454650);
  @override
  Color get inverseSurface => const Color(0xFF2D3136);
  @override
  Color get inverseOnSurface => const Color(0xFFEEF1F8);

  @override
  Color get outline => const Color(0xFF767681);
  @override
  Color get outlineVariant => const Color(0xFFC6C5D1);

  @override
  Color get primary => const Color(0xFF131F5D);
  @override
  Color get onPrimary => const Color(0xFFFFFFFF);
  @override
  Color get primaryContainer => const Color(0xFF2B3674);
  @override
  Color get onPrimaryContainer => const Color(0xFF97A1E7);
  @override
  Color get inversePrimary => const Color(0xFFBAC3FF);
  @override
  Color get primaryFixed => const Color(0xFFDEE0FF);
  @override
  Color get primaryFixedDim => const Color(0xFFBAC3FF);
  @override
  Color get onPrimaryFixed => const Color(0xFF061353);
  @override
  Color get onPrimaryFixedVariant => const Color(0xFF374280);
  @override
  Color get surfaceTint => const Color(0xFF4F5A9A);

  @override
  Color get secondary => const Color(0xFF94492C);
  @override
  Color get onSecondary => const Color(0xFFFFFFFF);
  @override
  Color get secondaryContainer => const Color(0xFFFE9D7A);
  @override
  Color get onSecondaryContainer => const Color(0xFF773318);
  @override
  Color get secondaryFixed => const Color(0xFFFFDBCF);
  @override
  Color get secondaryFixedDim => const Color(0xFFFFB59B);
  @override
  Color get onSecondaryFixed => const Color(0xFF380D00);
  @override
  Color get onSecondaryFixedVariant => const Color(0xFF763217);

  @override
  Color get tertiary => const Color(0xFF735C00);
  @override
  Color get onTertiary => const Color(0xFFFFFFFF);
  @override
  Color get tertiaryContainer => const Color(0xFFCCA730);
  @override
  Color get onTertiaryContainer => const Color(0xFF4F3E00);
  @override
  Color get tertiaryFixed => const Color(0xFFFFE088);
  @override
  Color get tertiaryFixedDim => const Color(0xFFE9C349);
  @override
  Color get onTertiaryFixed => const Color(0xFF241A00);
  @override
  Color get onTertiaryFixedVariant => const Color(0xFF574500);

  @override
  Color get error => const Color(0xFFBA1A1A);
  @override
  Color get onError => const Color(0xFFFFFFFF);
  @override
  Color get errorContainer => const Color(0xFFFFDAD6);
  @override
  Color get onErrorContainer => const Color(0xFF93000A);

  @override
  Color get statusPending => const Color(0xFF4F5A9A);
  @override
  Color get statusPendingBg => const Color(0xFFDEE0FF);
  @override
  Color get statusInProgress => const Color(0xFFFF9500);
  @override
  Color get statusInProgressBg => const Color(0xFFFFEDD5);
  @override
  Color get statusDone => const Color(0xFF34C759);
  @override
  Color get statusDoneBg => const Color(0xFFDCFCE7);
  @override
  Color get statusProblem => const Color(0xFFBA1A1A);
  @override
  Color get statusProblemBg => const Color(0xFFFFDAD6);

  @override
  Color get success => const Color(0xFF34C759);
  @override
  Color get cardSurface => surfaceContainerLowest;

  @override
  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryContainer],
      );

  @override
  LinearGradient get goldGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [tertiaryFixed, tertiaryFixedDim],
      );

  @override
  List<BoxShadow> get premiumShadow => [
        const BoxShadow(color: Color(0x102B3674), blurRadius: 24, offset: Offset(0, 8), spreadRadius: -4),
        const BoxShadow(color: Color(0x0A2B3674), blurRadius: 8, offset: Offset(0, 4), spreadRadius: -4),
      ];

  @override
  List<BoxShadow> get softShadow => [
        const BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
      ];
}

/// Palette sombre — les rôles "Fixed" (primaryFixed, secondaryFixed,
/// tertiaryFixed...) restent VOLONTAIREMENT identiques à la version claire :
/// c'est la convention Material 3 pour les couleurs qui doivent rester
/// stables quel que soit le thème (ex : dégradé or "premium").
class AppColorsDark implements AppColorPalette {
  const AppColorsDark();

  @override
  Color get background => const Color(0xFF10131C);
  @override
  Color get surface => const Color(0xFF10131C);
  @override
  Color get surfaceBright => const Color(0xFF2B2F3A);
  @override
  Color get surfaceContainerLowest => const Color(0xFF0A0C12);
  @override
  Color get surfaceContainerLow => const Color(0xFF171B26);
  @override
  Color get surfaceContainer => const Color(0xFF1C212E);
  @override
  Color get surfaceContainerHigh => const Color(0xFF262B3A);
  @override
  Color get surfaceContainerHighest => const Color(0xFF313746);
  @override
  Color get surfaceDim => const Color(0xFF10131C);

  @override
  Color get onSurface => const Color(0xFFE6E8F2);
  @override
  Color get onSurfaceVariant => const Color(0xFFB7BAC7);
  @override
  Color get inverseSurface => const Color(0xFFE6E8F2);
  @override
  Color get inverseOnSurface => const Color(0xFF181C21);

  @override
  Color get outline => const Color(0xFF8B8D9B);
  @override
  Color get outlineVariant => const Color(0xFF3A3E4C);

  @override
  Color get primary => const Color(0xFFBAC3FF);
  @override
  Color get onPrimary => const Color(0xFF1A2569);
  @override
  Color get primaryContainer => const Color(0xFF2B3674);
  @override
  Color get onPrimaryContainer => const Color(0xFFDEE0FF);
  @override
  Color get inversePrimary => const Color(0xFF131F5D);
  @override
  Color get primaryFixed => const Color(0xFFDEE0FF);
  @override
  Color get primaryFixedDim => const Color(0xFFBAC3FF);
  @override
  Color get onPrimaryFixed => const Color(0xFF061353);
  @override
  Color get onPrimaryFixedVariant => const Color(0xFF374280);
  @override
  Color get surfaceTint => const Color(0xFFBAC3FF);

  @override
  Color get secondary => const Color(0xFFFFB59B);
  @override
  Color get onSecondary => const Color(0xFF5C1F09);
  @override
  Color get secondaryContainer => const Color(0xFF773318);
  @override
  Color get onSecondaryContainer => const Color(0xFFFFDBCF);
  @override
  Color get secondaryFixed => const Color(0xFFFFDBCF);
  @override
  Color get secondaryFixedDim => const Color(0xFFFFB59B);
  @override
  Color get onSecondaryFixed => const Color(0xFF380D00);
  @override
  Color get onSecondaryFixedVariant => const Color(0xFF763217);

  @override
  Color get tertiary => const Color(0xFFE9C349);
  @override
  Color get onTertiary => const Color(0xFF3D2F00);
  @override
  Color get tertiaryContainer => const Color(0xFF574500);
  @override
  Color get onTertiaryContainer => const Color(0xFFFFE088);
  @override
  Color get tertiaryFixed => const Color(0xFFFFE088);
  @override
  Color get tertiaryFixedDim => const Color(0xFFE9C349);
  @override
  Color get onTertiaryFixed => const Color(0xFF241A00);
  @override
  Color get onTertiaryFixedVariant => const Color(0xFF574500);

  @override
  Color get error => const Color(0xFFFFB4AB);
  @override
  Color get onError => const Color(0xFF690005);
  @override
  Color get errorContainer => const Color(0xFF93000A);
  @override
  Color get onErrorContainer => const Color(0xFFFFDAD6);

  @override
  Color get statusPending => const Color(0xFFAEB6FF);
  @override
  Color get statusPendingBg => const Color(0xFF2B3674);
  @override
  Color get statusInProgress => const Color(0xFFFFB74D);
  @override
  Color get statusInProgressBg => const Color(0xFF4D3319);
  @override
  Color get statusDone => const Color(0xFF6EDB8F);
  @override
  Color get statusDoneBg => const Color(0xFF14401F);
  @override
  Color get statusProblem => const Color(0xFFFFB4AB);
  @override
  Color get statusProblemBg => const Color(0xFF5C1712);

  @override
  Color get success => const Color(0xFF6EDB8F);
  @override
  Color get cardSurface => surfaceContainer;

  @override
  LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2B3674), Color(0xFF0A0F30)],
      );

  @override
  LinearGradient get goldGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [tertiaryFixed, tertiaryFixedDim],
      );

  @override
  List<BoxShadow> get premiumShadow => [
        const BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8), spreadRadius: -4),
        const BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 4), spreadRadius: -4),
      ];

  @override
  List<BoxShadow> get softShadow => [
        const BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
      ];
}
