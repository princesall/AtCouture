import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/plan_guard.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../models/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../shared/calendar_screen.dart';

class StylistDashboard extends StatelessWidget {
  const StylistDashboard({super.key, this.onNavTap});

  /// Callback vers StylistShell pour changer d'onglet
  final ValueChanged<int>? onNavTap;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        _buildGreeting(user.firstName, user.atelierName),
        const SizedBox(height: 24),
        _buildBentoGrid(context),
        const SizedBox(height: 32),
        _buildSectionHeader('⚡ Priorité'),
        const SizedBox(height: 16),
        _buildUrgentOrders(context),
        const SizedBox(height: 32),
        _buildQuickActions(context),
        const SizedBox(height: 32),
        _buildSectionHeader('Commandes Récentes'),
        const SizedBox(height: 16),
        _buildRecentOrders(context),
      ],
    );
  }

  Widget _buildGreeting(String firstName, String? atelierName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour, $firstName',
          style: AppTextStyles.displayLg.copyWith(
            fontSize: 28,
            color: AppColors.primary,
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 4),
        Text(
          atelierName != null
              ? 'Bienvenue dans $atelierName'
              : 'Prêt à créer l\'excellence aujourd\'hui ?',
          style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
        ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildBentoGrid(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final orders = OrderService.instance.ordersOfAtelier(user.atelierId!);
    final inProgress = orders.where((o) => o.status == OrderStatus.inProgress).length;
    final completed = orders.where((o) => o.status == OrderStatus.completed).length;
    final urgent = orders.where((o) => o.status == OrderStatus.problem).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 136,
                child: StatCard(
                  label: 'COMMANDES EN COURS',
                  value: inProgress.toString(),
                  icon: Icons.pending_actions_rounded,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 136,
                child: StatCard(
                  label: 'TERMINÉES',
                  value: completed.toString(),
                  icon: Icons.check_circle_outline_rounded,
                  valueColor: AppColors.tertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 128,
          width: double.infinity,
          child: UrgentStatCard(count: urgent),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'VOIR TOUT',
              style: AppTextStyles.labelCaps.copyWith(color: AppColors.secondary, letterSpacing: 1.2),
            ),
          ),
      ],
    );
  }

  Widget _buildUrgentOrders(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final orders = OrderService.instance.ordersOfAtelier(user.atelierId!);
    final urgentOrders = orders.where((o) => o.status == OrderStatus.problem).toList();

    if (urgentOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Aucune commande urgente',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
    }

    return Column(
      children: urgentOrders.take(3).map((o) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: UrgentOrderCard(
          clientName: o.clientName,
          garmentType: o.description ?? 'Sans description',
          urgencyLabel: 'URGENT',
        ),
      )).toList(),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                label: 'Nouveau Client',
                icon: Icons.person_add_rounded,
                onTap: () => onNavTap?.call(1), // → onglet Clients
                isPrimary: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: QuickActionButton(
                label: 'Nouvelle Commande',
                icon: Icons.add_box_rounded,
                onTap: () => onNavTap?.call(2), // → onglet Commandes
                isPrimary: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                label: 'Calendrier',
                icon: Icons.calendar_month_rounded,
                onTap: () {
                  final permissions = context.read<AuthProvider>().user!.permissions;
                  if (PlanGuard.requireFeature(
                    context: context,
                    isAllowed: permissions.hasCalendar,
                    featureName: 'Calendrier des livraisons',
                    lockedMessage: permissions.calendarLockedMessage,
                  )) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
                  }
                },
                isPrimary: false,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  Widget _buildRecentOrders(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final orders = OrderService.instance.ordersOfAtelier(user.atelierId!);
    final recentOrders = orders.take(3).toList();

    if (recentOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.premiumShadow,
        ),
        child: Text(
          'Aucune commande récente',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ).animate().fadeIn(delay: 500.ms, duration: 500.ms);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.premiumShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: recentOrders.asMap().entries.map((entry) {
          final i = entry.key;
          final o = entry.value;
          return Column(
            children: [
              if (i > 0)
                Divider(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.3), indent: 16, endIndent: 16),
              OrderListItem(
                clientName: o.clientName,
                garmentType: o.description ?? 'Sans description',
                price: o.price.toString(),
                status: o.status,
              ),
            ],
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 500.ms);
  }
}
