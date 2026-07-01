import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum PremiumButtonVariant { primary, gold, outline, ghost, dark }

class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PremiumButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final PremiumButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final double height;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final colors = _resolveColors(enabled);

    final child = AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: AppConstants.animationFast,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        curve: Curves.easeOutCubic,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: colors.gradient,
          color: colors.gradient == null ? colors.background : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: colors.border != null
              ? Border.all(color: colors.border!)
              : null,
          boxShadow: enabled && colors.shadow != null
              ? [
                  BoxShadow(
                    color: colors.shadow!,
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? widget.onPressed : null,
            onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.foreground,
                      ),
                    )
                  : Row(
                      mainAxisSize:
                          widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 20, color: colors.foreground),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Text(
                          widget.label.toUpperCase(),
                          style: AppTextStyles.labelCaps.copyWith(
                            color: colors.foreground,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    return widget.isExpanded ? child : IntrinsicWidth(child: child);
  }

  _ButtonColors _resolveColors(bool enabled) {
    if (!enabled) {
      return const _ButtonColors(
        background: AppColors.surfaceContainerHigh,
        foreground: AppColors.onSurfaceVariant,
      );
    }

    return switch (widget.variant) {
      PremiumButtonVariant.primary => const _ButtonColors(
          background: AppColors.primary,
          foreground: AppColors.onPrimary,
          shadow: Color(0x33131F5D),
        ),
      PremiumButtonVariant.gold => const _ButtonColors(
          gradient: AppColors.goldGradient,
          foreground: AppColors.onTertiary,
          shadow: Color(0x33735C00),
        ),
      PremiumButtonVariant.outline => const _ButtonColors(
          background: AppColors.surfaceContainerLowest,
          foreground: AppColors.onSurface,
          border: AppColors.outlineVariant,
        ),
      PremiumButtonVariant.ghost => const _ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.secondary,
        ),
      PremiumButtonVariant.dark => const _ButtonColors(
          gradient: AppColors.heroGradient,
          foreground: AppColors.onPrimary,
          shadow: Color(0x33131F5D),
        ),
    };
  }
}

class _ButtonColors {
  const _ButtonColors({
    this.background,
    this.foreground = AppColors.onSurface,
    this.gradient,
    this.border,
    this.shadow,
  });

  final Color? background;
  final Color foreground;
  final Gradient? gradient;
  final Color? border;
  final Color? shadow;
}
