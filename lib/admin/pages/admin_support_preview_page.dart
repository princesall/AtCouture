import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/admin_account.dart';
import '../../models/app_user.dart';
import '../../models/client.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../services/admin_audit_service.dart';
import '../widgets/admin_kit.dart';

/// Aperçu support en LECTURE SEULE.
///
/// Ce n'est volontairement pas une connexion « en tant que » : une vraie
/// impersonation nécessite un custom token via Cloud Function et une origine
/// dédiée pour ne pas écraser la session client. Ici, l'admin voit les données
/// du compte sans aucune possibilité d'écriture.
class AdminSupportPreviewPage extends StatefulWidget {
  const AdminSupportPreviewPage({super.key, required this.data});

  final Account360Data data;

  @override
  State<AdminSupportPreviewPage> createState() => _AdminSupportPreviewPageState();
}

class _AdminSupportPreviewPageState extends State<AdminSupportPreviewPage> {
  int _tab = 0;

  static const _tabs = ['COMMANDES', 'CLIENTS', 'ÉQUIPE', 'ABONNEMENT'];

  @override
  void initState() {
    super.initState();
    AdminAuditService.instance.recordAsync(
      action: 'support.preview',
      targetType: 'user',
      targetId: widget.data.user.id,
      targetName: widget.data.user.fullName,
      details: 'Aperçu support en lecture seule',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = widget.data;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: AdminPageBody(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back_rounded, color: c.onSurface),
                  tooltip: 'Quitter l\'aperçu',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Aperçu support · ${data.user.fullName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMd.copyWith(
                      fontSize: 18,
                      color: c.onSurface,
                    ),
                  ),
                ),
                AdminButton(
                  label: 'Quitter',
                  icon: Icons.close_rounded,
                  small: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: c.statusInProgressBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: c.statusInProgress.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_rounded,
                    size: 18,
                    color: c.statusInProgress,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'MODE SUPPORT — LECTURE SEULE. Vous consultez les données de '
                      '${data.user.fullName}. Aucune modification ne peut être effectuée ici.',
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 12,
                        color: c.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AdminPanel(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    AdminAvatar.fromName(data.user.fullName, size: 58),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.user.fullName,
                            style: AppTextStyles.titleMd.copyWith(
                              fontSize: 18,
                              color: c.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${data.user.role.label} · ${data.user.atelierName ?? 'Sans atelier'}',
                            style: AppTextStyles.bodySm.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              AdminPlanBadge(
                                plan: data.user.plan,
                                isCompanyStaff: data.user.companyId != null,
                              ),
                              AdminBadge(
                                label: data.user.isActive ? 'ACTIF' : 'SUSPENDU',
                                foreground: data.user.isActive
                                    ? c.statusDone
                                    : c.statusProblem,
                                background: data.user.isActive
                                    ? c.statusDoneBg
                                    : c.statusProblemBg,
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
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 12.0;
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : (constraints.maxWidth >= 560 ? 2 : 1);
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                final cards = [
                  _PreviewKpi(
                    label: 'CLIENTS',
                    value: '${data.clientCount}',
                    icon: Icons.people_outline_rounded,
                  ),
                  _PreviewKpi(
                    label: 'COMMANDES',
                    value: '${data.orders.length}',
                    icon: Icons.receipt_long_outlined,
                  ),
                  _PreviewKpi(
                    label: 'CA ATELIER',
                    value: Formatters.compactCurrency(data.totalRevenue),
                    icon: Icons.trending_up_rounded,
                  ),
                  _PreviewKpi(
                    label: 'ÉQUIPE',
                    value: '${data.teamCount}',
                    icon: Icons.group_outlined,
                  ),
                ];
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final card in cards)
                      SizedBox(width: width, child: card),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            AdminFilterChips(
              labels: _tabs,
              selected: _tab,
              onSelect: (index) => setState(() => _tab = index),
            ),
            const SizedBox(height: 14),
            switch (_tab) {
              1 => _ClientsPreview(clients: data.clients),
              2 => _TeamPreview(team: data.team),
              3 => _SubscriptionPreview(data: data),
              _ => _OrdersPreview(orders: data.orders),
            },
          ],
        ),
      ),
    );
  }
}

class _PreviewKpi extends StatelessWidget {
  const _PreviewKpi({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: c.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelCaps.copyWith(
                    fontSize: 8.5,
                    color: c.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSm.copyWith(
                    fontSize: 18,
                    color: c.onSurface,
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

class _OrdersPreview extends StatelessWidget {
  const _OrdersPreview({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const AdminPanel(
        child: AdminEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Aucune commande',
          message: 'Ce compte n\'a encore aucune commande enregistrée.',
        ),
      );
    }
    return AdminPanel(
      clip: true,
      padding: EdgeInsets.zero,
      title: 'Commandes',
      subtitle: '${orders.length} commande${orders.length > 1 ? 's' : ''}',
      child: AdminTable(
        minWidth: 760,
        columns: const [
          AdminColumn('CLIENT', flex: 2),
          AdminColumn('ATELIER', flex: 2),
          AdminColumn('STATUT', width: 120),
          AdminColumn('MONTANT', width: 120, align: TextAlign.right),
          AdminColumn('RESTE', width: 110, align: TextAlign.right),
        ],
        rows: [
          for (final order in orders.take(30))
            AdminRow([
              Text(
                order.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSm.copyWith(
                  fontSize: 12.5,
                  color: context.colors.onSurface,
                ),
              ),
              Text(
                order.atelierName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              _orderStatusBadge(context, order.status),
              Text(
                Formatters.formatCurrency(order.price ?? 0),
                textAlign: TextAlign.right,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 12,
                  color: context.colors.onSurface,
                ),
              ),
              Text(
                Formatters.formatCurrency(order.balanceDue),
                textAlign: TextAlign.right,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 12,
                  color: order.balanceDue > 0
                      ? context.colors.statusProblem
                      : context.colors.statusDone,
                ),
              ),
            ]),
        ],
      ),
    );
  }
}

class _ClientsPreview extends StatelessWidget {
  const _ClientsPreview({required this.clients});

  final List<Client> clients;

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return const AdminPanel(
        child: AdminEmptyState(
          icon: Icons.people_outline_rounded,
          title: 'Aucun client',
          message: 'Ce compte n\'a encore aucun client enregistré.',
        ),
      );
    }
    return AdminPanel(
      clip: true,
      padding: EdgeInsets.zero,
      title: 'Clients',
      subtitle: '${clients.length} client${clients.length > 1 ? 's' : ''}',
      child: AdminTable(
        minWidth: 680,
        columns: const [
          AdminColumn('CLIENT', flex: 3),
          AdminColumn('TÉLÉPHONE', flex: 2),
          AdminColumn('COMMANDES', width: 110, align: TextAlign.right),
          AdminColumn('TOTAL DÉPENSÉ', width: 130, align: TextAlign.right),
        ],
        rows: [
          for (final client in clients.take(30))
            AdminRow([
              Text(
                client.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSm.copyWith(
                  fontSize: 12.5,
                  color: context.colors.onSurface,
                ),
              ),
              Text(
                client.phone,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              Text(
                '${client.orderCount}',
                textAlign: TextAlign.right,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 12,
                  color: context.colors.onSurface,
                ),
              ),
              Text(
                Formatters.formatCurrency(client.totalSpent),
                textAlign: TextAlign.right,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 12,
                  color: context.colors.onSurface,
                ),
              ),
            ]),
        ],
      ),
    );
  }
}

class _TeamPreview extends StatelessWidget {
  const _TeamPreview({required this.team});

  final List<AppUser> team;

  @override
  Widget build(BuildContext context) {
    if (team.isEmpty) {
      return const AdminPanel(
        child: AdminEmptyState(
          icon: Icons.group_outlined,
          title: 'Aucune équipe',
          message: 'Ce compte travaille seul ou n\'encadre aucun membre.',
        ),
      );
    }
    return AdminPanel(
      clip: true,
      padding: EdgeInsets.zero,
      title: 'Équipe',
      subtitle: '${team.length} membre${team.length > 1 ? 's' : ''}',
      child: AdminTable(
        minWidth: 700,
        columns: const [
          AdminColumn('MEMBRE', flex: 3),
          AdminColumn('RÔLE', flex: 2),
          AdminColumn('TÉLÉPHONE', flex: 2),
          AdminColumn('STATUT', width: 110),
        ],
        rows: [
          for (final member in team.take(30))
            AdminRow([
              Text(
                member.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSm.copyWith(
                  fontSize: 12.5,
                  color: context.colors.onSurface,
                ),
              ),
              Text(
                member.role.label,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              Text(
                member.phone,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              AdminBadge(
                label: member.isActive ? 'ACTIF' : 'SUSPENDU',
                foreground: member.isActive
                    ? context.colors.statusDone
                    : context.colors.statusProblem,
                background: member.isActive
                    ? context.colors.statusDoneBg
                    : context.colors.statusProblemBg,
              ),
            ]),
        ],
      ),
    );
  }
}

class _SubscriptionPreview extends StatelessWidget {
  const _SubscriptionPreview({required this.data});

  final Account360Data data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = data.user;
    return AdminPanel(
      title: 'Abonnement',
      subtitle: 'Vue en lecture seule',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AdminPlanBadge(
                  plan: user.plan,
                  isCompanyStaff: user.companyId != null,
                ),
                const SizedBox(width: 10),
                AdminBadge(
                  label: data.hasExpired
                      ? 'EXPIRÉ'
                      : (user.planExpiresAt == null
                          ? 'SANS EXPIRATION'
                          : 'VALIDE'),
                  foreground: data.hasExpired
                      ? c.statusProblem
                      : c.statusDone,
                  background: data.hasExpired
                      ? c.statusProblemBg
                      : c.statusDoneBg,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (user.planExpiresAt != null)
              Text(
                'Expiration : ${Formatters.date.format(user.planExpiresAt!)}',
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 13,
                  color: c.onSurface,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Paiements d\'abonnement enregistrés : '
              '${Formatters.formatCurrency(data.subscriptionPaid)}',
              style: AppTextStyles.bodySm.copyWith(
                color: c.onSurfaceVariant,
              ),
            ),
            if (data.pendingRequest != null) ...[
              const SizedBox(height: 8),
              Text(
                'Demande en attente : ${data.pendingRequest!.requestedPlan.name}',
                style: AppTextStyles.bodySm.copyWith(
                  color: c.statusInProgress,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _orderStatusBadge(BuildContext context, OrderStatus status) {
  final c = context.colors;
  final (fg, bg) = switch (status) {
    OrderStatus.pending => (c.goldInk, c.tertiaryContainer),
    OrderStatus.inProgress => (c.statusInProgress, c.statusInProgressBg),
    OrderStatus.completed => (c.statusDone, c.statusDoneBg),
    OrderStatus.problem => (c.statusProblem, c.statusProblemBg),
  };
  return AdminBadge(label: status.label, foreground: fg, background: bg);
}
