import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/firebase_error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';

class TailorDashboard extends StatefulWidget {
  const TailorDashboard({super.key, this.onNavTap});

  final ValueChanged<int>? onNavTap;

  @override
  State<TailorDashboard> createState() => _TailorDashboardState();
}

class _TailorDashboardState extends State<TailorDashboard> {
  int _filterIndex = 0;
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final c = context.colors;
    final orders = OrderService.instance.ordersOfTailor(atelierId: user.atelierId!, tailorId: user.id)
      ..sort((a, b) => (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999)));

    final inProgress = orders.where((o) => o.status == OrderStatus.inProgress).toList();
    final urgent = orders.where((o) => o.status == OrderStatus.problem).toList();
    final done = orders.where((o) => o.status == OrderStatus.completed).toList();

    final filtered = switch (_filterIndex) {
      1 => inProgress,
      2 => urgent,
      3 => done,
      _ => orders,
    };

    return Column(
      children: [
        _buildGreeting(user.firstName, user.atelierName),
        _buildStatRow(orders.length, inProgress.length, urgent.length, done.length),
        _buildFilterChips(orders.length, inProgress.length, urgent.length, done.length),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.checkroom_outlined, size: 40, color: c.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        orders.isEmpty ? 'Aucune commande pour le moment' : 'Aucune commande dans cette catégorie',
                        style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _buildOrderCard(filtered[i], i),
                ),
        ),
      ],
    );
  }

  Widget _buildGreeting(String firstName, String? atelierName) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour, $firstName',
            style: AppTextStyles.headlineLgMobile.copyWith(color: c.primary),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
          const SizedBox(height: 2),
          Text(
            atelierName ?? 'Vos tâches de couture',
            style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
          ).animate().fadeIn(delay: 80.ms),
        ],
      ),
    );
  }

  Widget _buildStatRow(int total, int inProgress, int urgent, int done) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 92,
                  child: StatCard(label: 'À FAIRE', value: '$total', icon: Icons.checklist_rounded),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 92,
                  child: StatCard(
                    label: 'EN COURS', value: '$inProgress', icon: Icons.pending_actions_rounded,
                    valueColor: c.statusInProgress,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 92,
                  child: StatCard(
                    label: 'URGENT', value: '$urgent', icon: Icons.priority_high_rounded,
                    valueColor: c.error, isAlert: urgent > 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 92,
                  child: StatCard(
                    label: 'TERMINÉ', value: '$done', icon: Icons.check_circle_outline_rounded,
                    valueColor: c.statusDone,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 120.ms, duration: 400.ms);
  }

  Widget _buildFilterChips(int total, int inProgress, int urgent, int done) {
    final filters = [
      'TOUT ($total)',
      'EN COURS ($inProgress)',
      'URGENT ($urgent)',
      'TERMINÉ ($done)',
    ];
    final c = context.colors;
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = i == _filterIndex;
          return GestureDetector(
            onTap: () => setState(() => _filterIndex = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? c.primary : c.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
                boxShadow: active ? [BoxShadow(color: c.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))] : null,
              ),
              child: Text(
                filters[i],
                style: AppTextStyles.labelCaps.copyWith(
                  color: active ? c.onPrimary : c.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 160.ms, duration: 400.ms);
  }

  Widget _buildOrderCard(Order order, int index) {
    final isExpanded = _expanded.contains(order.id);
    final c = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: c.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() {
              if (isExpanded) {
                _expanded.remove(order.id);
              } else {
                _expanded.add(order.id);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: c.primaryFixed.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      order.clientName.isNotEmpty ? order.clientName[0].toUpperCase() : '?',
                      style: AppTextStyles.titleMd.copyWith(color: c.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(order.clientName, style: AppTextStyles.titleSm.copyWith(color: c.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            StatusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.description ?? 'Sans description',
                          style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: c.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              order.dueDate != null ? Formatters.date.format(order.dueDate!) : 'Sans échéance',
                              style: AppTextStyles.labelCaps.copyWith(color: c.onSurfaceVariant),
                            ),
                            const Spacer(),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: c.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Panneau expansible ──────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedPanel(order),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index), duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Future<void> _updateStatus(Order order, OrderStatus status) async {
    final changedBy = context.read<AuthProvider>().user!.fullName;
    try {
      await OrderService.instance.updateOrderStatus(order.id, status, changedByName: changedBy);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyFirebaseError(e))),
      );
    }
  }

  void _showStatusHistory(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historique du statut'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final change in order.statusHistory.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusBadge(change.status),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${Formatters.dateTime.format(change.changedAt)} — ${change.changedByName}',
                            style: AppTextStyles.bodySm.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _buildExpandedPanel(Order order) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceContainerLow,
        border: Border(top: BorderSide(color: c.outlineVariant.withValues(alpha: 0.4))),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onNavTap?.call(1), // → onglet Mesures
                  icon: const Icon(Icons.straighten_rounded, size: 18),
                  label: Text('MESURES', style: AppTextStyles.labelCaps),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.primary,
                    side: BorderSide(color: c.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onNavTap?.call(2), // → onglet Photos
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text('PHOTOS', style: AppTextStyles.labelCaps),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.primary,
                    side: BorderSide(color: c.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: order.status == OrderStatus.completed
                      ? null
                      : () => _updateStatus(order, OrderStatus.completed),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: c.onPrimary,
                    disabledBackgroundColor: c.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('TERMINÉ', style: AppTextStyles.labelCaps.copyWith(
                    color: order.status == OrderStatus.completed ? c.onSurfaceVariant : c.onPrimary,
                  )),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: order.status == OrderStatus.problem
                      ? null
                      : () => _updateStatus(order, OrderStatus.problem),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.error,
                    side: BorderSide(color: c.error.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('PROBLÈME', style: AppTextStyles.labelCaps.copyWith(color: c.error)),
                ),
              ),
            ],
          ),
          if (order.statusHistory.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showStatusHistory(order),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 14, color: c.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Dernière mise à jour : ${Formatters.dateTime.format(order.statusHistory.last.changedAt)} par ${order.statusHistory.last.changedByName}',
                      style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
