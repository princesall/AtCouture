import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/admin_demo_data.dart';
import '../../models/platform_health.dart';
import '../../models/subscription_plan.dart';
import '../../models/user_role.dart';
import '../../models/support_message.dart';
import '../../services/platform_health_service.dart';
import '../../services/support_message_service.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_kit.dart';

/// Tableau de bord réel de la console : toutes les valeurs viennent de
/// `AdminDemoData` (cache Firestore temps réel) et de `SupportMessageService`.
/// Aucune donnée factice — la maquette validée sert uniquement de référence
/// de mise en page.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key, required this.onNavigate});

  /// Change d'onglet dans la console (0 = dashboard, 1 = stylistes,
  /// 2 = abonnements, 3 = messages).
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AdminDemoData.revision,
      builder: (context, _, _) => ListenableBuilder(
        listenable: SupportMessageService.instance,
        builder: (context, _) => AdminPageBody(
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            const _KpiGrid(),
            const SizedBox(height: 18),
            _Split(
              main: _SubscriptionPanel(onNavigate: onNavigate),
              side: _PendingRequestsPanel(onNavigate: onNavigate),
            ),
            const SizedBox(height: 18),
            _Split(
              main: _TopStylistsPanel(onNavigate: onNavigate),
              side: _RecentMessagesPanel(onNavigate: onNavigate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final c = context.colors;
    final expiring = AdminDemoData.expiringIn7Days;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminPageHeader(
          title: 'Tableau de bord',
          subtitle:
              'Vue consolidée de la plateforme · ${Formatters.date.format(DateTime.now())}',
        ),
        if (expiring > 0) ...[
          const SizedBox(height: 18),
          AdminInfoBanner(
            icon: Icons.warning_amber_rounded,
            text:
                '$expiring abonnement${expiring > 1 ? 's' : ''} expire${expiring > 1 ? 'nt' : ''} dans les 7 prochains jours.',
            accent: c.statusInProgress,
            action: AdminButton(
              label: 'Voir',
              small: true,
              onTap: () => onNavigate(2),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI
// ─────────────────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final paid = AdminDemoData.paidSubscribersCount;

    const gap = 16.0;
    final cards = <Widget>[
      _TotalUsersKpi(accent: c.secondary),
      AdminKpiCard(
        label: 'COUTURIERS',
        value: '${AdminDemoData.totalTailors}',
        icon: Icons.content_cut_rounded,
        accent: c.statusInProgress,
        hint: '${AdminDemoData.companies.length} entreprise${AdminDemoData.companies.length > 1 ? 's' : ''} multi-ateliers',
      ),
      AdminKpiCard(
        label: 'COMMANDES ACTIVES',
        value: '${AdminDemoData.activeOrders}',
        icon: Icons.receipt_long_rounded,
        accent: c.statusDone,
        hint: 'tous ateliers confondus',
      ),
      AdminKpiCard(
        label: 'REVENUS ABONNEMENTS',
        value: Formatters.compactCurrency(AdminDemoData.subscriptionRevenue),
        icon: Icons.payments_rounded,
        accent: c.tertiary,
        hint: '$paid abonné${paid > 1 ? 's' : ''} payant${paid > 1 ? 's' : ''}',
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

/// Compteur global (tous rôles) chargé via les agrégations Firestore.
/// Le Future est mis en cache par le widget pour éviter une requête à chaque
/// rebuild du dashboard.
class _TotalUsersKpi extends StatefulWidget {
  const _TotalUsersKpi({required this.accent});

  final Color accent;

  @override
  State<_TotalUsersKpi> createState() => _TotalUsersKpiState();
}

class _TotalUsersKpiState extends State<_TotalUsersKpi> {
  late final Future<PlatformUserStats> _future =
      PlatformHealthService.instance.loadUserStats();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlatformUserStats>(
      future: _future,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        return AdminKpiCard(
          label: 'UTILISATEURS',
          value: stats == null ? '—' : '${stats.total}',
          icon: Icons.people_alt_rounded,
          accent: widget.accent,
          hint: stats == null
              ? 'comptage des comptes…'
              : '${stats.count(UserRole.stylist)} stylistes · ${stats.count(UserRole.tailor)} couturiers',
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Colonne principale + latérale
// ─────────────────────────────────────────────────────────────────────────────

class _Split extends StatelessWidget {
  const _Split({required this.main, required this.side});

  final Widget main;
  final Widget side;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1060) {
          return Column(
            children: [main, const SizedBox(height: 18), side],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: main),
            const SizedBox(width: 18),
            Expanded(child: side),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Revenus d'abonnement (réels)
// ─────────────────────────────────────────────────────────────────────────────

class _SubscriptionPanel extends StatelessWidget {
  const _SubscriptionPanel({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final breakdown = AdminDemoData.paidSubscribersByPlan;
    final totalSubscribers = AdminDemoData.paidSubscribersCount;
    final paidPlans = [
      SubscriptionPlan.starter,
      SubscriptionPlan.pro,
      SubscriptionPlan.enterprise,
    ];

    return AdminPanel(
      title: 'Revenus d\'abonnement',
      subtitle: 'Répartition réelle des abonnés payants',
      trailing: AdminButton(
        label: 'Gérer',
        icon: Icons.arrow_forward_rounded,
        small: true,
        onTap: () => onNavigate(2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(AdminDemoData.subscriptionRevenue),
                  style: AppTextStyles.statNumber.copyWith(
                    fontSize: 27,
                    color: c.onSurface,
                  ),
                ),
                const SizedBox(width: 7),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ mois',
                    style: AppTextStyles.labelCaps.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$totalSubscribers abonné${totalSubscribers > 1 ? 's' : ''} payant${totalSubscribers > 1 ? 's' : ''}',
              style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            _StackedPlanBar(breakdown: breakdown, total: totalSubscribers),
            const SizedBox(height: 20),
            for (final plan in paidPlans) ...[
              _PlanRevenueRow(
                plan: plan,
                count: breakdown[plan] ?? 0,
                maxCount: breakdown.values.isEmpty
                    ? 0
                    : breakdown.values.reduce((a, b) => a > b ? a : b),
              ),
              if (plan != paidPlans.last) const SizedBox(height: 14),
            ],
            const SizedBox(height: 18),
            Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 15,
                  color: c.goldInk,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Revenu récurrent mensuel encaissé par StyleConnect',
                    style: AppTextStyles.bodySm.copyWith(
                      fontSize: 12,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StackedPlanBar extends StatelessWidget {
  const _StackedPlanBar({required this.breakdown, required this.total});

  final Map<SubscriptionPlan, int> breakdown;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final plans = [
      SubscriptionPlan.starter,
      SubscriptionPlan.pro,
      SubscriptionPlan.enterprise,
    ];

    Color colorFor(SubscriptionPlan plan) => switch (plan) {
          SubscriptionPlan.free => c.onSurfaceVariant,
          SubscriptionPlan.starter => c.statusInProgress,
          SubscriptionPlan.pro => c.secondary,
          SubscriptionPlan.enterprise => c.goldInk,
        };

    if (total == 0) {
      return Container(
        height: 10,
        decoration: BoxDecoration(
          color: c.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final plan in plans)
              if ((breakdown[plan] ?? 0) > 0)
                Expanded(
                  flex: breakdown[plan]!,
                  child: Container(color: colorFor(plan)),
                ),
          ],
        ),
      ),
    );
  }
}

class _PlanRevenueRow extends StatelessWidget {
  const _PlanRevenueRow({
    required this.plan,
    required this.count,
    required this.maxCount,
  });

  final SubscriptionPlan plan;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (plan) {
      SubscriptionPlan.starter => c.statusInProgress,
      SubscriptionPlan.pro => c.secondary,
      SubscriptionPlan.enterprise => c.goldInk,
      SubscriptionPlan.free => c.onSurfaceVariant,
    };
    final revenue = count * plan.price;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                plan.name,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.onSurface,
                ),
              ),
            ),
            Text(
              '$count',
              style: AppTextStyles.titleSm.copyWith(
                fontSize: 13,
                color: c.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 92,
              child: Text(
                Formatters.compactCurrency(revenue),
                textAlign: TextAlign.right,
                style: AppTextStyles.labelXs.copyWith(
                  color: c.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        AdminProgressBar(
          value: maxCount == 0 ? 0 : count / maxCount,
          color: color,
          height: 6,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Demandes d'abonnement
// ─────────────────────────────────────────────────────────────────────────────

class _PendingRequestsPanel extends StatelessWidget {
  const _PendingRequestsPanel({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final pending = AdminDemoData.stylists
        .where((entry) =>
            entry.subscriptionRequest != null &&
            !entry.subscriptionRequest!.approved)
        .toList();

    return AdminPanel(
      title: 'Demandes d\'abonnement',
      subtitle: '${pending.length} en attente de décision',
      trailing: AdminButton(
        label: 'Tout voir',
        icon: Icons.arrow_forward_rounded,
        small: true,
        onTap: () => onNavigate(2),
      ),
      clip: true,
      child: pending.isEmpty
          ? const AdminEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Aucune demande en attente',
              message: 'Les nouvelles demandes apparaîtront ici en temps réel.',
            )
          : Column(
              children: [
                for (var i = 0; i < pending.length && i < 4; i++)
                  _RequestRow(
                    entry: pending[i],
                    last: i == pending.length - 1 || i == 3,
                  ),
              ],
            ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.entry, this.last = false});

  final StylistEntry entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = entry.user;
    final request = entry.subscriptionRequest!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: c.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
      ),
      child: Row(
        children: [
          AdminAvatar.fromName(user.fullName, online: entry.isOnline, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSm.copyWith(
                    fontSize: 13.5,
                    color: c.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  user.atelierName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 12,
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AdminPlanBadge(plan: request.requestedPlan),
          const SizedBox(width: 14),
          SizedBox(
            width: 54,
            child: Text(
              Formatters.date.format(request.requestedAt),
              style: AppTextStyles.bodySm.copyWith(
                fontSize: 11,
                color: c.onSurfaceVariant,
              ),
            ),
          ),
          _MiniAction(
            icon: Icons.check_rounded,
            color: c.statusDone,
            background: c.statusDoneBg,
            tooltip: 'Approuver',
            onTap: () => runAdminAction(
              context,
              action: () => AdminDemoData.approveRequest(user.id),
              successMessage: 'Demande approuvée pour ${user.fullName}.',
            ),
          ),
          const SizedBox(width: 6),
          _MiniAction(
            icon: Icons.close_rounded,
            color: c.statusProblem,
            background: c.statusProblemBg,
            tooltip: 'Refuser',
            onTap: () => runAdminAction(
              context,
              action: () => AdminDemoData.rejectRequest(user.id),
              successMessage: 'Demande refusée. Le compte a été notifié.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.color,
    required this.background,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top stylistes
// ─────────────────────────────────────────────────────────────────────────────

class _TopStylistsPanel extends StatelessWidget {
  const _TopStylistsPanel({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = AdminDemoData.stylists
        .where((entry) => entry.user.isActive)
        .toList()
      ..sort((a, b) => AdminDemoData.getStylistRevenue(b.user)
          .compareTo(AdminDemoData.getStylistRevenue(a.user)));

    return AdminPanel(
      title: 'Top stylistes',
      subtitle: 'Classés par chiffre d\'affaires généré',
      trailing: AdminButton(
        label: 'Voir tout',
        icon: Icons.arrow_forward_rounded,
        small: true,
        onTap: () => onNavigate(1),
      ),
      clip: true,
      child: top.isEmpty
          ? const AdminEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Aucun styliste pour le moment',
            )
          : AdminTable(
              minWidth: 620,
              rowHeight: 58,
              columns: const [
                AdminColumn('STYLISTE', flex: 3),
                AdminColumn('ATELIER', flex: 2),
                AdminColumn('PLAN', width: 112),
                AdminColumn('CA GÉNÉRÉ', width: 110, align: TextAlign.right),
              ],
              rows: [
                for (final entry in top.take(5))
                  AdminRow(
                    [
                      Row(
                        children: [
                          AdminAvatar.fromName(
                            entry.user.fullName,
                            online: entry.isOnline,
                            size: 32,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              entry.user.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleSm.copyWith(
                                fontSize: 12.5,
                                color: c.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        entry.user.atelierName ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          fontSize: 12,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      AdminPlanBadge(
                        plan: entry.user.plan,
                        isCompanyStaff: entry.user.companyId != null,
                      ),
                      Text(
                        Formatters.compactCurrency(
                          AdminDemoData.getStylistRevenue(entry.user),
                        ),
                        textAlign: TextAlign.right,
                        style: AppTextStyles.titleSm.copyWith(
                          fontSize: 12.5,
                          color: c.onSurface,
                        ),
                      ),
                    ],
                    onTap: () => onNavigate(1),
                  ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Messages récents
// ─────────────────────────────────────────────────────────────────────────────

class _RecentMessagesPanel extends StatelessWidget {
  const _RecentMessagesPanel({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final messages = SupportMessageService.instance.allMessages.take(4).toList();
    final unread = SupportMessageService.instance.unreadCount;

    return AdminPanel(
      title: 'Messages récents',
      subtitle: unread > 0 ? '$unread non lu${unread > 1 ? 's' : ''}' : 'Tout est lu',
      trailing: AdminButton(
        label: 'Ouvrir',
        icon: Icons.arrow_forward_rounded,
        small: true,
        onTap: () => onNavigate(3),
      ),
      child: messages.isEmpty
          ? const AdminEmptyState(
              icon: Icons.forum_outlined,
              title: 'Aucun message',
              message: 'Les signalements des comptes arriveront ici.',
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                children: [
                  for (var i = 0; i < messages.length; i++)
                    _MessageRow(
                      message: messages[i],
                      last: i == messages.length - 1,
                      onTap: () {
                        SupportMessageService.instance.markRead(messages[i].id);
                        onNavigate(3);
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.last,
    required this.onTap,
  });

  final SupportMessage message;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.only(bottom: last ? 0 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminAvatar.fromName(message.senderName, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.senderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSm.copyWith(
                              fontSize: 12.5,
                              fontWeight:
                                  message.isRead ? FontWeight.w500 : FontWeight.w700,
                              color: c.onSurface,
                            ),
                          ),
                        ),
                        if (!message.isRead)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: c.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          _relative(message.sentAt),
                          style: AppTextStyles.labelXs.copyWith(
                            fontSize: 9,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 11.5,
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'il y a ${diff.inDays} j';
    if (diff.inHours > 0) return 'il y a ${diff.inHours} h';
    if (diff.inMinutes > 0) return 'il y a ${diff.inMinutes} min';
    return 'à l\'instant';
  }
}
