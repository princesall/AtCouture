import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/admin_demo_data.dart';
import '../../models/subscription_plan.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_kit.dart';

/// Gestion des comptes stylistes / chefs d'entreprise.
///
/// Réutilise strictement les mêmes actions que l'ancien écran mobile
/// (`AdminDemoData.approveRequest`, `toggleActive`, `renewSubscription`,
/// `applyManualPlanChange`) : aucune logique métier n'est dupliquée.
class AdminStylistsPage extends StatefulWidget {
  const AdminStylistsPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<AdminStylistsPage> createState() => _AdminStylistsPageState();
}

class _AdminStylistsPageState extends State<AdminStylistsPage> {
  static const _filters = ['TOUS', 'ACTIFS', 'INACTIFS', 'EXPIRÉS'];
  static const _pageSize = 12;

  int _filter = 0;
  int _page = 0;
  late String _query = widget.initialQuery;

  @override
  void didUpdateWidget(covariant AdminStylistsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery) {
      setState(() {
        _query = widget.initialQuery;
        _page = 0;
      });
    }
  }

  List<StylistEntry> get _filtered {
    var list = AdminDemoData.stylists;
    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where((entry) =>
              entry.user.fullName.toLowerCase().contains(query) ||
              (entry.user.atelierName ?? '').toLowerCase().contains(query) ||
              entry.user.email.toLowerCase().contains(query))
          .toList();
    }

    return switch (_filter) {
      1 => list.where((entry) => entry.user.isActive).toList(),
      2 => list.where((entry) => !entry.user.isActive).toList(),
      3 => list.where((entry) {
          final expiry = entry.user.planExpiresAt;
          return expiry != null &&
              expiry.isBefore(DateTime.now().add(const Duration(days: 7)));
        }).toList(),
      _ => list,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AdminDemoData.revision,
      builder: (context, _, _) {
        final entries = _filtered;
        final pages = (entries.length / _pageSize).ceil();
        final pageCount = pages < 1 ? 1 : pages;
        final current = _page.clamp(0, pageCount - 1);
        final start = current * _pageSize;
        final visible = entries.skip(start).take(_pageSize).toList();

        return AdminPageBody(
          children: [
            AdminPageHeader(
              title: 'Stylistes',
              subtitle:
                  '${AdminDemoData.totalStylists} comptes · ${AdminDemoData.stylists.where((e) => e.user.isActive).length} actifs · ${AdminDemoData.companies.length} entreprises',
            ),
            const SizedBox(height: 22),
            AdminPanel(
              clip: true,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildToolbar(context, entries.length),
                  Divider(height: 1, color: context.colors.outlineVariant.withValues(alpha: 0.7)),
                  if (entries.isEmpty)
                    const AdminEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Aucun compte ne correspond',
                      message: 'Changez de filtre ou de recherche.',
                    )
                  else
                    AdminTable(
                      minWidth: 980,
                      columns: const [
                        AdminColumn('STYLISTE', flex: 3),
                        AdminColumn('ATELIER', flex: 2),
                        AdminColumn('PLAN', width: 118),
                        AdminColumn('STATUT', width: 126),
                        AdminColumn('CMD', width: 58, align: TextAlign.right),
                        AdminColumn('CA / MOIS', width: 104, align: TextAlign.right),
                        AdminColumn('EXPIRATION', width: 104, align: TextAlign.right),
                        AdminColumn('', width: 42, align: TextAlign.right),
                      ],
                      rows: [
                        for (final entry in visible)
                          AdminRow(
                            _cellsFor(context, entry),
                            onTap: () => _showDetails(context, entry),
                          ),
                      ],
                    ),
                  Divider(height: 1, color: context.colors.outlineVariant.withValues(alpha: 0.7)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                    child: AdminPagination(
                      label:
                          'Affichage de ${entries.isEmpty ? 0 : start + 1}–${start + visible.length} sur ${entries.length}',
                      page: current + 1,
                      pages: pageCount,
                      onPrevious: current > 0
                          ? () => setState(() => _page = current - 1)
                          : null,
                      onNext: current < pageCount - 1
                          ? () => setState(() => _page = current + 1)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminInfoBanner(
              icon: Icons.info_outline_rounded,
              text:
                  'Cliquez une ligne pour ouvrir la fiche. Suspendre un compte coupe immédiatement son accès aux données (règle Firestore isActive).',
              accent: context.colors.secondary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, int resultCount) {
    final c = context.colors;
    final chips = AdminFilterChips(
      labels: _filters,
      selected: _filter,
      onSelect: (index) => setState(() {
        _filter = index;
        _page = 0;
      }),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSearchField(
                  hint: 'Rechercher un nom, un atelier, un email…',
                  onChanged: (value) => setState(() {
                    _query = value;
                    _page = 0;
                  }),
                ),
                const SizedBox(height: 12),
                chips,
                const SizedBox(height: 10),
                Text(
                  '$resultCount compte${resultCount > 1 ? 's' : ''}',
                  style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                ),
              ],
            );
          }
          return Row(
            children: [
              AdminSearchField(
                hint: 'Rechercher un nom, un atelier, un email…',
                width: 310,
                onChanged: (value) => setState(() {
                  _query = value;
                  _page = 0;
                }),
              ),
              const SizedBox(width: 16),
              Expanded(child: chips),
              const SizedBox(width: 12),
              Text(
                '$resultCount compte${resultCount > 1 ? 's' : ''}',
                style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _cellsFor(BuildContext context, StylistEntry entry) {
    final c = context.colors;
    final user = entry.user;
    final expiry = user.planExpiresAt;
    final expiringSoon =
        expiry != null && expiry.isBefore(DateTime.now().add(const Duration(days: 7)));
    final pending = entry.subscriptionRequest != null;

    return [
      Row(
        children: [
          AdminAvatar.fromName(user.fullName, online: entry.isOnline, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSm.copyWith(
                          fontSize: 13.5,
                          color: c.onSurface,
                        ),
                      ),
                    ),
                    if (pending) ...[
                      const SizedBox(width: 6),
                      AdminBadge(
                        label: 'DEMANDE',
                        foreground: c.onTertiaryContainer,
                        background: c.tertiaryContainer,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  user.email,
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
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user.atelierName ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: c.onSurface,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            user.companyId != null
                ? 'Chef d\'atelier rattaché'
                : (user.plan == SubscriptionPlan.free
                    ? 'Atelier indépendant'
                    : 'Atelier indépendant'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 11,
              color: c.onSurfaceVariant,
            ),
          ),
        ],
      ),
      AdminPlanBadge(plan: user.plan, isCompanyStaff: user.companyId != null),
      AdminStatusBadge(isActive: user.isActive, expiringSoon: expiringSoon),
      Text(
        '${AdminDemoData.getStylistOrderCount(user)}',
        textAlign: TextAlign.right,
        style: AppTextStyles.bodySm.copyWith(
          fontSize: 12.5,
          color: c.onSurface,
        ),
      ),
      Text(
        Formatters.compactCurrency(AdminDemoData.getStylistRevenue(user)),
        textAlign: TextAlign.right,
        style: AppTextStyles.titleSm.copyWith(
          fontSize: 12.5,
          color: c.onSurface,
        ),
      ),
      _ExpiryCell(expiry: expiry),
      _ActionsMenu(entry: entry, onDetails: () => _showDetails(context, entry)),
    ];
  }

  Future<void> _showDetails(BuildContext context, StylistEntry entry) async {
    await context.push('/stylists/${entry.user.id}');
  }
}

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({required this.entry, required this.onDetails});

  final StylistEntry entry;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = entry.user;
    final pending = entry.subscriptionRequest != null;

    Future<void> handle(String action) async {
      switch (action) {
        case 'details':
          onDetails();
          return;
        case 'plan':
          final plan = await adminPickPlan(context, current: user.plan);
          if (plan == null || plan == user.plan) return;
          if (!context.mounted) return;
          await runAdminAction(
            context,
            action: () => AdminDemoData.applyManualPlanChange(user.id, plan),
            successMessage:
                'Plan de ${user.fullName} changé en ${plan.name}.',
          );
          return;
        case 'toggle':
          final suspend = user.isActive;
          final confirmed = await adminConfirm(
            context,
            title: suspend ? 'Suspendre ce compte ?' : 'Réactiver ce compte ?',
            message: suspend
                ? '${user.fullName} perdra immédiatement l\'accès aux données. Vous pourrez réactiver le compte à tout moment.'
                : '${user.fullName} retrouvera immédiatement l\'accès à son espace.',
            confirmLabel: suspend ? 'Suspendre' : 'Réactiver',
            danger: suspend,
          );
          if (!confirmed || !context.mounted) return;
          await runAdminAction(
            context,
            action: () => AdminDemoData.toggleActive(user.id),
            successMessage:
                suspend ? 'Compte suspendu.' : 'Compte réactivé.',
          );
          return;
        case 'renew':
          final confirmed = await adminConfirm(
            context,
            title: 'Renouveler l\'abonnement ?',
            message:
                'Le plan ${user.plan.name} de ${user.fullName} sera prolongé de 12 mois et le compte sera notifié.',
            confirmLabel: 'Renouveler 12 mois',
          );
          if (!confirmed || !context.mounted) return;
          await runAdminAction(
            context,
            action: () => AdminDemoData.renewSubscription(user.id),
            successMessage: 'Abonnement renouvelé pour 12 mois.',
          );
          return;
        case 'approve':
          await runAdminAction(
            context,
            action: () => AdminDemoData.approveRequest(user.id),
            successMessage: 'Demande approuvée pour ${user.fullName}.',
          );
          return;
        case 'reject':
          await runAdminAction(
            context,
            action: () => AdminDemoData.rejectRequest(user.id),
            successMessage: 'Demande refusée. Le compte a été notifié.',
          );
          return;
      }
    }

    return PopupMenuButton<String>(
      tooltip: 'Actions',
      onSelected: handle,
      color: c.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.outlineVariant),
      ),
      itemBuilder: (context) => [
        _menuItem(context, 'details', Icons.person_outline_rounded, 'Voir la fiche'),
        _menuItem(context, 'plan', Icons.workspace_premium_outlined, 'Changer de plan'),
        _menuItem(context, 'renew', Icons.autorenew_rounded, 'Renouveler 12 mois'),
        if (pending) ...[
          _menuItem(context, 'approve', Icons.check_circle_outline_rounded, 'Approuver la demande'),
          _menuItem(context, 'reject', Icons.cancel_outlined, 'Refuser la demande'),
        ],
        _menuItem(
          context,
          'toggle',
          user.isActive ? Icons.block_rounded : Icons.play_circle_outline_rounded,
          user.isActive ? 'Suspendre le compte' : 'Réactiver le compte',
          danger: user.isActive,
        ),
      ],
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.outlineVariant.withValues(alpha: 0.9)),
        ),
        child: Icon(Icons.more_horiz_rounded, size: 17, color: c.onSurfaceVariant),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    BuildContext context,
    String value,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    final c = context.colors;
    final color = danger ? c.statusProblem : c.onSurface;
    return PopupMenuItem<String>(
      value: value,
      height: 42,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 12.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryCell extends StatelessWidget {
  const _ExpiryCell({required this.expiry});

  final DateTime? expiry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (expiry == null) {
      return Text(
        '—',
        textAlign: TextAlign.right,
        style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
      );
    }
    final days = expiry!.difference(DateTime.now()).inDays;
    final urgent = days <= 7;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (urgent) ...[
          Icon(Icons.error_outline_rounded, size: 13, color: c.statusProblem),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            days <= 0 ? 'Expiré' : 'Dans $days j',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 12,
              fontWeight: urgent ? FontWeight.w600 : FontWeight.w400,
              color: urgent ? c.statusProblem : c.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
