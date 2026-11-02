import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../models/subscription_plan.dart';
import '../preview_data.dart';
import '../widgets/preview_kit.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return PreviewPageBody(
      children: [
        const PreviewPageHeader(
          title: 'Tableau de bord',
          subtitle: 'Vue consolidée de la plateforme · 1er novembre 2026',
          actions: [
            PreviewButton(label: 'Exporter', icon: Icons.download_rounded),
            PreviewButton(
              label: 'Ajouter un styliste',
              icon: Icons.add_rounded,
              primary: true,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _KpiGrid(),
        const SizedBox(height: 18),
        const _Split(
          main: _RevenuePanel(),
          side: _PlanBreakdownPanel(),
        ),
        const SizedBox(height: 18),
        const _Split(
          main: _RequestsPanel(),
          side: _ActivityPanel(),
        ),
        const SizedBox(height: 18),
        PreviewInfoBanner(
          icon: Icons.info_outline_rounded,
          text:
              'Maquette statique : les données sont factices et aucune action n\'est branchée. '
              'Objectif — valider la densité, les tableaux et la hiérarchie avant la migration réelle.',
          accent: c.secondary,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grille KPI — 4 / 2 / 1 colonnes
// ─────────────────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const gap = 16.0;

    final cards = <Widget>[
      PreviewKpiCard(
        label: 'STYLISTES ACTIFS',
        value: '112',
        icon: Icons.storefront_rounded,
        accent: c.secondary,
        delta: '+12 %',
        hint: '128 comptes au total',
      ),
      PreviewKpiCard(
        label: 'ABONNÉS PAYANTS',
        value: '74',
        icon: Icons.workspace_premium_rounded,
        accent: c.goldInk,
        delta: '+8 %',
        hint: 'dont 15 en Entreprise',
      ),
      PreviewKpiCard(
        label: 'REVENUS DU MOIS',
        value: '1,25 M FCFA',
        icon: Icons.payments_rounded,
        accent: c.statusDone,
        delta: '+18 %',
        hint: 'MRR · novembre 2026',
      ),
      PreviewKpiCard(
        label: 'DEMANDES EN ATTENTE',
        value: '4',
        icon: Icons.pending_actions_rounded,
        accent: c.statusInProgress,
        hint: 'à traiter aujourd\'hui',
        highlight: true,
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
// Colonne principale + colonne latérale
// ─────────────────────────────────────────────────────────────────────────────

class _Split extends StatelessWidget {
  const _Split({
    required this.main,
    required this.side,
  });

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
// Revenus
// ─────────────────────────────────────────────────────────────────────────────

class _RevenuePanel extends StatelessWidget {
  const _RevenuePanel();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final last = revenueValues.last;
    final previous = revenueValues[revenueValues.length - 2];
    final growth = ((last - previous) / previous * 100).toStringAsFixed(1);

    return PreviewPanel(
      title: 'Revenus des abonnements',
      subtitle: '12 derniers mois · FCFA',
      trailing: PreviewBadge(
        label: '+$growth % vs oct.',
        foreground: c.statusDone,
        background: c.statusDoneBg,
        icon: Icons.trending_up_rounded,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '1 250 000',
                  style: AppTextStyles.statNumber.copyWith(
                    fontSize: 30,
                    color: c.onSurface,
                  ),
                ),
                const SizedBox(width: 7),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    'FCFA',
                    style: AppTextStyles.labelCaps.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const PreviewRevenueChart(
              values: revenueValues,
              labels: revenueMonths,
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            Row(
              children: const [
                Expanded(
                  child: _MiniStat(label: 'MRR', value: '1,25 M'),
                ),
                Expanded(
                  child: _MiniStat(label: 'ARPU', value: '16 900'),
                ),
                Expanded(
                  child: _MiniStat(label: 'CHURN', value: '2,1 %'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelXs.copyWith(
            color: c.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTextStyles.titleMd.copyWith(
            fontSize: 16,
            color: c.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Répartition par plan
// ─────────────────────────────────────────────────────────────────────────────

class _PlanBreakdownPanel extends StatelessWidget {
  const _PlanBreakdownPanel();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = planSubscriberCounts.values.fold<int>(0, (sum, v) => sum + v);
    final maxCount = planSubscriberCounts.values.reduce((a, b) => a > b ? a : b);

    Color colorFor(SubscriptionPlan plan) => switch (plan) {
          SubscriptionPlan.free => c.onSurfaceVariant,
          SubscriptionPlan.starter => c.statusInProgress,
          SubscriptionPlan.pro => c.secondary,
          SubscriptionPlan.enterprise => c.goldInk,
        };

    return PreviewPanel(
      title: 'Répartition par plan',
      subtitle: '$total comptes · 74 payants',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          children: [
            for (final plan in SubscriptionPlan.values) ...[
              _PlanRow(
                plan: plan,
                count: planSubscriberCounts[plan] ?? 0,
                total: total,
                maxCount: maxCount,
                color: colorFor(plan),
              ),
              if (plan != SubscriptionPlan.values.last)
                const SizedBox(height: 16),
            ],
            const SizedBox(height: 18),
            Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.auto_graph_rounded, size: 15, color: c.statusDone),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '58 % des comptes sont sur une offre payante',
                    style: AppTextStyles.bodySm.copyWith(
                      color: c.onSurfaceVariant,
                      fontSize: 12,
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

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.plan,
    required this.count,
    required this.total,
    required this.maxCount,
    required this.color,
  });

  final SubscriptionPlan plan;
  final int count;
  final int total;
  final int maxCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final percent = total == 0 ? 0.0 : count / total;
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
                  color: c.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
            const SizedBox(width: 6),
            SizedBox(
              width: 38,
              child: Text(
                '${(percent * 100).round()} %',
                textAlign: TextAlign.right,
                style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        PreviewProgressBar(
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

class _RequestsPanel extends StatelessWidget {
  const _RequestsPanel();

  @override
  Widget build(BuildContext context) {
    final pending = previewRequests
        .where((r) => r.status == PreviewRequestStatus.pending)
        .toList();

    return PreviewPanel(
      title: 'Demandes d\'abonnement',
      subtitle: '${pending.length} en attente de décision',
      trailing: const PreviewButton(
        label: 'Tout voir',
        icon: Icons.arrow_forward_rounded,
        small: true,
      ),
      clip: true,
      child: Column(
        children: [
          for (var i = 0; i < pending.length; i++)
            _RequestRow(
              request: pending[i],
              last: i == pending.length - 1,
            ),
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, this.last = false});

  final PreviewRequest request;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
          PreviewAvatar(initials: request.initials, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSm.copyWith(
                    fontSize: 13.5,
                    color: c.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  request.atelier,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: c.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PreviewPlanBadge(plan: request.plan),
          const SizedBox(width: 16),
          SizedBox(
            width: 64,
            child: Text(
              previewShortDate(request.requestedAt),
              style: AppTextStyles.bodySm.copyWith(
                color: c.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          _MiniAction(
            icon: Icons.check_rounded,
            color: c.statusDone,
            background: c.statusDoneBg,
            tooltip: 'Approuver',
          ),
          const SizedBox(width: 6),
          _MiniAction(
            icon: Icons.close_rounded,
            color: c.statusProblem,
            background: c.statusProblemBg,
            tooltip: 'Refuser',
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
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {},
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
// Activité récente
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel();

  static const _items = <(IconData, String, String, bool)>[
    (Icons.workspace_premium_rounded, 'Awa Cissé a renouvelé son plan Entreprise', 'il y a 12 min', true),
    (Icons.check_circle_rounded, 'Demande de Moussa Konaté approuvée', 'il y a 48 min', false),
    (Icons.block_rounded, 'Seydou Bagayoko suspendu', 'il y a 2 h', false),
    (Icons.download_rounded, 'Export mensuel généré', 'il y a 3 h', false),
    (Icons.storefront_rounded, 'Kadidia Touré a mis à jour son atelier', 'hier', false),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PreviewPanel(
      title: 'Activité récente',
      trailing: Icon(Icons.more_horiz_rounded, size: 18, color: c.onSurfaceVariant),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          children: [
            for (var i = 0; i < _items.length; i++)
              _ActivityRow(
                icon: _items[i].$1,
                text: _items[i].$2,
                time: _items[i].$3,
                gold: _items[i].$4,
                last: i == _items.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.text,
    required this.time,
    required this.gold,
    this.last = false,
  });

  final IconData icon;
  final String text;
  final String time;
  final bool gold;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = gold ? c.goldInk : c.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 13, color: accent),
              ),
              if (!last)
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.only(top: 4),
                  color: c.outlineVariant.withValues(alpha: 0.8),
                ),
            ],
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: AppTextStyles.bodySm.copyWith(
                    color: c.onSurface,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: AppTextStyles.labelXs.copyWith(
                    color: c.onSurfaceVariant,
                    fontSize: 9,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
