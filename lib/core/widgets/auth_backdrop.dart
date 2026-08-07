import 'package:flutter/material.dart';

import '../theme/build_context_colors.dart';

/// Fond des écrans d'authentification — photo d'atelier de couture (machine
/// à coudre, ciseaux, mètre ruban) avec un voile sombre dégradé par-dessus
/// pour garder le texte de marque (blanc) et la carte de connexion lisibles
/// quel que soit l'endroit où ils tombent selon la largeur d'écran.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/branding/login_background.jpg',
          fit: BoxFit.cover,
        ),
        // Plus sombre en haut/à gauche (panneau de marque, texte blanc sans
        // fond opaque derrière), plus léger en bas/à droite (la carte de
        // connexion a déjà son propre fond quasi opaque, elle a besoin de
        // moins de voile pour rester lisible).
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.68),
                Colors.black.withValues(alpha: 0.42),
                Colors.black.withValues(alpha: 0.22),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: c.tertiary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        'assets/branding/logo_mark_transparent.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
