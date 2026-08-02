import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/build_context_colors.dart';

/// Fond animé des écrans d'authentification — dégradé Indigo profond avec
/// quelques halos doux (or / terracotta / blanc) qui dérivent lentement.
/// Remplace le rectangle à dégradé plat par quelque chose qui respire, sans
/// jamais distraire du formulaire (mouvement lent, opacité faible).
class AuthBackdrop extends StatefulWidget {
  const AuthBackdrop({super.key});

  @override
  State<AuthBackdrop> createState() => _AuthBackdropState();
}

class _AuthBackdropState extends State<AuthBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: c.heroGradient),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value * 2 * math.pi;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              _Glow(
                top: -70 + math.sin(t) * 14,
                left: -60 + math.cos(t) * 10,
                size: 240,
                color: c.tertiaryFixed.withValues(alpha: 0.22),
              ),
              _Glow(
                top: 60 + math.cos(t * 0.8) * 16,
                right: -80 + math.sin(t * 0.8) * 10,
                size: 280,
                color: c.secondaryFixed.withValues(alpha: 0.16),
              ),
              _Glow(
                bottom: -90 + math.sin(t * 0.6) * 12,
                left: 40 + math.cos(t * 0.6) * 16,
                size: 220,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.size,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final double size;
  final Color color;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
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
