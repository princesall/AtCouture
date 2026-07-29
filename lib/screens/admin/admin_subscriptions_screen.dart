import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/admin_demo_data.dart';
import '../../models/subscription_plan.dart';
import 'admin_dashboard.dart';

class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});
  @override
  State<AdminSubscriptionsScreen> createState() => _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen> {
  int _tabIndex = 0;
  final _tabs = ['APERÇU', 'EN ATTENTE', 'EXPIRANT'];

  // ── Barre fixe + onglets ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Onglets
      Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
        child: Row(children: List.generate(_tabs.length, (i) {
          final active = i == _tabIndex;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _tabIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppColors.surfaceContainerLowest : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: active ? AppColors.softShadow : null,
              ),
              child: Text(_tabs[i], style: AppTextStyles.labelCaps.copyWith(color: active ? AppColors.primary : AppColors.onSurfaceVariant), textAlign: TextAlign.center),
            ),
          ));
        })),
      ),
      const SizedBox(height: 16),
      // Contenu
      Expanded(child: IndexedStack(index: _tabIndex, children: [
        _OverviewTab(),
        _PendingTab(),
        _ExpiringTab(),
      ])),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet Aperçu — répartition par plan
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counts = <SubscriptionPlan, int>{};
    for (final s in AdminDemoData.stylists) {
      counts[s.user.plan] = (counts[s.user.plan] ?? 0) + 1;
    }
    final total = AdminDemoData.stylists.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: [
        // ── Banner revenus ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('REVENUS MENSUELS', style: AppTextStyles.labelXs.copyWith(color: AppColors.onTertiary.withValues(alpha: 0.7))),
              const SizedBox(height: 6),
              Text(Formatters.formatCurrency(AdminDemoData.monthlyRevenue), style: AppTextStyles.statNumber.copyWith(color: AppColors.onTertiary, fontSize: 28)),
              Text('FCFA', style: AppTextStyles.labelXs.copyWith(color: AppColors.onTertiary.withValues(alpha: 0.7))),
            ])),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 28),
            ),
          ]),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 24),
        Text('Répartition par plan', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
        const SizedBox(height: 16),

        // ── Cartes par plan ────────────────────────────────────────────
        ...SubscriptionPlan.values.map((plan) {
          final count = counts[plan] ?? 0;
          final pct = total > 0 ? count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlanStatCard(plan: plan, count: count, pct: pct),
          ).animate().fadeIn(delay: Duration(milliseconds: 80 * SubscriptionPlan.values.indexOf(plan)));
        }),

      ],
    );
  }
}

class _PlanStatCard extends StatelessWidget {
  const _PlanStatCard({required this.plan, required this.count, required this.pct});
  final SubscriptionPlan plan; final int count; final double pct;

  Color get _color => switch (plan) {
    SubscriptionPlan.free       => AppColors.onSurfaceVariant,
    SubscriptionPlan.starter    => AppColors.statusInProgress,
    SubscriptionPlan.pro        => AppColors.primary,
    SubscriptionPlan.enterprise => AppColors.tertiary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
            child: Text(plan.name.toUpperCase(), style: AppTextStyles.labelCaps.copyWith(color: _color)),
          ),
          const Spacer(),
          Text('$count styliste${count > 1 ? 's' : ''}', style: AppTextStyles.titleSm.copyWith(color: _color, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: _color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          )),
          const SizedBox(width: 12),
          Text('${(pct * 100).toStringAsFixed(0)}%', style: AppTextStyles.labelXs.copyWith(color: _color)),
        ]),
        if (plan != SubscriptionPlan.free) ...[
          const SizedBox(height: 8),
          Text(plan.priceLabel, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet En attente
// ─────────────────────────────────────────────────────────────────────────────
class _PendingTab extends StatefulWidget {
  @override
  State<_PendingTab> createState() => _PendingTabState();
}
class _PendingTabState extends State<_PendingTab> {
  final Set<String> _approved = {};
  final Set<String> _rejected = {};

  @override
  Widget build(BuildContext context) {
    final pending = AdminDemoData.stylists.where((s) => s.subscriptionRequest != null && !s.subscriptionRequest!.approved).toList();

    if (pending.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_outline_rounded, color: AppColors.statusDone, size: 56),
        const SizedBox(height: 16),
        Text('Aucune demande en attente', style: AppTextStyles.titleSm.copyWith(color: AppColors.onSurfaceVariant)),
      ]));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: pending.map((s) {
        final id = s.user.id;
        final isApproved = _approved.contains(id);
        final isRejected = _rejected.contains(id);

        if (isApproved || isRejected) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isApproved ? AppColors.statusDoneBg : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isApproved ? AppColors.statusDone.withValues(alpha: 0.3) : AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isApproved ? AppColors.statusDone : AppColors.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                Text(isApproved ? '${s.user.fullName} — Approuvé' : '${s.user.fullName} — Refusé', style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600, color: isApproved ? AppColors.statusDone : AppColors.onSurfaceVariant)),
              ]),
            ),
          );
        }

        final req = s.subscriptionRequest!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)), boxShadow: AppColors.softShadow),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                StylistAvatar(name: s.user.fullName, isOnline: s.isOnline),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.user.fullName, style: AppTextStyles.titleSm),
                  Text(s.user.atelierName ?? '', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ])),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primaryFixed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text('${s.user.plan.name} → ${req.requestedPlan.name}', style: AppTextStyles.titleSm.copyWith(color: AppColors.primary, fontSize: 14)),
                  const Spacer(),
                  Text(req.requestedPlan.priceLabel, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ]),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () async {
                    await AdminDemoData.rejectRequest(id);
                    if (!mounted) return;
                    setState(() => _rejected.add(id));
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: Text('REFUSER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.error)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    await AdminDemoData.approveRequest(id);
                    if (!mounted) return;
                    setState(() => _approved.add(id));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
                  child: Text('APPROUVER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary)),
                )),
              ]),
            ]),
          ).animate().fadeIn(delay: const Duration(milliseconds: 80), duration: 400.ms),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet Expirant
// ─────────────────────────────────────────────────────────────────────────────
class _ExpiringTab extends StatefulWidget {
  @override
  State<_ExpiringTab> createState() => _ExpiringTabState();
}
class _ExpiringTabState extends State<_ExpiringTab> {
  @override
  Widget build(BuildContext context) {
    final expiring = AdminDemoData.stylists.where((s) {
      final exp = s.user.planExpiresAt;
      return exp != null && exp.isBefore(DateTime.now().add(const Duration(days: 30)));
    }).toList()
      ..sort((a, b) => a.user.planExpiresAt!.compareTo(b.user.planExpiresAt!));

    if (expiring.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_outline_rounded, color: AppColors.statusDone, size: 56),
        const SizedBox(height: 16),
        Text('Aucun abonnement expirant', style: AppTextStyles.titleSm.copyWith(color: AppColors.onSurfaceVariant)),
      ]));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      children: expiring.asMap().entries.map((e) {
        final s = e.value;
        final daysLeft = s.user.planExpiresAt!.difference(DateTime.now()).inDays;
        final isUrgent = daysLeft <= 7;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUrgent ? AppColors.errorContainer.withValues(alpha: 0.15) : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isUrgent ? AppColors.error.withValues(alpha: 0.2) : AppColors.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(children: [
              StylistAvatar(name: s.user.fullName, isOnline: s.isOnline),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.user.fullName, style: AppTextStyles.titleSm),
                Text(s.user.atelierName ?? '', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isUrgent ? AppColors.errorContainer.withValues(alpha: 0.4) : AppColors.statusInProgressBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isUrgent ? 'EXPIRE DANS $daysLeft J' : 'EXPIRE DANS $daysLeft J',
                      style: AppTextStyles.labelXs.copyWith(color: isUrgent ? AppColors.error : AppColors.statusInProgress),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(s.user.plan.name, style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant)),
                ]),
              ])),
              GestureDetector(
                onTap: () => _showRenewDialog(context, s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUrgent ? AppColors.error : AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('RENOUVELER', style: AppTextStyles.labelXs.copyWith(color: Colors.white)),
                ),
              ),
            ]),
          ).animate().fadeIn(delay: Duration(milliseconds: 80 * e.key), duration: 400.ms),
        );
      }).toList(),
    );
  }

  void _showRenewDialog(BuildContext context, StylistEntry s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Renouveler l\'abonnement', style: AppTextStyles.titleMd.copyWith(color: AppColors.primary)),
        content: Text(
          'Renouveler le plan ${s.user.plan.name} de ${s.user.fullName} pour 12 mois ?',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ANNULER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurfaceVariant))),
          ElevatedButton(
            onPressed: () async {
              await AdminDemoData.renewSubscription(s.user.id);
              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: Text('CONFIRMER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary)),
          ),
        ],
      ),
    );
  }
}
