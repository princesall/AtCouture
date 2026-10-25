import 'package:flutter/material.dart';

import '../theme/build_context_colors.dart';

/// Ébène et champagne du panneau de marque — couleurs fixes, volontairement
/// indépendantes du thème : le contraste blanc sur ébène reste garanti en mode
/// clair comme en mode sombre (là où `c.primary` s'inversait).
const kAuthEbony = Color(0xFF121212);
const kAuthChampagne = Color(0xFFC5A880);

/// Fond des écrans d'authentification — toile ivoire « Haute Couture
/// Éditoriale » : pas de photo, pas de verre dépoli, juste le fond ivoire de
/// la palette réchauffé par un voile d'or très discret en haut à gauche.
///
/// Le texte de marque se pose donc sur clair : il doit utiliser les couleurs
/// de la palette (`onSurface`, `goldInk`) et non du blanc.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: c.background),
        // Voile d'or : donne de la profondeur au fond sans jamais gêner la
        // lecture (10 % au centre, transparent en bordure).
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.8, -0.9),
              radius: 1.3,
              colors: [
                c.tertiary.withValues(alpha: 0.10),
                c.background.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Monogramme de marque — badge blanc portant le symbole SC (Style·Connect).
/// Sert de repère visuel identique sur les écrans de connexion/inscription.
class BrandMonogram extends StatelessWidget {
  const BrandMonogram({super.key, this.size = 60});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(size * 0.3),
        // Bordure 1px couture au lieu de l'ancien halo doré.
        border: Border.all(color: c.outlineVariant, width: 1),
        boxShadow: c.softShadow,
      ),
      child: Image.asset(
        'assets/branding/logo_mark_transparent.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
