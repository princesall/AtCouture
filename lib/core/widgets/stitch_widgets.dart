import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../models/order_status.dart';
import '../constants/app_constants.dart';
import '../theme/app_color_palette.dart';
import '../theme/app_text_styles.dart';
import '../theme/build_context_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// StatusBadge — badge couture avec micro-point d'état
// ═══════════════════════════════════════════════════════════════════════════════

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (label, bg, fg, border) = switch (status) {
      OrderStatus.pending    => ('EN ATTENTE',    c.statusPendingBg,    c.statusPending,    c.statusPending.withValues(alpha: 0.2)),
      OrderStatus.inProgress => ('EN CONFECTION', c.statusInProgressBg, c.statusInProgress, c.statusInProgress.withValues(alpha: 0.25)),
      OrderStatus.completed  => ('TERMINÉ',       c.statusDoneBg,       c.statusDone,       c.statusDone.withValues(alpha: 0.25)),
      OrderStatus.problem    => ('SIGNALÉ',       c.statusProblemBg,    c.statusProblem,    c.statusProblem.withValues(alpha: 0.25)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelXs.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// StitchCard — carte haute couture avec bordure 1px & ombre légère
// ═══════════════════════════════════════════════════════════════════════════════

class StitchCard extends StatelessWidget {
  const StitchCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 12,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: c.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: c.outlineVariant, width: 0.8),
          boxShadow: c.premiumShadow,
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// StatCard — carte de métrique atelier
// ═══════════════════════════════════════════════════════════════════════════════

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.backgroundColor,
    this.span2 = false,
    this.isAlert = false,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final Color? backgroundColor;
  final bool span2;
  final bool isAlert;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = backgroundColor ??
        (isAlert
            ? c.errorContainer.withValues(alpha: 0.3)
            : c.surfaceContainerLowest);

    final numColor = valueColor ?? (isAlert ? c.error : c.primary);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert ? c.error.withValues(alpha: 0.25) : c.outlineVariant,
          width: 0.8,
        ),
        boxShadow: isAlert ? null : c.premiumShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.labelXs.copyWith(
                    color: isAlert
                        ? c.error.withValues(alpha: 0.9)
                        : c.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: isAlert ? c.error : c.goldInk, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.statNumber.copyWith(color: numColor),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtitle!,
                    style: AppTextStyles.bodySm.copyWith(
                      color: numColor.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// OrderListItem — ligne de commande haute couture
// ═══════════════════════════════════════════════════════════════════════════════

class OrderListItem extends StatelessWidget {
  const OrderListItem({
    super.key,
    required this.clientName,
    required this.garmentType,
    required this.price,
    required this.status,
    this.onTap,
    this.trailing,
  });

  final String clientName;
  final String garmentType;
  final String price;
  final OrderStatus status;
  final VoidCallback? onTap;
  final Widget? trailing;

  String get _initials {
    final parts = clientName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return clientName.isNotEmpty ? clientName[0].toUpperCase() : '?';
  }

  Color _avatarBg(AppColorPalette c) => switch (status) {
    OrderStatus.completed  => c.statusDoneBg,
    OrderStatus.inProgress => c.statusInProgressBg,
    OrderStatus.pending    => c.statusPendingBg,
    OrderStatus.problem    => c.statusProblemBg,
  };

  Color _avatarFg(AppColorPalette c) => switch (status) {
    OrderStatus.completed  => c.statusDone,
    OrderStatus.inProgress => c.statusInProgress,
    OrderStatus.pending    => c.statusPending,
    OrderStatus.problem    => c.statusProblem,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final avatarBg = _avatarBg(c);
    final avatarFg = _avatarFg(c);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Monogramme client
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: avatarBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: avatarFg.withValues(alpha: 0.2), width: 0.8),
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: AppTextStyles.titleSm.copyWith(color: avatarFg, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clientName, style: AppTextStyles.titleSm.copyWith(color: c.onSurface)),
                  const SizedBox(height: 2),
                  Text(garmentType, style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Prix + statut
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text.rich(
                  TextSpan(
                    text: price,
                    style: AppTextStyles.priceLabel.copyWith(color: c.primary),
                    children: [
                      TextSpan(
                        text: ' ${AppConstants.currency}',
                        style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(status),
              ],
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GlassNavBar — barre de navigation moderne
// ═══════════════════════════════════════════════════════════════════════════════

class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned(
      bottom: 16,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.surfaceContainerLowest.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          boxShadow: c.premiumShadow,
          border: Border.all(color: c.outlineVariant, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isActive = i == currentIndex;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: _NavPill(item: item, isActive: isActive),
            );
          }),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({required this.item, required this.isActive});
  final NavItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = isActive ? c.primary : c.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            item.label.toUpperCase(),
            style: AppTextStyles.labelXs.copyWith(
              color: color,
              fontSize: 9,
              letterSpacing: 0.6,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: c.tertiary,
                shape: BoxShape.circle,
              ),
            ),
          ] else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class NavItem {
  const NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

// ═══════════════════════════════════════════════════════════════════════════════
// UrgentStatCard — bandeau statut d'atelier
// ═══════════════════════════════════════════════════════════════════════════════

class UrgentStatCard extends StatelessWidget {
  const UrgentStatCard({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasIssues = count > 0;
    final bg = hasIssues
        ? c.errorContainer.withValues(alpha: 0.35)
        : c.surfaceContainerLowest;
    final borderColor = hasIssues
        ? c.error.withValues(alpha: 0.25)
        : c.outlineVariant;
    final fg = hasIssues ? c.error : c.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: hasIssues ? null : c.premiumShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasIssues ? c.error.withValues(alpha: 0.12) : c.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                hasIssues ? PhosphorIconsRegular.warningCircle : PhosphorIconsRegular.checkCircle,
                color: hasIssues ? c.error : c.statusDone,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hasIssues ? 'ATTENTION REQUISE' : 'TOUT EST EN ORDRE',
                  style: AppTextStyles.labelXs.copyWith(
                    color: fg,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasIssues
                      ? '$count commande${count > 1 ? 's' : ''} signalée${count > 1 ? 's' : ''} en difficulté'
                      : 'Aucun retard ou incident signalé en atelier',
                  style: AppTextStyles.bodySm.copyWith(
                    color: c.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TopAppBar Stitch — header haute couture fixe
// ═══════════════════════════════════════════════════════════════════════════════

class StitchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StitchAppBar({
    super.key,
    required this.title,
    this.onNotificationTap,
    this.actions,
  });

  final String title;
  final VoidCallback? onNotificationTap;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 64 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top, 20, 0),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest.withValues(alpha: 0.96),
        border: Border(bottom: BorderSide(color: c.outlineVariant, width: 0.8)),
      ),
      child: Row(
        children: [
          // Monogramme StyleConnect
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Image.asset(
              'assets/branding/logo_mark_transparent.png',
              fit: BoxFit.contain,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          // Titre Haute Couture
          Text.rich(
            TextSpan(
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: c.onSurface,
              ),
              children: [
                TextSpan(text: title.length >= 5 ? title.substring(0, 5) : title),
                if (title.length > 5)
                  TextSpan(
                    text: title.substring(5),
                    style: TextStyle(color: c.goldInk),
                  ),
              ],
            ),
          ),
          const Spacer(),
          ...?actions,
          IconButton(
            onPressed: onNotificationTap,
            icon: Icon(PhosphorIconsRegular.bell, color: c.onSurface, size: 22),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: c.outlineVariant, width: 0.8),
              ),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// QuickActionButton — bouton action rapide atelier
// ═══════════════════════════════════════════════════════════════════════════════

class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = isPrimary ? c.primary : c.surfaceContainerLowest;
    final fg = isPrimary ? c.onPrimary : c.onSurface;
    final border = isPrimary ? Colors.transparent : c.outlineVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 0.8),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                ]
              : c.premiumShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? c.goldInk : c.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.labelCaps.copyWith(
                color: fg,
                letterSpacing: 0.8,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// UrgentOrderCard — carte commande prioritaire
// ═══════════════════════════════════════════════════════════════════════════════

class UrgentOrderCard extends StatelessWidget {
  const UrgentOrderCard({
    super.key,
    required this.clientName,
    required this.garmentType,
    required this.urgencyLabel,
    this.imageUrl,
    this.onTap,
  });

  final String clientName;
  final String garmentType;
  final String urgencyLabel;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.outlineVariant, width: 0.8),
          boxShadow: c.premiumShadow,
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: c.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.outlineVariant, width: 0.6),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : Icon(PhosphorIconsRegular.coatHanger, color: c.goldInk, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clientName,
                          style: AppTextStyles.titleSm.copyWith(color: c.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: c.errorContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: c.error.withValues(alpha: 0.3), width: 0.8),
                        ),
                        child: Text(
                          urgencyLabel.toUpperCase(),
                          style: AppTextStyles.labelXs.copyWith(color: c.error, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    garmentType,
                    style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
