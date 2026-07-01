import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../providers/auth_provider.dart';

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
        _buildBentoGrid(),
        const SizedBox(height: 32),
        _buildSectionHeader('⚡ Priorité'),
        const SizedBox(height: 16),
        _buildUrgentOrders(),
        const SizedBox(height: 32),
        _buildQuickActions(context),
        const SizedBox(height: 32),
        _buildSectionHeader('Commandes Récentes'),
        const SizedBox(height: 16),
        _buildRecentOrders(),
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

  Widget _buildBentoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 136,
                child: StatCard(
                  label: 'COMMANDES EN COURS',
                  value: '14',
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
                  value: '28',
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
          child: UrgentStatCard(count: 3),
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

  Widget _buildUrgentOrders() {
    final urgent = [
      (name: 'Amadou Fall',  garment: 'Complet Bazin Riche - 3 pièces', label: 'LIVRAISON DEMAIN'),
      (name: 'Fatou Ndoye',  garment: 'Robe de soirée Soie & Perles',   label: 'LIVRAISON 48H'),
    ];

    return Column(
      children: urgent.map((o) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: UrgentOrderCard(
          clientName:   o.name,
          garmentType:  o.garment,
          urgencyLabel: o.label,
        ),
      )).toList(),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
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
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  Widget _buildRecentOrders() {
    final orders = [
      (name: 'Moussa Konaté', garment: 'Boubou Traditionnel',   price: '75.000',  status: OrderStatus.done),
      (name: 'Sokhna Diop',   garment: 'Taille Basse Dentelle', price: '120.000', status: OrderStatus.inProgress),
      (name: 'Alioune Ly',    garment: 'Costume Africain 2p',   price: '45.000',  status: OrderStatus.problem),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.premiumShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: orders.asMap().entries.map((entry) {
          final i = entry.key;
          final o = entry.value;
          return Column(
            children: [
              if (i > 0)
                Divider(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.3), indent: 16, endIndent: 16),
              OrderListItem(
                clientName:  o.name,
                garmentType: o.garment,
                price:       o.price,
                status:      o.status,
              ),
            ],
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 500.ms);
  }
}
