import 'package:flutter/material.dart';

import 'premium_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;

    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const Spacer(),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.statNumber.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: AppTextStyles.bodySm.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }
}
