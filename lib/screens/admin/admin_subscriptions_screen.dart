import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_color_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
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
    final c = context.colors;
    return Column(children: [
      // Onglets
      Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: c.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
        child: Row(children: List.generate(_tabs.length, (i) {
          final active = i == _tabIndex;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _tabIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? c.surfaceContainerLowest : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: active ? c.softShadow : null,
              ),
              child: Text(_tabs[i], style: AppTextStyles.labelCaps.copyWith(color: active ? c.primary : c.onSurfaceVariant), textAlign: TextAlign.center),
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
    final c = context.colors;
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
            gradient: c.goldGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: c.tertiary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('REVENUS MENSUELS', style: AppTextStyles.labelXs.copyWith(color: c.onTertiary.withValues(alpha: 0.7))),
              const SizedBox(height: 6),
              Text(Formatters.formatCurrency(AdminDemoData.monthlyRevenue), style: AppTextStyles.statNumber.copyWith(color: c.onTertiary, fontSize: 28)),
              Text(AppConstants.currency, style: AppTextStyles.labelXs.copyWith(color: c.onTertiary.withValues(alpha: 0.7))),
            ])),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 28),
            ),
          ]),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 24),
        Text('Répartition par plan', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
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

  Color _color(AppColorPalette c) => switch (plan) {
    SubscriptionPlan.free       => c.onSurfaceVariant,
    SubscriptionPlan.starter    => c.statusInProgress,
    SubscriptionPlan.pro        => c.primary,
    SubscriptionPlan.enterprise => c.tertiary,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = _color(c);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: c.softShadow,
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
            child: Text(plan.name.toUpperCase(), style: AppTextStyles.labelCaps.copyWith(color: color)),
          ),
          const Spacer(),
          Text('$count styliste${count > 1 ? 's' : ''}', style: AppTextStyles.titleSm.copyWith(color: color, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )),
          const SizedBox(width: 12),
          Text('${(pct * 100).toStringAsFixed(0)}%', style: AppTextStyles.labelXs.copyWith(color: color)),
        ]),
        if (plan != SubscriptionPlan.free) ...[
          const SizedBox(height: 8),
          Text(plan.priceLabel, style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
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
    final c = context.colors;
    final pending = AdminDemoData.stylists.where((s) => s.subscriptionRequest != null && !s.subscriptionRequest!.approved).toList();

    if (pending.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_outline_rounded, color: c.statusDone, size: 56),
        const SizedBox(height: 16),
        Text('Aucune demande en attente', style: AppTextStyles.titleSm.copyWith(color: c.onSurfaceVariant)),
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
                color: isApproved ? c.statusDoneBg : c.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isApproved ? c.statusDone.withValues(alpha: 0.3) : c.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isApproved ? c.statusDone : c.onSurfaceVariant, size: 20),
                const SizedBox(width: 12),
                Text(isApproved ? '${s.user.fullName} — Approuvé' : '${s.user.fullName} — Refusé', style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600, color: isApproved ? c.statusDone : c.onSurfaceVariant)),
              ]),
            ),
          );
        }

        final req = s.subscriptionRequest!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.surfaceContainerLowest, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.outlineVariant.withValues(alpha: 0.4)), boxShadow: c.softShadow),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                StylistAvatar(name: s.user.fullName, isOnline: s.isOnline),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.user.fullName, style: AppTextStyles.titleSm),
                  Text(s.user.atelierName ?? '', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
                ])),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.primaryFixed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.swap_horiz_rounded, color: c.primary, size: 20),
                  const SizedBox(width: 10),
                  Text('${s.user.plan.name} → ${req.requestedPlan.name}', style: AppTextStyles.titleSm.copyWith(color: c.primary, fontSize: 14)),
                  const Spacer(),
                  Text(req.requestedPlan.priceLabel, style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
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
                  style: OutlinedButton.styleFrom(foregroundColor: c.error, side: BorderSide(color: c.error.withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: Text('REFUSER', style: AppTextStyles.labelCaps.copyWith(color: c.error)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    await AdminDemoData.approveRequest(id);
                    if (!mounted) return;
                    setState(() => _approved.add(id));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: c.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
                  child: Text('APPROUVER', style: AppTextStyles.labelCaps.copyWith(color: c.onPrimary)),
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
    final c = context.colors;
    final expiring = AdminDemoData.stylists.where((s) {
      final exp = s.user.planExpiresAt;
      return exp != null && exp.isBefore(DateTime.now().add(const Duration(days: 30)));
    }).toList()
      ..sort((a, b) => a.user.planExpiresAt!.compareTo(b.user.planExpiresAt!));

    if (expiring.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_outline_rounded, color: c.statusDone, size: 56),
        const SizedBox(height: 16),
        Text('Aucun abonnement expirant', style: AppTextStyles.titleSm.copyWith(color: c.onSurfaceVariant)),
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
              color: isUrgent ? c.errorContainer.withValues(alpha: 0.15) : c.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isUrgent ? c.error.withValues(alpha: 0.2) : c.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: c.softShadow,
            ),
            child: Row(children: [
              StylistAvatar(name: s.user.fullName, isOnline: s.isOnline),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.user.fullName, style: AppTextStyles.titleSm),
                Text(s.user.atelierName ?? '', style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isUrgent ? c.errorContainer.withValues(alpha: 0.4) : c.statusInProgressBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isUrgent ? 'EXPIRE DANS $daysLeft J' : 'EXPIRE DANS $daysLeft J',
                      style: AppTextStyles.labelXs.copyWith(color: isUrgent ? c.error : c.statusInProgress),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(s.user.plan.name, style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant)),
                ]),
              ])),
              GestureDetector(
                onTap: () => _showRenewDialog(context, s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUrgent ? c.error : c.primary,
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
    final c = context.colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Renouveler l\'abonnement', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
        content: Text(
          'Renouveler le plan ${s.user.plan.name} de ${s.user.fullName} pour 12 mois ?',
          style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ANNULER', style: AppTextStyles.labelCaps.copyWith(color: c.onSurfaceVariant))),
          ElevatedButton(
            onPressed: () async {
              await AdminDemoData.renewSubscription(s.user.id);
              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: c.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: Text('CONFIRMER', style: AppTextStyles.labelCaps.copyWith(color: c.onPrimary)),
          ),
        ],
      ),
    );
  }
}
