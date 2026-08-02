import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/build_context_colors.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.showShadow = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final decoration = BoxDecoration(
      gradient: gradient,
      color: gradient == null ? (backgroundColor ?? c.surfaceContainerLowest) : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: Border.all(
        color: borderColor ?? c.outlineVariant.withValues(alpha: 0.4),
      ),
      boxShadow: showShadow ? c.premiumShadow : null,
    );

    final content = Padding(padding: padding, child: child);

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Ink(decoration: decoration, child: content),
        ),
      );
    }

    return DecoratedBox(decoration: decoration, child: content);
  }
}

class PremiumDarkCard extends StatelessWidget {
  const PremiumDarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PremiumCard(
      gradient: c.heroGradient,
      borderColor: c.primaryContainer,
      showShadow: true,
      padding: padding,
      child: child,
    );
  }
}
