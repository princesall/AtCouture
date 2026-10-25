import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_color_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/plan_guard.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../models/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../shared/calendar_screen.dart';
import 'orders/order_list_widgets.dart';

class StylistDashboard extends StatelessWidget {
  const StylistDashboard({super.key, this.onNavTap});

  /// Callback vers StylistShell pour changer d'onglet
  final ValueChanged<int>? onNavTap;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        _buildGreeting(c, user.firstName, user.atelierName),
        const SizedBox(height: 24),
        _buildBentoGrid(context),
        const SizedBox(height: 28),
        _buildSectionHeader(c, 'Urgences & Priorités'),
        const SizedBox(height: 14),
        _buildUrgentOrders(context),
        const SizedBox(height: 28),
        _buildSectionHeader(c, 'Actions d\'Atelier'),
        const SizedBox(height: 14),
        _buildQuickActions(context),
        const SizedBox(height: 28),
        _buildSectionHeader(
          c,
          'Commandes Récentes',
          onSeeAll: () => onNavTap?.call(2),
        ),
        const SizedBox(height: 14),
        _buildRecentOrders(context),
      ],
    );
  }

  Widget _buildGreeting(AppColorPalette c, String firstName, String? atelierName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour, $firstName',
          style: AppTextStyles.displayLg.copyWith(
            fontSize: 26,
            color: c.onSurface,
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 4),
        Text(
          atelierName != null
              ? 'Maison & Atelier $atelierName'
              : 'Création & confection de haute précision',
          style: AppTextStyles.bodyLg.copyWith(color: c.onSurfaceVariant),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildBentoGrid(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final c = context.colors;
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
                height: 120,
                child: StatCard(
                  label: 'EN COURS',
                  value: inProgress.toString(),
                  icon: PhosphorIconsRegular.hourglassSimple,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 120,
                child: StatCard(
                  label: 'LIVRÉES',
                  value: completed.toString(),
                  icon: PhosphorIconsRegular.checkCircle,
                  valueColor: c.statusDone,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 120,
                child: StatCard(
                  label: 'ENCAISSÉ',
                  value: Formatters.compactCurrency(
                    OrderService.instance.cashCollected(user.atelierId!),
                  ),
                  icon: PhosphorIconsRegular.wallet,
                  valueColor: c.statusDone,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 120,
                child: StatCard(
                  label: 'RESTE À RECEVOIR',
                  value: Formatters.compactCurrency(
                    OrderService.instance.outstandingBalance(user.atelierId!),
                  ),
                  icon: PhosphorIconsRegular.receipt,
                  valueColor: OrderService.instance.outstandingBalance(user.atelierId!) > 0
                      ? c.statusInProgress
                      : c.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: UrgentStatCard(count: urgent),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 500.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSectionHeader(AppColorPalette c, String title, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.titleMd.copyWith(color: c.onSurface)),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'TOUT VOIR',
              style: AppTextStyles.labelCaps.copyWith(
                color: c.tertiary,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUrgentOrders(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final c = context.colors;
    final orders = OrderService.instance.ordersOfAtelier(user.atelierId!);
    final urgentOrders = orders.where((o) => o.status == OrderStatus.problem).toList();

    if (urgentOrders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.outlineVariant, width: 0.8),
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsRegular.shieldCheck, color: c.statusDone, size: 20),
            const SizedBox(width: 10),
            Text(
              'Aucune alerte en attente dans l\'atelier',
              style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
    }

    return Column(
      children: urgentOrders.take(3).map((o) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: UrgentOrderCard(
          clientName: o.clientName,
          garmentType: o.description ?? 'Sans description',
          urgencyLabel: 'PRIORITAIRE',
          onTap: () => showOrderDetailSheet(context, o, onChanged: () {}),
        ),
      )).toList(),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                label: 'Nouveau Client',
                icon: PhosphorIconsRegular.userPlus,
                onTap: () => onNavTap?.call(1),
                isPrimary: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                label: 'Nouvelle Commande',
                icon: PhosphorIconsRegular.plusCircle,
                onTap: () => onNavTap?.call(2),
                isPrimary: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                label: 'Calendrier des Livraisons',
                icon: PhosphorIconsRegular.calendarBlank,
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
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
  }

  Widget _buildRecentOrders(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final c = context.colors;
    final orders = OrderService.instance.ordersOfAtelier(user.atelierId!);
    final recentOrders = orders.take(4).toList();

    if (recentOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: c.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.outlineVariant, width: 0.8),
          boxShadow: c.premiumShadow,
        ),
        child: EmptyState(
          title: 'Aucune commande pour l\'instant',
          subtitle: 'Créez votre première fiche pour débuter la confection',
          icon: PhosphorIconsRegular.receipt,
          action: ElevatedButton.icon(
            onPressed: () => onNavTap?.call(2),
            icon: Icon(PhosphorIconsRegular.plus, size: 16),
            label: const Text('NOUVELLE COMMANDE'),
          ),
        ),
      ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
    }

    return Container(
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.outlineVariant, width: 0.8),
        boxShadow: c.premiumShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: recentOrders.asMap().entries.map((entry) {
          final i = entry.key;
          final o = entry.value;
          return Column(
            children: [
              if (i > 0)
                Divider(height: 1, color: c.outlineVariant, indent: 16, endIndent: 16),
              OrderListItem(
                clientName: o.clientName,
                garmentType: o.description ?? 'Sans description',
                price: o.price.toString(),
                status: o.status,
                onTap: () => showOrderDetailSheet(context, o, onChanged: () {}),
              ),
            ],
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }
}
