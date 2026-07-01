import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// StatusBadge — badge pill pour le statut d'une commande
// ═══════════════════════════════════════════════════════════════════════════════

enum OrderStatus { pending, inProgress, done, problem }

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      OrderStatus.pending    => ('EN ATTENTE', AppColors.statusPendingBg,    AppColors.statusPending),
      OrderStatus.inProgress => ('EN COURS',   AppColors.statusInProgressBg, AppColors.statusInProgress),
      OrderStatus.done       => ('TERMINÉ',     AppColors.statusDoneBg,       AppColors.statusDone),
      OrderStatus.problem    => ('PROBLÈME',    AppColors.statusProblemBg,    AppColors.statusProblem),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelXs.copyWith(color: fg),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// StitchCard — carte blanche avec ombre premium + bordure subtile
// ═══════════════════════════════════════════════════════════════════════════════

class StitchCard extends StatelessWidget {
  const StitchCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.surfaceContainerLowest),
          boxShadow: AppColors.premiumShadow,
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// StatCard — bento card pour les KPI (Commandes, Terminées, Retard)
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
    final bg = backgroundColor ??
        (isAlert
            ? AppColors.errorContainer.withValues(alpha: 0.4)
            : AppColors.surfaceContainerLowest);

    final numColor = valueColor ??
        (isAlert ? AppColors.error : AppColors.primary);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: isAlert
            ? Border.all(color: AppColors.error.withValues(alpha: 0.1))
            : Border.all(color: AppColors.surfaceContainerLowest),
        boxShadow: isAlert ? null : AppColors.premiumShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.labelXs.copyWith(
              color: isAlert
                  ? AppColors.error.withValues(alpha: 0.8)
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTextStyles.statNumber.copyWith(color: numColor),
              ),
              const Spacer(),
              if (subtitle != null)
                Flexible(
                  child: Text(
                    subtitle!,
                    style: AppTextStyles.bodySm.copyWith(
                      color: numColor.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                Icon(icon, color: numColor.withValues(alpha: 0.4), size: 28),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// OrderListItem — ligne de commande dans la liste (avec avatar initiales)
// ═══════════════════════════════════════════════════════════════════════════════

class OrderListItem extends StatelessWidget {
  const OrderListItem({
    super.key,
    required this.clientName,
    required this.garmentType,
    required this.price,
    required this.status,
    this.onTap,
  });

  final String clientName;
  final String garmentType;
  final String price;
  final OrderStatus status;
  final VoidCallback? onTap;

  String get _initials {
    final parts = clientName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return clientName.isNotEmpty ? clientName[0].toUpperCase() : '?';
  }

  Color get _avatarBg => switch (status) {
    OrderStatus.done       => AppColors.secondaryFixed.withValues(alpha: 0.5),
    OrderStatus.inProgress => AppColors.primaryFixed.withValues(alpha: 0.5),
    OrderStatus.pending    => AppColors.surfaceContainerHigh,
    OrderStatus.problem    => AppColors.errorContainer.withValues(alpha: 0.5),
  };

  Color get _avatarFg => switch (status) {
    OrderStatus.done       => AppColors.secondary,
    OrderStatus.inProgress => AppColors.primary,
    OrderStatus.pending    => AppColors.onSurfaceVariant,
    OrderStatus.problem    => AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar initiales
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _avatarBg,
                shape: BoxShape.circle,
                border: Border.all(color: _avatarFg.withValues(alpha: 0.1)),
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: AppTextStyles.titleSm.copyWith(color: _avatarFg),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clientName, style: AppTextStyles.titleSm.copyWith(color: AppColors.onSurface)),
                  const SizedBox(height: 2),
                  Text(garmentType, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
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
                    style: AppTextStyles.titleSm.copyWith(color: AppColors.primary),
                    children: [
                      TextSpan(
                        text: ' FCFA',
                        style: AppTextStyles.labelXs.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GlassNavBar — barre de navigation flottante style "glass pill"
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
    return Positioned(
      bottom: 16,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(999),
          boxShadow: AppColors.premiumShadow,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isActive = i == currentIndex;
            return GestureDetector(
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
    final color = isActive ? AppColors.secondary : AppColors.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isActive)
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            Icon(item.icon, color: color, size: 24),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: AppTextStyles.labelXs.copyWith(color: color, fontSize: 10),
        ),
      ],
    );
  }
}

class NavItem {
  const NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

// ═══════════════════════════════════════════════════════════════════════════════
// UrgentCard — carte "En retard" terracotta (span 2 colonnes)
// ═══════════════════════════════════════════════════════════════════════════════

class UrgentStatCard extends StatelessWidget {
  const UrgentStatCard({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Icon(Icons.warning_rounded, size: 80, color: AppColors.error.withValues(alpha: 0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EN RETARD',
                style: AppTextStyles.labelXs.copyWith(color: AppColors.error.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    count.toString().padLeft(2, '0'),
                    style: AppTextStyles.statNumber.copyWith(color: AppColors.error),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Actions requises\nimmédiatement',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.error.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TopAppBar Stitch — header fixe avec avatar + notifications
// ═══════════════════════════════════════════════════════════════════════════════

class StitchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StitchAppBar({
    super.key,
    required this.title,
    this.avatarUrl,
    this.onNotificationTap,
    this.actions,
  });

  final String title;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3), width: 2),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(avatarUrl!, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.primaryFixed,
                      child: Icon(Icons.person, color: AppColors.primary, size: 22),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Titre app
          Text(
            title,
            style: AppTextStyles.headlineLgMobile.copyWith(color: AppColors.primary),
          ),
          const Spacer(),
          // Actions
          ...?actions,
          // Cloche notifs
          IconButton(
            onPressed: onNotificationTap,
            icon: const Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant),
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ActionQuickButton — bouton action rapide (2 colonnes dashboard)
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
    final bg = isPrimary ? AppColors.primary : AppColors.primaryContainer;
    final fg = AppColors.onPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: fg, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.labelCaps.copyWith(color: fg),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// UrgentOrderCard — carte commande urgente (header de liste avec thumbnail)
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceContainerLowest),
          boxShadow: AppColors.premiumShadow,
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.checkroom, color: AppColors.secondary, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(clientName, style: AppTextStyles.titleSm.copyWith(color: AppColors.primary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          urgencyLabel.toUpperCase(),
                          style: AppTextStyles.labelXs.copyWith(color: AppColors.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(garmentType, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
