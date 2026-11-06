import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_spacing.dart';
import '../theme/build_context_colors.dart';

/// Squelettes de chargement (placeholders animés affichés pendant qu'une
/// première synchronisation Firestore est en cours).
///
/// Pourquoi : les listes affichaient immédiatement « Aucune commande » /
/// « Aucun client » pendant que le stream répondait (1 à 2 s sur réseau
/// mobile), laissant croire que les données étaient perdues, puis les lignes
/// surgissaient d'un coup. Un squelette qui reprend la forme du contenu réel
/// supprime ce mensonge visuel et rend l'attente plus courte à percevoir.
///
/// Règle d'usage : uniquement pour du contenu structuré qui arrive en bloc
/// (listes, grilles, cartes de statistiques). Pour une action ponctuelle
/// (bouton, dialogue), un `CircularProgressIndicator` reste plus adapté.
///
/// Un seul [Skeleton] doit envelopper l'ensemble de l'écran plutôt qu'un par
/// élément : l'animation est alors partagée et coûte beaucoup moins cher sur
/// les téléphones d'entrée de gamme.

/// Enveloppe animée commune à tous les squelettes.
///
/// Respecte le réglage système « réduire les animations » : dans ce cas les
/// blocs restent affichés, mais figés (pas de défilement de dégradé).
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) return child;

    return Shimmer.fromColors(
      baseColor: c.surfaceContainerHigh,
      highlightColor: c.surfaceContainerLow,
      child: child,
    );
  }
}

/// Bloc neutre : brique de base de tous les squelettes.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppSpacing.radiusSm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Ligne de texte factice dont la largeur est une fraction de l'espace
/// disponible — des lignes toutes identiques auraient l'air artificiel.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.widthFactor = 0.6, this.height = 12});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: SkeletonBox(height: height, radius: height / 2),
    );
  }
}

/// Squelette d'une carte de commande (avatar + titre + sous-titre + badge).
class SkeletonOrderCard extends StatelessWidget {
  const SkeletonOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.cardSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 44, height: 44, radius: 12),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(widthFactor: 0.55, height: 14),
                    SizedBox(height: 8),
                    SkeletonLine(widthFactor: 0.35),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const SkeletonBox(width: 68, height: 24, radius: 12),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const SkeletonLine(widthFactor: 0.78),
          const SizedBox(height: 8),
          const SkeletonLine(widthFactor: 0.45),
        ],
      ),
    );
  }
}

/// Liste de cartes de commande factices (écran Commandes).
class OrderListSkeleton extends StatelessWidget {
  const OrderListSkeleton({super.key, this.itemCount = 5, this.padding});

  final int itemCount;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => const SkeletonOrderCard(),
      ),
    );
  }
}

/// Squelette d'une ligne de client (avatar rond + nom + téléphone).
class SkeletonClientTile extends StatelessWidget {
  const SkeletonClientTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SkeletonBox(width: 48, height: 48, radius: 16),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(widthFactor: 0.5, height: 14),
              SizedBox(height: 8),
              SkeletonLine(widthFactor: 0.3),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const SkeletonBox(width: 24, height: 24, radius: 12),
      ],
    );
  }
}

/// Liste de clients factices (écran Clients).
class ClientListSkeleton extends StatelessWidget {
  const ClientListSkeleton({super.key, this.itemCount = 6, this.padding});

  final int itemCount;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, _) => const SkeletonClientTile(),
      ),
    );
  }
}

/// Rangée de cartes de statistiques factices (tableau de bord).
///
/// La hauteur reprend celle des vraies `StatCard` du tableau de bord (120) pour
/// que le contenu ne « saute » pas au moment où les données arrivent.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key, this.statCount = 3});

  final int statCount;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < statCount; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: SkeletonBox(height: 120, radius: AppSpacing.radiusMd),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonLine(widthFactor: 0.4, height: 16),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < 3; i++) ...[
            const SkeletonOrderCard(),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
