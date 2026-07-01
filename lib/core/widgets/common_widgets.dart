import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.headlineLgMobile,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMd),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle!, style: AppTextStyles.bodySm),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class PlanBadge extends StatelessWidget {
  const PlanBadge({super.key, required this.planName, this.compact = false});

  final String planName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: compact ? 2 : AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        planName.toUpperCase(),
        style: AppTextStyles.labelCaps.copyWith(
          color: AppColors.onTertiary,
          fontSize: compact ? 9 : 10,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.size = 44,
    this.imageUrl,
    this.dark = false,
  });

  final String initials;
  final double size;
  final String? imageUrl;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: dark ? AppColors.heroGradient : AppColors.goldGradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(
          color: AppColors.outlineVariant,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.labelCaps.copyWith(
          color: Colors.white,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}
