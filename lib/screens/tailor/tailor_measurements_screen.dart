import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_color_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';

class TailorMeasurementsScreen extends StatefulWidget {
  const TailorMeasurementsScreen({super.key});

  @override
  State<TailorMeasurementsScreen> createState() => _TailorMeasurementsScreenState();
}

class _TailorMeasurementsScreenState extends State<TailorMeasurementsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final c = context.colors;
    final orders = OrderService.instance.ordersOfAtelier(user.atelierId!);

    // Filtrer les commandes qui ont des mesures
    final ordersWithMeasurements = orders.where((o) => 
      o.measurements != null && o.measurements!.isNotEmpty
    ).toList();

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  'Mesures des clients',
                  style: AppTextStyles.headlineLgMobile,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${ordersWithMeasurements.length} commande${ordersWithMeasurements.length > 1 ? 's' : ''} avec mesures',
                  style: AppTextStyles.bodySm.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Liste des mesures
          Expanded(
            child: ordersWithMeasurements.isEmpty
                ? Center(
                    child: EmptyState(
                      title: 'Aucune mesure',
                      subtitle: 'Aucune commande avec mesures enregistrées',
                      icon: Icons.straighten_outlined,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: ordersWithMeasurements.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final order = ordersWithMeasurements[index];
                      return _MeasurementCard(
                        order: order,
                      ).animate().fadeIn(delay: (index * 50).ms).slideY();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: c.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec info client
          Row(
            children: [
              UserAvatar(
                initials: order.clientName.split(' ').map((n) => n[0]).take(2).join().toUpperCase(),
                size: 40,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.clientName,
                      style: AppTextStyles.titleMd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.description ?? 'Sans description',
                      style: AppTextStyles.bodySm.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status, c).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.statusLabel,
                  style: AppTextStyles.labelXs.copyWith(
                    color: _getStatusColor(order.status, c),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          // Mesures en grille
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.5,
            children: order.measurements!.entries.map((entry) {
              return _MeasurementItem(
                label: _formatMeasurementLabel(entry.key),
                value: '${entry.value} cm',
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status, AppColorPalette c) {
    switch (status) {
      case OrderStatus.pending:
        return c.tertiary;
      case OrderStatus.inProgress:
        return c.primary;
      case OrderStatus.completed:
        return c.secondary;
      case OrderStatus.problem:
        return c.success;
    }
  }

  String _formatMeasurementLabel(String key) {
    final labels = {
      'epaule': 'Épaule',
      'poitrine': 'Poitrine',
      'taille': 'Taille',
      'hanche': 'Hanche',
      'longueur': 'Longueur',
      'bras': 'Bras',
      'cou': 'Cou',
      'epaule_to_epaule': 'Épaule à épaule',
    };
    return labels[key] ?? key;
  }
}

class _MeasurementItem extends StatelessWidget {
  const _MeasurementItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: c.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.labelXs.copyWith(
              color: c.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleSm.copyWith(
              color: c.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
