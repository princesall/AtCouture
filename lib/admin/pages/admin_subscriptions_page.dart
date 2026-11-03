import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/admin_demo_data.dart';
import '../../models/subscription_plan.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_kit.dart';

/// Abonnements : demandes à trancher, comptes qui expirent, répartition réelle
/// des plans. Les décisions passent par `AdminDemoData` (mêmes règles métier
/// et mêmes messages système que l'ancien écran mobile).
class AdminSubscriptionsPage extends StatefulWidget {
  const AdminSubscriptionsPage({super.key});

  @override
  State<AdminSubscriptionsPage> createState() => _AdminSubscriptionsPageState();
}

class _AdminSubscriptionsPageState extends State<AdminSubscriptionsPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ValueListenableBuilder<int>(
      valueListenable: AdminDemoData.revision,
      builder: (context, _, _) {
        final pending = _pendingEntries();
        final expiring = _expiringEntries();

        return AdminPageBody(
          children: [
            AdminPageHeader(
              title: 'Abonnements',
              subtitle:
                  '${pending.length} demande${pending.length > 1 ? 's' : ''} en attente · ${expiring.length} expiration${expiring.length > 1 ? 's' : ''} sous 7 jours',
            ),
            const SizedBox(height: 22),
            _KpiGrid(pending: pending.length, expiring: expiring.length),
            const SizedBox(height: 18),
            AdminFilterChips(
              labels: const ['DEMANDES', 'EXPIRANT', 'RÉPARTITION'],
              selected: _tab,
              onSelect: (index) => setState(() => _tab = index),
            ),
            const SizedBox(height: 16),
            if (_tab == 0)
              _RequestsPanel(entries: pending)
            else if (_tab == 1)
              _ExpiringPanel(entries: expiring)
            else
              const _BreakdownPanel(),
            const SizedBox(height: 16),
            AdminInfoBanner(
              icon: Icons.verified_user_outlined,
              text:
                  'Chaque décision est horodatée, journalisée et notifiée au compte. Une approbation met à jour le plan et la date d\'expiration immédiatement.',
              accent: c.goldInk,
            ),
          ],
        );
      },
    );
  }

  List<StylistEntry> _pendingEntries() => AdminDemoData.stylists
      .where((entry) =>
          entry.subscriptionRequest != null &&
          !entry.subscriptionRequest!.approved)
      .toList();

  List<StylistEntry> _expiringEntries() {
    final limit = DateTime.now().add(const Duration(days: 7));
    final list = AdminDemoData.stylists
        .where((entry) =>
            entry.user.planExpiresAt != null &&
            entry.user.planExpiresAt!.isBefore(limit))
        .toList()
      ..sort((a, b) => a.user.planExpiresAt!.compareTo(b.user.planExpiresAt!));
    return list;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI
// ─────────────────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.pending, required this.expiring});

  final int pending;
  final int expiring;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const gap = 16.0;
    final cards = <Widget>[
      AdminKpiCard(
        label: 'EN ATTENTE',
        value: '$pending',
        icon: Icons.pending_actions_rounded,
        accent: c.statusInProgress,
        hint: 'demande${pending > 1 ? 's' : ''} à trancher',
        highlight: true,
      ),
      AdminKpiCard(
        label: 'EXPIRE SOUS 7 J',
        value: '$expiring',
        icon: Icons.hourglass_bottom_rounded,
        accent: c.statusProblem,
        hint: 'à relancer ou renouveler',
      ),
      AdminKpiCard(
        label: 'ABONNÉS PAYANTS',
        value: '${AdminDemoData.paidSubscribersCount}',
        icon: Icons.workspace_premium_rounded,
        accent: c.secondary,
        hint: 'hors offre Découverte',
      ),
      AdminKpiCard(
        label: 'REVENUS RÉCURRENTS',
        value: Formatters.compactCurrency(AdminDemoData.subscriptionRevenue),
        icon: Icons.payments_rounded,
        accent: c.tertiary,
        hint: 'MRR · FCFA',
        hero: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1040
            ? 4
            : (constraints.maxWidth >= 640 ? 2 : 1);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Demandes
// ─────────────────────────────────────────────────────────────────────────────

class _RequestsPanel extends StatelessWidget {
  const _RequestsPanel({required this.entries});

  final List<StylistEntry> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminPanel(
      clip: true,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demandes d\'abonnement',
                        style: AppTextStyles.titleMd.copyWith(color: c.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Approuver applique le plan demandé pour 30 jours. Refuser notifie le compte sans changer son plan.',
                        style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
          if (entries.isEmpty)
            const AdminEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Aucune demande en attente',
              message: 'Les nouvelles demandes apparaîtront ici en temps réel.',
            )
          else
            AdminTable(
              minWidth: 860,
              columns: const [
                AdminColumn('DEMANDEUR', flex: 3),
                AdminColumn('ATELIER', flex: 2),
                AdminColumn('PLAN DEMANDÉ', width: 130),
                AdminColumn('DEMANDÉ LE', width: 104, align: TextAlign.right),
                AdminColumn('ACTIONS', width: 168, align: TextAlign.right),
              ],
              rows: [
                for (final entry in entries)
                  AdminRow(_cellsFor(context, entry)),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _cellsFor(BuildContext context, StylistEntry entry) {
    final c = context.colors;
    final user = entry.user;
    final request = entry.subscriptionRequest!;

    return [
      Row(
        children: [
          AdminAvatar.fromName(user.fullName, online: entry.isOnline, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSm.copyWith(
                    fontSize: 13,
                    color: c.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 11,
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      Text(
        user.atelierName ?? '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySm.copyWith(
          fontSize: 12.5,
          color: c.onSurface,
        ),
      ),
      AdminPlanBadge(plan: request.requestedPlan),
      Text(
        Formatters.date.format(request.requestedAt),
        textAlign: TextAlign.right,
        style: AppTextStyles.bodySm.copyWith(
          fontSize: 11.5,
          color: c.onSurfaceVariant,
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AdminIconAction(
            icon: Icons.check_rounded,
            tooltip: 'Approuver la demande',
            color: c.statusDone,
            background: c.statusDoneBg,
            onTap: () => runAdminAction(
              context,
              action: () => AdminDemoData.approveRequest(user.id),
              successMessage: 'Demande approuvée pour ${user.fullName}.',
            ),
          ),
          const SizedBox(width: 6),
          AdminIconAction(
            icon: Icons.close_rounded,
            tooltip: 'Refuser la demande',
            color: c.statusProblem,
            background: c.statusProblemBg,
            onTap: () => runAdminAction(
              context,
              action: () => AdminDemoData.rejectRequest(user.id),
              successMessage: 'Demande refusée. Le compte a été notifié.',
            ),
          ),
        ],
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expirations
// ─────────────────────────────────────────────────────────────────────────────

class _ExpiringPanel extends StatelessWidget {
  const _ExpiringPanel({required this.entries});

  final List<StylistEntry> entries;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminPanel(
      clip: true,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abonnements expirant sous 7 jours',
                        style: AppTextStyles.titleMd.copyWith(color: c.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Renouveler prolonge le plan actuel de 1 à 12 mois et notifie le compte.',
                        style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
          if (entries.isEmpty)
            const AdminEmptyState(
              icon: Icons.event_available_rounded,
              title: 'Aucune expiration imminente',
              message: 'Tous les abonnements payants sont valides au-delà de 7 jours.',
            )
          else
            AdminTable(
              minWidth: 820,
              columns: const [
                AdminColumn('COMPTE', flex: 3),
                AdminColumn('ATELIER', flex: 2),
                AdminColumn('PLAN', width: 112),
                AdminColumn('EXPIRATION', width: 118, align: TextAlign.right),
                AdminColumn('RESTE', width: 76, align: TextAlign.right),
                AdminColumn('', width: 118, align: TextAlign.right),
              ],
              rows: [
                for (final entry in entries)
                  AdminRow(_cellsFor(context, entry)),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _cellsFor(BuildContext context, StylistEntry entry) {
    final c = context.colors;
    final user = entry.user;
    final expiry = user.planExpiresAt!;
    final days = Formatters.daysUntil(expiry);
    final expired = expiry.isBefore(DateTime.now());

    return [
      Row(
        children: [
          AdminAvatar.fromName(user.fullName, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              user.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleSm.copyWith(
                fontSize: 13,
                color: c.onSurface,
              ),
            ),
          ),
        ],
      ),
      Text(
        user.atelierName ?? '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySm.copyWith(fontSize: 12.5, color: c.onSurface),
      ),
      AdminPlanBadge(plan: user.plan, isCompanyStaff: user.companyId != null),
      Text(
        Formatters.date.format(expiry),
        textAlign: TextAlign.right,
        style: AppTextStyles.bodySm.copyWith(
          fontSize: 11.5,
          color: c.onSurfaceVariant,
        ),
      ),
      Text(
        expired ? 'Expiré' : '$days j',
        textAlign: TextAlign.right,
        style: AppTextStyles.labelCaps.copyWith(
          fontSize: 10,
          color: expired ? c.statusProblem : c.statusInProgress,
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: AdminIconAction(
          icon: Icons.autorenew_rounded,
          tooltip: 'Renouveler l\'abonnement',
          color: c.onSurface,
          background: c.surfaceContainerLow,
          onTap: () async {
            final months = await adminPickRenewalMonths(
              context,
              userFullName: user.fullName,
              plan: user.plan,
              currentExpiry: expiry,
            );
            if (months == null || !context.mounted) return;
            await runAdminAction(
              context,
              action: () =>
                  AdminDemoData.renewSubscription(user.id, months: months),
              successMessage: 'Abonnement renouvelé pour $months mois.',
            );
          },
        ),
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Répartition
// ─────────────────────────────────────────────────────────────────────────────

class _BreakdownPanel extends StatelessWidget {
  const _BreakdownPanel();

  @override
  Widget build(BuildContext context) {
    final counts = <SubscriptionPlan, int>{};
    for (final entry in AdminDemoData.stylists) {
      counts[entry.user.plan] = (counts[entry.user.plan] ?? 0) + 1;
    }
    final total = AdminDemoData.stylists.length;
    final maxCount = counts.values.isEmpty
        ? 0
        : counts.values.reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final columns = constraints.maxWidth >= 1080
            ? 4
            : (constraints.maxWidth >= 640 ? 2 : 1);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final plan in SubscriptionPlan.values)
              SizedBox(
                width: width,
                child: _PlanCard(
                  plan: plan,
                  count: counts[plan] ?? 0,
                  total: total,
                  maxCount: maxCount,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.count,
    required this.total,
    required this.maxCount,
  });

  final SubscriptionPlan plan;
  final int count;
  final int total;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final highlighted = plan == SubscriptionPlan.pro;
    final accent = switch (plan) {
      SubscriptionPlan.free => c.onSurfaceVariant,
      SubscriptionPlan.starter => c.statusInProgress,
      SubscriptionPlan.pro => c.secondary,
      SubscriptionPlan.enterprise => c.goldInk,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlighted ? c.tertiaryContainer : c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? c.tertiary.withValues(alpha: 0.65)
              : c.outlineVariant.withValues(alpha: 0.75),
        ),
        boxShadow: c.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan.name,
                  style: AppTextStyles.titleMd.copyWith(
                    fontSize: 15,
                    color: c.onSurface,
                  ),
                ),
              ),
              if (highlighted)
                AdminBadge(
                  label: 'POPULAIRE',
                  foreground: c.onTertiaryContainer,
                  background: c.tertiary.withValues(alpha: 0.28),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: AppTextStyles.statNumber.copyWith(
                  fontSize: 24,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'compte${count > 1 ? 's' : ''}',
                  style: AppTextStyles.labelXs.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.price == 0
                ? 'Offre gratuite'
                : '${Formatters.formatCurrency(plan.price)} / mois',
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 11.5,
              color: c.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          AdminProgressBar(
            value: maxCount == 0 ? 0 : count / maxCount,
            color: accent,
            height: 6,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${total == 0 ? 0 : (count / total * 100).round()} % des comptes',
                style: AppTextStyles.labelXs.copyWith(
                  color: c.onSurfaceVariant,
                  fontSize: 9,
                ),
              ),
              const Spacer(),
              Text(
                plan.price == 0
                    ? '0 FCFA'
                    : Formatters.compactCurrency(count * plan.price),
                style: AppTextStyles.labelXs.copyWith(
                  color: c.onSurfaceVariant,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
