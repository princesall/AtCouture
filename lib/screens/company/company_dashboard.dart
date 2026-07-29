import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../models/atelier.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../models/client.dart';
import '../../services/company_service.dart';

/// Dashboard consolidé du Chef d'Entreprise — vue RÉELLE de toute son
/// activité : ateliers, couturiers, clients, commandes, revenus — tout
/// est calculé depuis les vraies données de CompanyService.
class CompanyDashboard extends StatelessWidget {
  const CompanyDashboard({super.key, this.onNavTap});
  final ValueChanged<int>? onNavTap;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final ateliers = CompanyService.instance.ateliersOfCompany(user.id);
    final stats = CompanyService.instance.companyStats(user.id);
    final recentOrders = CompanyService.instance.allOrdersOfCompany(user.id)
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    final clients = CompanyService.instance.allClientsOfCompany(user.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        _buildHeader(user.firstName, user.atelierName ?? 'Mon Entreprise', ateliers.length),
        const SizedBox(height: 24),
        _buildKpiBento(stats),
        const SizedBox(height: 32),
        _buildSectionRow('Mes Ateliers', onSeeAll: () => onNavTap?.call(1)),
        const SizedBox(height: 16),
        _buildAtelierCards(ateliers, user.id, onNavTap),
        const SizedBox(height: 32),
        _buildSectionRow('Clients récents', onSeeAll: () => onNavTap?.call(2)),
        const SizedBox(height: 16),
        _buildRecentClients(clients),
        const SizedBox(height: 32),
        _buildSectionRow('Commandes récentes', onSeeAll: () => onNavTap?.call(3)),
        const SizedBox(height: 16),
        _buildRecentOrders(recentOrders.take(4).toList()),
        const SizedBox(height: 32),
        _buildQuickActions(onNavTap),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(String firstName, String companyName, int atelierCount) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.workspace_premium_rounded, color: AppColors.onTertiary, size: 12),
            const SizedBox(width: 4),
            Text('ENTREPRISE', style: AppTextStyles.labelXs.copyWith(color: AppColors.onTertiary, letterSpacing: 0.8)),
          ]),
        ),
      ]),
      const SizedBox(height: 8),
      Text('Bonjour, $firstName', style: AppTextStyles.displayLg.copyWith(fontSize: 26, color: AppColors.primary))
          .animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
      const SizedBox(height: 4),
      Text('Bienvenue dans $companyName · $atelierCount atelier${atelierCount > 1 ? 's' : ''}',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant))
          .animate().fadeIn(delay: 100.ms),
    ]);
  }

  // ── KPI Bento ─────────────────────────────────────────────────────────────
  Widget _buildKpiBento(({int totalAteliers, int totalTailors, int totalClients, int totalOrders, int totalRevenue}) stats) {
    return Column(children: [
      Row(children: [
        Expanded(child: SizedBox(height: 120, child: StatCard(label: 'ATELIERS',   value: '${stats.totalAteliers}', icon: Icons.storefront_rounded,    valueColor: AppColors.secondary))),
        const SizedBox(width: 14),
        Expanded(child: SizedBox(height: 120, child: StatCard(label: 'COUTURIERS', value: '${stats.totalTailors}',  icon: Icons.content_cut_rounded,   valueColor: AppColors.primary))),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: SizedBox(height: 120, child: StatCard(label: 'CLIENTS',    value: '${stats.totalClients}', icon: Icons.people_alt_rounded,     valueColor: AppColors.surfaceTint))),
        const SizedBox(width: 14),
        Expanded(child: SizedBox(height: 120, child: StatCard(label: 'COMMANDES',  value: '${stats.totalOrders}',  icon: Icons.receipt_long_rounded,   valueColor: AppColors.statusInProgress))),
      ]),
      const SizedBox(height: 14),
      // Revenus pleine largeur en or
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('REVENUS TOTAUX', style: AppTextStyles.labelXs.copyWith(color: AppColors.onTertiary.withValues(alpha: 0.7))),
            const SizedBox(height: 6),
            Text(Formatters.formatCurrency(stats.totalRevenue), style: AppTextStyles.statNumber.copyWith(color: AppColors.onTertiary, fontSize: 28)),
            Text('FCFA générés par tous vos ateliers', style: AppTextStyles.labelXs.copyWith(color: AppColors.onTertiary.withValues(alpha: 0.7))),
          ]),
          const Spacer(),
          const Icon(Icons.trending_up_rounded, color: AppColors.onTertiary, size: 36),
        ]),
      ),
    ]).animate().fadeIn(delay: 150.ms, duration: 500.ms);
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _buildSectionRow(String title, {VoidCallback? onSeeAll}) {
    return Row(children: [
      Text(title, style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
      const Spacer(),
      if (onSeeAll != null)
        TextButton(
          onPressed: onSeeAll,
          child: Text('VOIR TOUT', style: AppTextStyles.labelCaps.copyWith(color: AppColors.secondary, letterSpacing: 1.1)),
        ),
    ]);
  }

  // ── Ateliers cards ────────────────────────────────────────────────────────
  Widget _buildAtelierCards(List<Atelier> ateliers, String ownerId, ValueChanged<int>? onNavTap) {
    return Column(
      children: ateliers.take(3).toList().asMap().entries.map((e) {
        final a = e.value;
        final isOwner = a.headStylistId == ownerId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onNavTap?.call(1),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isOwner ? AppColors.tertiary.withValues(alpha: 0.3) : AppColors.outlineVariant.withValues(alpha: 0.3)),
                boxShadow: AppColors.softShadow,
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: isOwner ? AppColors.goldGradient : null,
                    color: isOwner ? null : AppColors.primaryFixed.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(isOwner ? Icons.star_rounded : Icons.storefront_rounded,
                    color: isOwner ? AppColors.onTertiary : AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.name, style: AppTextStyles.titleSm.copyWith(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(isOwner ? 'Votre atelier personnel' : 'Chef : ${a.headStylistName}',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 12)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${CompanyService.instance.ordersOfAtelier(a.id).length}', style: AppTextStyles.titleSm.copyWith(color: AppColors.primary)),
                  Text('commandes', style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
                ]),
              ]),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 80 * e.key), duration: 400.ms),
        );
      }).toList(),
    );
  }

  // ── Clients récents ───────────────────────────────────────────────────────
  Widget _buildRecentClients(List<Client> clients) {
    final recent = clients.take(3).toList();
    if (recent.isEmpty) return _EmptyHint(label: 'Aucun client pour le moment');

    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.premiumShadow),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: recent.asMap().entries.map((e) {
          final c = e.value;
          return Column(children: [
            if (e.key > 0) Divider(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.3), indent: 16, endIndent: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primaryFixed.withValues(alpha: 0.4), shape: BoxShape.circle),
                child: Center(child: Text(c.initials, style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary))),
              ),
              title: Text(c.fullName, style: AppTextStyles.titleSm.copyWith(fontSize: 14)),
              subtitle: Row(children: [
                const Icon(Icons.storefront_outlined, size: 10, color: AppColors.secondary),
                const SizedBox(width: 3),
                Text(c.atelierName, style: AppTextStyles.labelXs.copyWith(color: AppColors.secondary)),
              ]),
              trailing: Text('${c.orderCount} cmds', style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
            ),
          ]);
        }).toList(),
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  // ── Commandes récentes ────────────────────────────────────────────────────
  Widget _buildRecentOrders(List<Order> orders) {
    if (orders.isEmpty) return _EmptyHint(label: 'Aucune commande pour le moment');

    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.premiumShadow),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: orders.asMap().entries.map((e) {
          final o = e.value;
          return Column(children: [
            if (e.key > 0) Divider(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.3), indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.clientName, style: AppTextStyles.titleSm.copyWith(fontSize: 13)),
                  Text('${o.description ?? 'Vêtement non précisé'} · ${o.atelierName}', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 12)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${Formatters.formatCurrency(o.price ?? 0)} F', style: AppTextStyles.titleSm.copyWith(color: AppColors.primary, fontSize: 12)),
                  const SizedBox(height: 4),
                  StatusBadge(o.status),
                ]),
              ]),
            ),
          ]);
        }).toList(),
      ),
    ).animate().fadeIn(delay: 450.ms);
  }

  // ── Actions rapides ───────────────────────────────────────────────────────
  Widget _buildQuickActions(ValueChanged<int>? onNavTap) {
    return Column(children: [
      Row(children: [
        Expanded(child: QuickActionButton(label: 'Nouvel Atelier',    icon: Icons.add_business_rounded, onTap: () => onNavTap?.call(1), isPrimary: true)),
        const SizedBox(width: 14),
        Expanded(child: QuickActionButton(label: 'Nouveau Client',    icon: Icons.person_add_rounded,   onTap: () => onNavTap?.call(2), isPrimary: false)),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: QuickActionButton(label: 'Voir Couturiers',   icon: Icons.content_cut_rounded,  onTap: () => onNavTap?.call(4), isPrimary: false)),
        const SizedBox(width: 14),
        Expanded(child: QuickActionButton(label: 'Toutes Commandes',  icon: Icons.receipt_long_rounded, onTap: () => onNavTap?.call(3), isPrimary: false)),
      ]),
    ]).animate().fadeIn(delay: 500.ms);
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
  );
}
