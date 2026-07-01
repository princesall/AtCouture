import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/stitch_widgets.dart';

class TailorDashboard extends StatefulWidget {
  const TailorDashboard({super.key, this.onNavTap});

  final ValueChanged<int>? onNavTap;

  @override
  State<TailorDashboard> createState() => _TailorDashboardState();
}

class _TailorDashboardState extends State<TailorDashboard> {
  int _filterIndex = 0;
  final Set<int> _expanded = {};

  final _filters = ['TOUT (8)', 'EN COURS (3)', 'URGENT (2)', 'TERMINÉ (3)'];

  final _orders = [
    _OrderData(id: 0, clientName: 'Amadou Konaté', garment: 'Bazin Riche - 3 pièces',  status: OrderStatus.inProgress, deadline: '15 Oct.'),
    _OrderData(id: 1, clientName: 'Fatou Sylla',   garment: 'Robe Bogolan Moderne',    status: OrderStatus.pending,    deadline: '20 Oct.'),
    _OrderData(id: 2, clientName: 'Ibrahima Diallo',garment: 'Costume 2 pièces Wax',   status: OrderStatus.problem,    deadline: '10 Oct.'),
    _OrderData(id: 3, clientName: 'Aïssatou Bah',  garment: 'Boubou Grand Boubou',     status: OrderStatus.done,       deadline: '05 Oct.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Filtres pill ───────────────────────────────────────────────────
        _buildFilterChips(),

        // ── Liste commandes ────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemCount: _orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _buildOrderCard(_orders[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = i == _filterIndex;
          return GestureDetector(
            onTap: () => setState(() => _filterIndex = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
                boxShadow: active ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))] : null,
              ),
              child: Text(
                _filters[i],
                style: AppTextStyles.labelCaps.copyWith(
                  color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildOrderCard(_OrderData order, int index) {
    final isExpanded = _expanded.contains(order.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: AppColors.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() {
              if (isExpanded) _expanded.remove(order.id);
              else _expanded.add(order.id);
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.checkroom_rounded, color: AppColors.secondary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(order.clientName, style: AppTextStyles.titleSm.copyWith(color: AppColors.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            StatusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(order.garment, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(order.deadline, style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurfaceVariant)),
                            const Spacer(),
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
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
    ).animate().fadeIn(delay: Duration(milliseconds: 80 * index), duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildExpandedPanel(_OrderData order) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4))),
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
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.outlineVariant),
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
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.outlineVariant),
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
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('TERMINÉ', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('PROBLÈME', style: AppTextStyles.labelCaps.copyWith(color: AppColors.error)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderData {
  const _OrderData({required this.id, required this.clientName, required this.garment, required this.status, required this.deadline});
  final int id;
  final String clientName;
  final String garment;
  final OrderStatus status;
  final String deadline;
}
