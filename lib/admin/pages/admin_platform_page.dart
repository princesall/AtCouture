import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_color_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/platform_health.dart';
import '../../models/user_role.dart';
import '../../services/platform_config_service.dart';
import '../../services/platform_health_service.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_kit.dart';

/// Console « Plateforme » : santé technique, qualité des données, adoption
/// des fonctionnalités et réglages d'exploitation.
class AdminPlatformPage extends StatefulWidget {
  const AdminPlatformPage({super.key, required this.onNavigate});

  /// 0 = dashboard, 1 = stylistes, 2 = abonnements.
  final ValueChanged<int> onNavigate;

  @override
  State<AdminPlatformPage> createState() => _AdminPlatformPageState();
}

class _AdminPlatformPageState extends State<AdminPlatformPage> {
  static const _tabs = [
    'VUE D\'ENSEMBLE',
    'QUALITÉ',
    'ADOPTION',
    'SYSTÈME',
  ];

  PlatformSnapshot? _snapshot;
  Object? _error;
  bool _loading = true;
  int _tab = 0;
  QualityIssueType? _qualityFilter;

  @override
  void initState() {
    super.initState();
    _load(force: true);
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot =
          await PlatformHealthService.instance.loadSnapshot(force: force);
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<PlatformConfigService>();
    final snapshot = _snapshot;

    return AdminPageBody(
      children: [
        AdminPageHeader(
          title: 'Plateforme',
          subtitle: snapshot == null
              ? 'Santé, qualité des données et adoption'
              : '${snapshot.users.total} utilisateurs · ${snapshot.quality.total} anomalies · ${snapshot.usage.totalEvents} événements sur ${snapshot.usage.windowDays} j',
          actions: [
            AdminButton(
              label: _loading ? 'Chargement…' : 'Actualiser',
              icon: Icons.refresh_rounded,
              onTap: _loading ? null : () => _load(force: true),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_error != null)
          AdminInfoBanner(
            icon: Icons.cloud_off_rounded,
            text:
                'Impossible de charger la santé de la plateforme : $_error. Vérifiez la connexion Firestore et les règles.',
            accent: context.colors.statusProblem,
            action: AdminButton(
              label: 'Réessayer',
              small: true,
              onTap: () => _load(force: true),
            ),
          )
        else if (snapshot == null)
          const AdminPanel(
            child: AdminEmptyState(
              icon: Icons.monitor_heart_outlined,
              title: 'Chargement de la santé de la plateforme…',
              message: 'Lecture des comptes, commandes et télémétrie.',
            ),
          )
        else ...[
          _SummaryKpis(snapshot: snapshot),
          if (snapshot.warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            AdminInfoBanner(
              icon: Icons.info_outline_rounded,
              text: snapshot.warnings.join(' · '),
              accent: context.colors.statusInProgress,
            ),
          ],
          const SizedBox(height: 18),
          AdminFilterChips(
            labels: _tabs,
            selected: _tab,
            onSelect: (index) => setState(() => _tab = index),
          ),
          const SizedBox(height: 16),
          switch (_tab) {
            1 => _QualityTab(
                snapshot: snapshot,
                filter: _qualityFilter,
                onFilter: (type) => setState(() => _qualityFilter = type),
                onOpenAccount: () => widget.onNavigate(1),
              ),
            2 => _AdoptionTab(usage: snapshot.usage),
            3 => _SystemTab(
                snapshot: snapshot,
                config: config,
                onReload: () => _load(force: true),
              ),
            _ => _OverviewTab(
                snapshot: snapshot,
                config: config,
                onOpenQuality: (type) => setState(() {
                  _tab = 1;
                  _qualityFilter = type;
                }),
                onOpenAdoption: () => setState(() => _tab = 2),
                onOpenSystem: () => setState(() => _tab = 3),
              ),
          },
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI de synthèse
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryKpis extends StatelessWidget {
  const _SummaryKpis({required this.snapshot});

  final PlatformSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final users = snapshot.users;
    final quality = snapshot.quality;
    final errors = snapshot.errors.length;

    const gap = 16.0;
    final cards = <Widget>[
      AdminKpiCard(
        label: 'UTILISATEURS',
        value: '${users.total}',
        icon: Icons.people_alt_rounded,
        accent: c.secondary,
        hint:
            '${users.count(UserRole.stylist)} stylistes · ${users.count(UserRole.tailor)} couturiers',
      ),
      AdminKpiCard(
        label: 'ACTIFS · 30 J',
        value: '${users.active30d}',
        icon: Icons.bolt_rounded,
        accent: c.statusDone,
        hint: '+${users.new30d} nouveaux comptes sur 30 j',
      ),
      AdminKpiCard(
        label: 'ANOMALIES',
        value: '${quality.total}',
        icon: Icons.rule_rounded,
        accent: c.statusInProgress,
        hint:
            '${quality.count(QualityIssueType.duplicateEmail)} doublons · ${quality.count(QualityIssueType.dormantOrder)} commandes dormantes',
        highlight: quality.total > 0,
      ),
      AdminKpiCard(
        label: 'ERREURS RÉCENTES',
        value: '$errors',
        icon: Icons.bug_report_outlined,
        accent: errors > 0 ? c.statusProblem : c.statusDone,
        hint: errors > 0 ? 'à examiner dans Système' : 'aucune erreur journalisée',
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
// Vue d'ensemble
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.snapshot,
    required this.config,
    required this.onOpenQuality,
    required this.onOpenAdoption,
    required this.onOpenSystem,
  });

  final PlatformSnapshot snapshot;
  final PlatformConfigService config;
  final ValueChanged<QualityIssueType> onOpenQuality;
  final VoidCallback onOpenAdoption;
  final VoidCallback onOpenSystem;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1060;
            final left = Column(
              children: [
                _UserBreakdownPanel(snapshot: snapshot),
                const SizedBox(height: 18),
                _QualitySummaryPanel(
                  snapshot: snapshot,
                  onOpen: onOpenQuality,
                ),
              ],
            );
            final right = Column(
              children: [
                _AdoptionSummaryPanel(
                  usage: snapshot.usage,
                  onOpen: onOpenAdoption,
                ),
                const SizedBox(height: 18),
                _SystemSummaryPanel(
                  snapshot: snapshot,
                  config: config,
                  onOpen: onOpenSystem,
                ),
              ],
            );
            if (!wide) {
              return Column(
                children: [left, const SizedBox(height: 18), right],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: left),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: right),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UserBreakdownPanel extends StatelessWidget {
  const _UserBreakdownPanel({required this.snapshot});

  final PlatformSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final users = snapshot.users;
    final maxCount = users.byRole.values.isEmpty
        ? 0
        : users.byRole.values.reduce((a, b) => a > b ? a : b);

    return AdminPanel(
      title: 'Répartition des utilisateurs',
      subtitle:
          '${users.total} comptes · ${users.active30d} actifs sur 30 jours',
      trailing: AdminBadge(
        label: '+${users.new30d} / 30 J',
        foreground: c.statusDone,
        background: c.statusDoneBg,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          children: [
            for (final role in UserRole.values) ...[
              _RoleRow(
                role: role,
                count: users.count(role),
                maxCount: maxCount,
                total: users.total,
                color: _roleColor(role, c),
              ),
              if (role != UserRole.values.last) const SizedBox(height: 15),
            ],
          ],
        ),
      ),
    );
  }

  Color _roleColor(UserRole role, AppColorPalette c) => switch (role) {
        UserRole.admin => c.goldInk,
        UserRole.companyOwner => c.secondary,
        UserRole.stylist => c.statusInProgress,
        UserRole.tailor => c.statusDone,
      };
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.role,
    required this.count,
    required this.maxCount,
    required this.total,
    required this.color,
  });

  final UserRole role;
  final int count;
  final int maxCount;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
                role.label,
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
            const SizedBox(width: 8),
            SizedBox(
              width: 38,
              child: Text(
                '${total == 0 ? 0 : (count / total * 100).round()} %',
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

class _QualitySummaryPanel extends StatelessWidget {
  const _QualitySummaryPanel({required this.snapshot, required this.onOpen});

  final PlatformSnapshot snapshot;
  final ValueChanged<QualityIssueType> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final quality = snapshot.quality;
    final types = QualityIssueType.values;

    return AdminPanel(
      title: 'Qualité des données',
      subtitle:
          '${quality.usersScanned} comptes et ${quality.ordersScanned} commandes examinés',
      trailing: AdminBadge(
        label: '${quality.total}',
        foreground: quality.total > 0 ? c.onTertiaryContainer : c.statusDone,
        background: quality.total > 0 ? c.tertiaryContainer : c.statusDoneBg,
      ),
      clip: true,
      child: Column(
        children: [
          for (final type in types) ...[
            _QualitySummaryRow(
              type: type,
              count: quality.count(type),
              onTap: () => onOpen(type),
            ),
            if (type != types.last)
              Divider(
                height: 1,
                color: c.outlineVariant.withValues(alpha: 0.55),
              ),
          ],
        ],
      ),
    );
  }
}

class _QualitySummaryRow extends StatelessWidget {
  const _QualitySummaryRow({
    required this.type,
    required this.count,
    required this.onTap,
  });

  final QualityIssueType type;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = count == 0 ? c.statusDone : _severityColor(type, c);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              Icon(type.icon, size: 15, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  type.label,
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 12.5,
                    color: c.onSurface,
                  ),
                ),
              ),
              Text(
                '$count',
                style: AppTextStyles.titleSm.copyWith(
                  fontSize: 12.5,
                  color: count == 0 ? c.onSurfaceVariant : color,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: c.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdoptionSummaryPanel extends StatelessWidget {
  const _AdoptionSummaryPanel({required this.usage, required this.onOpen});

  final FeatureUsageReport usage;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = usage.stats.where((stat) => stat.events > 0).take(3).toList();

    return AdminPanel(
      title: 'Adoption',
      subtitle: '${usage.totalEvents} événements · ${usage.uniqueUsers} utilisateurs',
      trailing: AdminButton(
        label: 'Détail',
        icon: Icons.arrow_forward_rounded,
        small: true,
        onTap: onOpen,
      ),
      child: top.isEmpty
          ? const AdminEmptyState(
              icon: Icons.insights_outlined,
              title: 'Pas encore d\'événements',
              message:
                  'Les usages apparaîtront dès que les comptes utiliseront l\'application.',
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                children: [
                  for (var i = 0; i < top.length; i++) ...[
                    _FeaturePreviewRow(stat: top[i], total: usage.totalEvents),
                    if (i != top.length - 1) const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'Fenêtre d\'analyse : ${usage.windowDays} derniers jours',
                    style: AppTextStyles.labelXs.copyWith(
                      color: c.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FeaturePreviewRow extends StatelessWidget {
  const _FeaturePreviewRow({required this.stat, required this.total});

  final FeatureUsageStat stat;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final info = stat.info;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: c.surfaceContainerLow,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(info.icon, size: 15, color: c.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      info.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${stat.events}',
                    style: AppTextStyles.labelXs.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              AdminProgressBar(
                value: total == 0 ? 0 : stat.events / total,
                color: c.secondary,
                height: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SystemSummaryPanel extends StatelessWidget {
  const _SystemSummaryPanel({
    required this.snapshot,
    required this.config,
    required this.onOpen,
  });

  final PlatformSnapshot snapshot;
  final PlatformConfigService config;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final jobsOk =
        snapshot.jobs.where((job) => job.state == PlatformJobState.ok).length;
    final jobsProblem = snapshot.jobs
        .where((job) =>
            job.state == PlatformJobState.error ||
            job.state == PlatformJobState.warning)
        .length;

    return AdminPanel(
      title: 'Système',
      subtitle: 'Version ${snapshot.appVersion}',
      trailing: AdminButton(
        label: 'Gérer',
        icon: Icons.tune_rounded,
        small: true,
        onTap: onOpen,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          children: [
            _StatusLine(
              icon: Icons.construction_rounded,
              label: 'Maintenance',
              value: config.maintenanceMode ? 'Activée' : 'Désactivée',
              color: config.maintenanceMode ? c.statusProblem : c.statusDone,
            ),
            _StatusLine(
              icon: Icons.schedule_rounded,
              label: 'Jobs planifiés',
              value: jobsProblem > 0
                  ? '$jobsProblem à surveiller'
                  : '$jobsOk opérationnels',
              color: jobsProblem > 0 ? c.statusInProgress : c.statusDone,
            ),
            _StatusLine(
              icon: Icons.bug_report_outlined,
              label: 'Erreurs récentes',
              value: '${snapshot.errors.length}',
              color: snapshot.errors.isEmpty
                  ? c.statusDone
                  : c.statusProblem,
            ),
            _StatusLine(
              icon: Icons.storage_rounded,
              label: 'Stockage mesuré',
              value: snapshot.storage.available
                  ? _formatBytes(snapshot.storage.bytes!)
                  : 'Non disponible',
              color: snapshot.storage.available
                  ? c.statusDone
                  : c.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 15, color: c.onSurfaceVariant),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySm.copyWith(
                fontSize: 12,
                color: c.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelCaps.copyWith(
              fontSize: 9.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Qualité
// ─────────────────────────────────────────────────────────────────────────────

class _QualityTab extends StatelessWidget {
  const _QualityTab({
    required this.snapshot,
    required this.filter,
    required this.onFilter,
    required this.onOpenAccount,
  });

  final PlatformSnapshot snapshot;
  final QualityIssueType? filter;
  final ValueChanged<QualityIssueType?> onFilter;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final quality = snapshot.quality;
    final issues = filter == null
        ? quality.sortedBySeverity
        : quality.ofType(filter!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanel(
          title: 'Filtres',
          subtitle: '${quality.total} anomalies sur ${quality.usersScanned} comptes',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'TOUT (${quality.total})',
                  selected: filter == null,
                  onTap: () => onFilter(null),
                ),
                for (final type in QualityIssueType.values)
                  _FilterChip(
                    label: '${type.label.toUpperCase()} (${quality.count(type)})',
                    selected: filter == type,
                    onTap: () => onFilter(type),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (issues.isEmpty)
          const AdminPanel(
            child: AdminEmptyState(
              icon: Icons.verified_rounded,
              title: 'Aucune anomalie',
              message: 'Les comptes et commandes examinés sont cohérents.',
            ),
          )
        else
          AdminPanel(
            clip: true,
            padding: EdgeInsets.zero,
            title: 'Anomalies',
            subtitle:
                '${issues.length} élément${issues.length > 1 ? 's' : ''} à traiter',
            child: AdminTable(
              minWidth: 940,
              columns: const [
                AdminColumn('TYPE', width: 176),
                AdminColumn('COMPTE / COMMANDE', flex: 3),
                AdminColumn('DÉTAIL', flex: 4),
                AdminColumn('JOURS', width: 64, align: TextAlign.right),
                AdminColumn('', width: 72, align: TextAlign.right),
              ],
              rows: [
                for (final issue in issues.take(200))
                  AdminRow(
                    [
                      AdminBadge(
                        label: issue.type.label.toUpperCase(),
                        foreground: _severityColor(issue.type, c),
                        background: _severityColor(issue.type, c)
                            .withValues(alpha: 0.10),
                        icon: issue.type.icon,
                      ),
                      Text(
                        issue.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSm.copyWith(
                          fontSize: 12.5,
                          color: c.onSurface,
                        ),
                      ),
                      Text(
                        issue.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          fontSize: 11.5,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        issue.days == null ? '—' : '${issue.days}',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodySm.copyWith(
                          fontSize: 12,
                          color: issue.days != null && issue.days! >= 60
                              ? c.statusProblem
                              : c.onSurface,
                        ),
                      ),
                      if (issue.userId != null)
                        AdminIconAction(
                          icon: Icons.person_search_rounded,
                          tooltip: 'Ouvrir les comptes',
                          color: c.onSurface,
                          background: c.surfaceContainerLow,
                          onTap: onOpenAccount,
                        )
                      else
                        AdminIconAction(
                          icon: Icons.copy_rounded,
                          tooltip: "Copier l'identifiant",
                          color: c.onSurface,
                          background: c.surfaceContainerLow,
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: issue.orderId ?? issue.title),
                            );
                            showAdminSnack(context, 'Identifiant copié.');
                          },
                        ),
                    ],
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        AdminInfoBanner(
          icon: Icons.info_outline_rounded,
          text:
              'Seuils : inactivité 30/60/90 jours depuis la dernière connexion connue, commande dormante après 14 jours sans changement de statut. Les comptes historiques sans date de connexion utilisent leur date de création.',
          accent: c.secondary,
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : c.outlineVariant.withValues(alpha: 0.9),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.labelXs.copyWith(
              color: selected ? c.onPrimary : c.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Adoption
// ─────────────────────────────────────────────────────────────────────────────

class _AdoptionTab extends StatelessWidget {
  const _AdoptionTab({required this.usage});

  final FeatureUsageReport usage;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = usage.topFeature;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 16.0;
            final columns = constraints.maxWidth >= 1040
                ? 4
                : (constraints.maxWidth >= 640 ? 2 : 1);
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            final cards = [
              AdminKpiCard(
                label: 'ÉVÉNEMENTS · 30 J',
                value: '${usage.totalEvents}',
                icon: Icons.bolt_rounded,
                accent: c.secondary,
                hint: 'toutes fonctionnalités confondues',
              ),
              AdminKpiCard(
                label: 'UTILISATEURS ACTIFS',
                value: '${usage.uniqueUsers}',
                icon: Icons.people_alt_rounded,
                accent: c.statusDone,
                hint: 'au moins un usage sur 30 j',
              ),
              AdminKpiCard(
                label: 'TOP FONCTIONNALITÉ',
                value: top == null ? '—' : '${top.events}',
                icon: top?.info.icon ?? Icons.insights_rounded,
                accent: c.goldInk,
                hint: top == null ? 'pas encore de données' : top.info.label,
              ),
              AdminKpiCard(
                label: 'USAGES / UTILISATEUR',
                value: usage.uniqueUsers == 0
                    ? '—'
                    : (usage.totalEvents / usage.uniqueUsers).toStringAsFixed(1),
                icon: Icons.percent_rounded,
                accent: c.statusInProgress,
                hint: 'moyenne sur la fenêtre',
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
        if (usage.totalEvents == 0)
          const AdminPanel(
            child: AdminEmptyState(
              icon: Icons.insights_outlined,
              title: 'Aucun événement sur la période',
              message:
                  'Les événements sont enregistrés au fur et à mesure des usages réels : création de commande, encaissement, export PDF, support…',
            ),
          )
        else
          AdminPanel(
            clip: true,
            padding: EdgeInsets.zero,
            title: 'Classement des fonctionnalités',
            subtitle:
                '${usage.totalEvents} événements · fenêtre de ${usage.windowDays} jours',
            trailing: AdminBadge(
              label: '${usage.uniqueUsers} UTILISATEURS',
              foreground: c.onSurfaceVariant,
              background: c.surfaceContainerHigh,
            ),
            child: AdminTable(
              minWidth: 980,
              columns: const [
                AdminColumn('FONCTIONNALITÉ', flex: 3),
                AdminColumn('ÉVÉNEMENTS', width: 104, align: TextAlign.right),
                AdminColumn('UTILISATEURS', width: 106, align: TextAlign.right),
                AdminColumn('PART', width: 150),
                AdminColumn('TENDANCE 7 J', width: 116, align: TextAlign.right),
                AdminColumn('DERNIER USAGE', width: 118, align: TextAlign.right),
              ],
              rows: [
                for (final stat in usage.stats.where((s) => s.events > 0))
                  AdminRow(
                    [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              stat.info.icon,
                              size: 16,
                              color: c.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  stat.info.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.titleSm.copyWith(
                                    fontSize: 12.5,
                                    color: c.onSurface,
                                  ),
                                ),
                                Text(
                                  stat.info.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySm.copyWith(
                                    fontSize: 10.5,
                                    color: c.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${stat.events}',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.titleSm.copyWith(
                          fontSize: 12.5,
                          color: c.onSurface,
                        ),
                      ),
                      Text(
                        '${stat.uniqueUsers}',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodySm.copyWith(
                          fontSize: 12,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AdminProgressBar(
                            value:
                                usage.totalEvents == 0 ? 0 : stat.events / usage.totalEvents,
                            color: c.secondary,
                            height: 6,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(stat.events / usage.totalEvents * 100).round()} %',
                            style: AppTextStyles.labelXs.copyWith(
                              fontSize: 8.5,
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      _TrendBadge(stat: stat),
                      Text(
                        stat.lastUsedAt == null
                            ? '—'
                            : _relative(stat.lastUsedAt!),
                        textAlign: TextAlign.right,
                        style: AppTextStyles.bodySm.copyWith(
                          fontSize: 11,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        AdminInfoBanner(
          icon: Icons.privacy_tip_outlined,
          text:
              'Télémétrie sans données personnelles : seule la clé de fonctionnalité et l\'identifiant du compte sont enregistrés. Aucun contenu de commande, nom ou téléphone n\'est transmis.',
          accent: c.secondary,
        ),
      ],
    );
  }

  static String _relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'il y a ${diff.inDays} j';
    if (diff.inHours > 0) return 'il y a ${diff.inHours} h';
    if (diff.inMinutes > 0) return 'il y a ${diff.inMinutes} min';
    return 'à l\'instant';
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.stat});

  final FeatureUsageStat stat;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final trend = stat.trend;
    if (trend == null) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          '—',
          style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
        ),
      );
    }

    final up = trend >= 0;
    final percent = (trend.abs() * 100).round();
    return Align(
      alignment: Alignment.centerRight,
      child: AdminBadge(
        label: '$percent %',
        foreground: up ? c.statusDone : c.statusProblem,
        background: up ? c.statusDoneBg : c.statusProblemBg,
        icon: up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Système
// ─────────────────────────────────────────────────────────────────────────────

class _SystemTab extends StatelessWidget {
  const _SystemTab({
    required this.snapshot,
    required this.config,
    required this.onReload,
  });

  final PlatformSnapshot snapshot;
  final PlatformConfigService config;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MaintenancePanel(config: config, onSaved: onReload),
        const SizedBox(height: 18),
        _FeatureFlagsPanel(config: config),
        const SizedBox(height: 18),
        _VersionPanel(config: config),
        const SizedBox(height: 18),
        _JobsPanel(jobs: snapshot.jobs),
        const SizedBox(height: 18),
        _StoragePanel(storage: snapshot.storage),
        const SizedBox(height: 18),
        _ErrorsPanel(errors: snapshot.errors),
      ],
    );
  }
}

class _MaintenancePanel extends StatefulWidget {
  const _MaintenancePanel({required this.config, required this.onSaved});

  final PlatformConfigService config;
  final VoidCallback onSaved;

  @override
  State<_MaintenancePanel> createState() => _MaintenancePanelState();
}

class _MaintenancePanelState extends State<_MaintenancePanel> {
  late final TextEditingController _messageController =
      TextEditingController(text: widget.config.maintenanceMessage);
  bool _saving = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _toggle(bool value) async {
    setState(() => _saving = true);
    try {
      await widget.config.setMaintenance(
        value,
        message: _messageController.text,
      );
      if (!mounted) return;
      showAdminSnack(
        context,
        value
            ? 'Mode maintenance activé. Les utilisateurs voient l\'écran de maintenance.'
            : 'Mode maintenance désactivé. La plateforme est de nouveau accessible.',
      );
      widget.onSaved();
    } catch (_) {
      if (!mounted) return;
      showAdminSnack(context, 'Impossible de modifier le mode maintenance.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminPanel(
      title: 'Mode maintenance',
      subtitle:
          'Bloque l\'accès aux comptes non-admin. Les administrateurs restent connectés.',
      trailing: Switch.adaptive(
        value: widget.config.maintenanceMode,
        onChanged: _saving ? null : _toggle,
        activeThumbColor: c.statusProblem,
        activeTrackColor: c.statusProblemBg,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'MESSAGE AFFICHÉ AUX UTILISATEURS',
              style: AppTextStyles.labelCaps.copyWith(
                color: c.onSurfaceVariant,
                fontSize: 9,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: _messageController,
              maxLines: 2,
              style: AppTextStyles.bodySm.copyWith(
                fontSize: 12.5,
                color: c.onSurface,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.surfaceContainerLow,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.goldInk, width: 1.3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: AdminButton(
                label: 'Enregistrer le message',
                icon: Icons.save_rounded,
                small: true,
                onTap: _saving
                    ? null
                    : () async {
                        await widget.config.setMaintenance(
                          widget.config.maintenanceMode,
                          message: _messageController.text,
                        );
                        if (!context.mounted) return;
                        showAdminSnack(context, 'Message de maintenance enregistré.');
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureFlagsPanel extends StatelessWidget {
  const _FeatureFlagsPanel({required this.config});

  final PlatformConfigService config;

  static const _labels = {
    'pdfExport': ('Export PDF', 'Devis et factures PDF'),
    'supportMessaging': ('Messagerie support', 'Contact et réponses support'),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final keys = _labels.keys.toList();

    return AdminPanel(
      title: 'Feature flags',
      subtitle:
          'Activez ou coupez une fonctionnalité sans redéployer l\'application.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          children: [
            for (var i = 0; i < keys.length; i++) ...[
              _FlagRow(
                label: _labels[keys[i]]!.$1,
                description: _labels[keys[i]]!.$2,
                value: config.isEnabled(keys[i]),
                onChanged: (value) async {
                  try {
                    await config.setFeatureFlag(keys[i], value);
                    if (!context.mounted) return;
                    showAdminSnack(
                      context,
                      '${_labels[keys[i]]!.$1} ${value ? 'activé' : 'désactivé'}.',
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    showAdminSnack(
                      context,
                      'Impossible de modifier ce flag.',
                      error: true,
                    );
                  }
                },
              ),
              if (i != keys.length - 1)
                Divider(
                  height: 1,
                  color: c.outlineVariant.withValues(alpha: 0.6),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FlagRow extends StatelessWidget {
  const _FlagRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.titleSm.copyWith(
                    fontSize: 12.5,
                    color: c.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 11,
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: c.statusDone,
            activeTrackColor: c.statusDoneBg,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _VersionPanel extends StatefulWidget {
  const _VersionPanel({required this.config});

  final PlatformConfigService config;

  @override
  State<_VersionPanel> createState() => _VersionPanelState();
}

class _VersionPanelState extends State<_VersionPanel> {
  late final TextEditingController _notesController =
      TextEditingController(text: widget.config.releaseNotes);
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.config.saveReleaseNotes(_notesController.text);
      if (!mounted) return;
      showAdminSnack(context, 'Notes de version enregistrées.');
    } catch (_) {
      if (!mounted) return;
      showAdminSnack(context, 'Impossible d\'enregistrer les notes.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminPanel(
      title: 'Version & notes de version',
      subtitle: 'Version actuellement déployée : ${widget.config.version}',
      trailing: AdminBadge(
        label: 'v${widget.config.version}',
        foreground: c.onSurfaceVariant,
        background: c.surfaceContainerHigh,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'NOUVEAUTÉS À COMMUNIQUER',
              style: AppTextStyles.labelCaps.copyWith(
                color: c.onSurfaceVariant,
                fontSize: 9,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: _notesController,
              maxLines: 4,
              style: AppTextStyles.bodySm.copyWith(
                fontSize: 12.5,
                color: c.onSurface,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.surfaceContainerLow,
                isDense: true,
                hintText:
                    'Ex. Novembre 2026 : export PDF plus rapide, relances d\'expiration, nouveau tableau de bord.',
                hintStyle: AppTextStyles.bodySm.copyWith(
                  fontSize: 12,
                  color: c.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.goldInk, width: 1.3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: AdminButton(
                label: 'Enregistrer les notes',
                icon: Icons.save_rounded,
                small: true,
                onTap: _saving ? null : _save,
              ),
            ),
            if (widget.config.releaseNotesUpdatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Dernière mise à jour : ${Formatters.dateTime.format(widget.config.releaseNotesUpdatedAt!)}',
                textAlign: TextAlign.right,
                style: AppTextStyles.labelXs.copyWith(
                  fontSize: 9,
                  color: c.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JobsPanel extends StatelessWidget {
  const _JobsPanel({required this.jobs});

  final List<PlatformJobStatus> jobs;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminPanel(
      title: 'Jobs planifiés',
      subtitle:
          'État des tâches d\'exploitation (snapshots, relances, purge, stockage).',
      trailing: AdminBadge(
        label: '${jobs.where((j) => j.state == PlatformJobState.ok).length}/${jobs.length} OK',
        foreground: c.onSurfaceVariant,
        background: c.surfaceContainerHigh,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Column(
          children: [
            for (var i = 0; i < jobs.length; i++) ...[
              _JobRow(job: jobs[i]),
              if (i != jobs.length - 1)
                Divider(
                  height: 1,
                  color: c.outlineVariant.withValues(alpha: 0.6),
                ),
            ],
            const SizedBox(height: 12),
            AdminInfoBanner(
              icon: Icons.cloud_sync_outlined,
              text:
                  'Ces jobs nécessitent Cloud Functions (plan Blaze). Tant qu\'ils ne sont pas déployés, leur état reste « Non configuré ».',
              accent: c.statusInProgress,
            ),
          ],
        ),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});

  final PlatformJobStatus job;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fg, bg) = switch (job.state) {
      PlatformJobState.ok => (c.statusDone, c.statusDoneBg),
      PlatformJobState.warning => (c.statusInProgress, c.statusInProgressBg),
      PlatformJobState.error => (c.statusProblem, c.statusProblemBg),
      PlatformJobState.notConfigured => (
          c.onSurfaceVariant,
          c.surfaceContainerHigh
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.label,
                  style: AppTextStyles.titleSm.copyWith(
                    fontSize: 12.5,
                    color: c.onSurface,
                  ),
                ),
                Text(
                  job.message?.isNotEmpty == true
                      ? job.message!
                      : job.description,
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 11,
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (job.lastRunAt != null)
            Text(
              'Dernière exécution : ${Formatters.dateTime.format(job.lastRunAt!)}',
              style: AppTextStyles.labelXs.copyWith(
                fontSize: 8.5,
                color: c.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 10),
          AdminBadge(label: job.state.label, foreground: fg, background: bg),
        ],
      ),
    );
  }
}

class _StoragePanel extends StatelessWidget {
  const _StoragePanel({required this.storage});

  final StorageUsage storage;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminPanel(
      title: 'Stockage',
      subtitle: storage.available
          ? 'Espace utilisé mesuré par l\'audit de stockage'
          : 'Mesure non disponible depuis le navigateur',
      trailing: AdminBadge(
        label: storage.available ? _formatBytes(storage.bytes!) : 'NON MESURÉ',
        foreground: storage.available ? c.statusDone : c.onSurfaceVariant,
        background:
            storage.available ? c.statusDoneBg : c.surfaceContainerHigh,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (storage.available)
              AdminProgressBar(
                value: _storageRatio(storage.bytes!),
                color: c.secondary,
                height: 8,
              ),
            if (storage.updatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Dernière mesure : ${Formatters.dateTime.format(storage.updatedAt!)}',
                style: AppTextStyles.labelXs.copyWith(
                  fontSize: 9,
                  color: c.onSurfaceVariant,
                ),
              ),
            ],
            if (storage.note != null) ...[
              const SizedBox(height: 10),
              Text(
                storage.note!,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 11.5,
                  height: 1.5,
                  color: c.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static double _storageRatio(int bytes) {
    // Repère indicatif : 1 Go. Le quota réel dépend du plan Firebase.
    const reference = 1024 * 1024 * 1024;
    return (bytes / reference).clamp(0, 1);
  }
}

class _ErrorsPanel extends StatelessWidget {
  const _ErrorsPanel({required this.errors});

  final List<PlatformErrorRecord> errors;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminPanel(
      title: 'Erreurs récentes',
      subtitle: errors.isEmpty
          ? 'Aucune erreur remontée par les clients'
          : '${errors.length} erreur${errors.length > 1 ? 's' : ''} journalisée${errors.length > 1 ? 's' : ''}',
      trailing: AdminBadge(
        label: '${errors.length}',
        foreground: errors.isEmpty ? c.statusDone : c.statusProblem,
        background: errors.isEmpty ? c.statusDoneBg : c.statusProblemBg,
      ),
      clip: true,
      padding: EdgeInsets.zero,
      child: errors.isEmpty
          ? const AdminEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Aucune erreur récente',
              message:
                  'Les erreurs non fatales de l\'application et de la console apparaîtront ici.',
            )
          : Column(
              children: [
                for (var i = 0; i < errors.length && i < 10; i++) ...[
                  _ErrorRow(record: errors[i]),
                  if (i != errors.length - 1 && i != 9)
                    Divider(
                      height: 1,
                      color: c.outlineVariant.withValues(alpha: 0.6),
                    ),
                ],
              ],
            ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.record});

  final PlatformErrorRecord record;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      iconColor: c.onSurfaceVariant,
      collapsedIconColor: c.onSurfaceVariant,
      title: Text(
        record.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySm.copyWith(
          fontSize: 12,
          color: c.onSurface,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${Formatters.dateTime.format(record.createdAt)} · ${record.platform ?? 'inconnu'} · v${record.appVersion ?? '?'}',
          style: AppTextStyles.labelXs.copyWith(
            fontSize: 8.5,
            color: c.onSurfaceVariant,
          ),
        ),
      ),
      children: [
        if (record.context != null && record.context!.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              record.context!,
              style: AppTextStyles.bodySm.copyWith(
                fontSize: 11,
                color: c.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            record.stack ?? 'Pas de pile d\'appels disponible.',
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 10,
              height: 1.45,
              color: c.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

Color _severityColor(QualityIssueType type, AppColorPalette c) => switch (type) {
      QualityIssueType.duplicateEmail => c.statusProblem,
      QualityIssueType.missingAtelier => c.statusInProgress,
      QualityIssueType.dormantOrder => c.statusInProgress,
      QualityIssueType.inactive90 => c.statusProblem,
      QualityIssueType.inactive60 => c.statusInProgress,
      _ => c.onSurfaceVariant,
    };

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} Go';
  }
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} Ko';
  }
  return '$bytes o';
}
