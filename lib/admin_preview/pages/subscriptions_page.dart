import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../models/subscription_plan.dart';
import '../preview_data.dart';
import '../widgets/preview_kit.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pending = previewRequests
        .where((request) => request.status == PreviewRequestStatus.pending)
        .length;

    return PreviewPageBody(
      children: [
        const PreviewPageHeader(
          title: 'Abonnements',
          subtitle: 'Validation des demandes, plans et revenus récurrents',
          actions: [
            PreviewButton(label: 'Exporter', icon: Icons.download_rounded),
            PreviewButton(
              label: 'Créer un abonnement',
              icon: Icons.add_rounded,
              primary: true,
            ),
          ],
        ),
        const SizedBox(height: 22),
        _KpiGrid(pending: pending),
        const SizedBox(height: 18),
        const _PlansGrid(),
        const SizedBox(height: 18),
        PreviewPanel(
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
                            'Demandes récentes',
                            style: AppTextStyles.titleMd.copyWith(
                              color: c.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '6 demandes ce mois · $pending en attente',
                            style: AppTextStyles.bodySm.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PreviewButton(
                      label: 'Filtres',
                      icon: Icons.filter_list_rounded,
                      small: true,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
              AdminTable(
                minWidth: 900,
                columns: const [
                  AdminColumn('DEMANDEUR', flex: 3),
                  AdminColumn('ATELIER', flex: 2),
                  AdminColumn('PLAN', width: 110),
                  AdminColumn('DEMANDÉ LE', width: 112, align: TextAlign.right),
                  AdminColumn('STATUT', width: 122),
                  AdminColumn('ACTIONS', width: 172, align: TextAlign.right),
                ],
                rows: [
                  for (final request in previewRequests)
                    AdminRow(
                      _cellsFor(context, request),
                      onTap: () {},
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PreviewInfoBanner(
          icon: Icons.verified_user_outlined,
          text:
              'Chaque décision est horodatée, journalisée et notifiée au styliste. '
              'Les demandes approuvées mettent à jour le plan et la date d\'expiration du compte.',
          accent: c.goldInk,
        ),
      ],
    );
  }

  List<Widget> _cellsFor(BuildContext context, PreviewRequest request) {
    final c = context.colors;
    return [
      Row(
        children: [
          PreviewAvatar(initials: request.initials, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  request.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSm.copyWith(
                    fontSize: 13,
                    color: c.onSurface,
                  ),
                ),
                if (request.note != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    request.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      fontSize: 11,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      Text(
        request.atelier,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySm.copyWith(
          fontSize: 12.5,
          color: c.onSurface,
        ),
      ),
      PreviewPlanBadge(plan: request.plan),
      Text(
        previewDate(request.requestedAt),
        textAlign: TextAlign.right,
        style: AppTextStyles.bodySm.copyWith(
          fontSize: 11.5,
          color: c.onSurfaceVariant,
        ),
      ),
      PreviewRequestStatusBadge(status: request.status),
      if (request.status == PreviewRequestStatus.pending)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            PreviewButton(
              label: 'Approuver',
              icon: Icons.check_rounded,
              small: true,
              primary: true,
            ),
            SizedBox(width: 6),
            PreviewButton(
              label: 'Refuser',
              icon: Icons.close_rounded,
              small: true,
              danger: true,
            ),
          ],
        )
      else
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Voir le compte',
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 11.5,
              color: c.onSurfaceVariant,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI
// ─────────────────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.pending});

  final int pending;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const gap = 16.0;

    final cards = <Widget>[
      PreviewKpiCard(
        label: 'EN ATTENTE',
        value: '$pending',
        icon: Icons.pending_actions_rounded,
        accent: c.statusInProgress,
        hint: 'délai moyen de décision : 6 h',
        highlight: true,
      ),
      PreviewKpiCard(
        label: 'APPROUVÉES · 30 J',
        value: '23',
        icon: Icons.check_circle_rounded,
        accent: c.statusDone,
        delta: '+15 %',
        hint: 'sur 29 demandes reçues',
      ),
      PreviewKpiCard(
        label: 'REVENUS RÉCURRENTS',
        value: '1,25 M',
        icon: Icons.autorenew_rounded,
        accent: c.goldInk,
        delta: '+18 %',
        hint: 'MRR · FCFA',
      ),
      PreviewKpiCard(
        label: 'TAUX DE CONVERSION',
        value: '34 %',
        icon: Icons.percent_rounded,
        accent: c.secondary,
        delta: '+4 pts',
        hint: 'Découverte → payant',
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
// Cartes de plans
// ─────────────────────────────────────────────────────────────────────────────

class _PlansGrid extends StatelessWidget {
  const _PlansGrid();

  static const _descriptions = <SubscriptionPlan, String>{
    SubscriptionPlan.free: '1 couturier · 20 clients · 20 commandes',
    SubscriptionPlan.starter: '5 couturiers · statistiques · notifications',
    SubscriptionPlan.pro: '20 couturiers · calendrier · devis · PDF',
    SubscriptionPlan.enterprise: 'Ateliers illimités · multi-sites · manager',
  };

  @override
  Widget build(BuildContext context) {
    const gap = 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
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
                  description: _descriptions[plan]!,
                  subscribers: planSubscriberCounts[plan] ?? 0,
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
    required this.description,
    required this.subscribers,
  });

  final SubscriptionPlan plan;
  final String description;
  final int subscribers;

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
    final total = planSubscriberCounts.values.fold<int>(0, (sum, v) => sum + v);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlighted ? c.tertiaryContainer : c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? c.tertiary.withValues(alpha: 0.65)
              : c.outlineVariant.withValues(alpha: 0.75),
          width: highlighted ? 1.3 : 1,
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
                PreviewBadge(
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
                plan.price == 0 ? 'Gratuit' : fcfa(plan.price).replaceAll(' FCFA', ''),
                style: AppTextStyles.statNumber.copyWith(
                  fontSize: 22,
                  color: c.onSurface,
                ),
              ),
              if (plan.price > 0) ...[
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'FCFA / mois',
                    style: AppTextStyles.labelXs.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            maxLines: 2,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 11.5,
              height: 1.45,
              color: c.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '$subscribers',
                style: AppTextStyles.titleSm.copyWith(
                  fontSize: 13,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'abonné${subscribers > 1 ? 's' : ''}',
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 11.5,
                  color: c.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '${(subscribers / total * 100).round()} %',
                style: AppTextStyles.labelXs.copyWith(
                  color: c.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          PreviewProgressBar(value: subscribers / total, color: accent, height: 6),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PreviewButton(
              label: highlighted ? 'Gérer les abonnés' : 'Voir les abonnés',
              icon: Icons.arrow_forward_rounded,
              small: true,
            ),
          ),
        ],
      ),
    );
  }
}
