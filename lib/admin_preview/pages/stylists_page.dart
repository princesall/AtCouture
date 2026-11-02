import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../preview_data.dart';
import '../widgets/preview_kit.dart';

class StylistsPage extends StatefulWidget {
  const StylistsPage({super.key});

  @override
  State<StylistsPage> createState() => _StylistsPageState();
}

class _StylistsPageState extends State<StylistsPage> {
  int _filter = 0;
  String _query = '';

  static const _filters = ['TOUS', 'ACTIFS', 'EXPIRE BIENTÔT', 'SUSPENDUS'];

  List<PreviewStylist> get _filtered {
    final query = _query.trim().toLowerCase();
    return previewStylists.where((stylist) {
      final matchesQuery = query.isEmpty ||
          stylist.name.toLowerCase().contains(query) ||
          stylist.atelier.toLowerCase().contains(query) ||
          stylist.email.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        1 => stylist.status == PreviewAccountStatus.active,
        2 => stylist.status == PreviewAccountStatus.expiring,
        3 => stylist.status == PreviewAccountStatus.suspended,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final stylists = _filtered;

    return PreviewPageBody(
      children: [
        const PreviewPageHeader(
          title: 'Stylistes',
          subtitle: '128 comptes · 112 actifs · 6 suspendus · 10 expirés',
          actions: [
            PreviewButton(label: 'Exporter', icon: Icons.download_rounded),
            PreviewButton(
              label: 'Créer un compte',
              icon: Icons.add_rounded,
              primary: true,
            ),
          ],
        ),
        const SizedBox(height: 22),
        PreviewPanel(
          clip: true,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildToolbar(context),
              Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
              if (stylists.isEmpty)
                _EmptyState(query: _query)
              else
                AdminTable(
                  columns: const [
                    AdminColumn('', width: 40),
                    AdminColumn('STYLISTE', flex: 3),
                    AdminColumn('ATELIER', flex: 2),
                    AdminColumn('PLAN', width: 108),
                    AdminColumn('STATUT', width: 126),
                    AdminColumn('CMD', width: 62, align: TextAlign.right),
                    AdminColumn('CA / MOIS', width: 108, align: TextAlign.right),
                    AdminColumn('EXPIRATION', width: 112, align: TextAlign.right),
                    AdminColumn('', width: 40, align: TextAlign.right),
                  ],
                  rows: [
                    for (final stylist in stylists)
                      AdminRow(_cellsFor(stylist), onTap: () {}),
                  ],
                ),
              Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                child: PreviewPagination(
                  label: 'Affichage de ${stylists.length} compte(s) sur 128',
                  page: 1,
                  pages: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PreviewInfoBanner(
          icon: Icons.touch_app_rounded,
          text:
              'Cliquez une ligne pour ouvrir la fiche du compte. La sélection multiple '
              'permettra les actions groupées (relance, export, suspension).',
          accent: c.secondary,
        ),
      ],
    );
  }

  List<Widget> _cellsFor(PreviewStylist stylist) {
    final c = context.colors;
    return [
      const PreviewCheckbox(),
      Row(
        children: [
          PreviewAvatar(
            initials: stylist.initials,
            size: 36,
            online: stylist.online,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stylist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSm.copyWith(
                    fontSize: 13.5,
                    color: c.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  stylist.email,
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
            stylist.atelier,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 12.5,
              color: c.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${stylist.city} · ${stylist.lastActive}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 11,
              color: c.onSurfaceVariant,
            ),
          ),
        ],
      ),
      PreviewPlanBadge(plan: stylist.plan),
      PreviewStatusBadge(status: stylist.status),
      Text(
        '${stylist.orders}',
        textAlign: TextAlign.right,
        style: AppTextStyles.bodySm.copyWith(
          fontSize: 12.5,
          color: c.onSurface,
        ),
      ),
      Text(
        stylist.revenue == 0 ? '—' : compactFcfa(stylist.revenue),
        textAlign: TextAlign.right,
        style: AppTextStyles.titleSm.copyWith(
          fontSize: 12.5,
          color: stylist.revenue == 0 ? c.onSurfaceVariant : c.onSurface,
        ),
      ),
      _ExpirationCell(days: stylist.expiresInDays),
      Icon(Icons.more_horiz_rounded, size: 18, color: c.onSurfaceVariant),
    ];
  }

  Widget _buildToolbar(BuildContext context) {
    final chips = PreviewFilterChips(
      labels: _filters,
      selected: _filter,
      onSelect: (index) => setState(() => _filter = index),
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        PreviewButton(label: 'Filtres', icon: Icons.filter_list_rounded),
        SizedBox(width: 8),
        PreviewButton(label: 'Colonnes', icon: Icons.view_column_rounded),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 980) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PreviewSearchField(
                  hint: 'Rechercher un nom, un atelier, un email…',
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                chips,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }
          return Row(
            children: [
              PreviewSearchField(
                hint: 'Rechercher un nom, un atelier, un email…',
                width: 300,
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(width: 16),
              Expanded(child: chips),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _ExpirationCell extends StatelessWidget {
  const _ExpirationCell({required this.days});

  final int? days;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (days == null) {
      return Text(
        '—',
        textAlign: TextAlign.right,
        style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
      );
    }

    final urgent = days! <= 7;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (urgent) ...[
          Icon(Icons.error_outline_rounded, size: 13, color: c.statusProblem),
          const SizedBox(width: 4),
        ],
        Text(
          'Dans $days j',
          textAlign: TextAlign.right,
          style: AppTextStyles.bodySm.copyWith(
            fontSize: 12,
            color: urgent ? c.statusProblem : c.onSurfaceVariant,
            fontWeight: urgent ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 22,
                color: c.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Aucun compte ne correspond',
              style: AppTextStyles.titleSm.copyWith(color: c.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              query.isEmpty
                  ? 'Changez de filtre pour afficher d\'autres comptes.'
                  : 'Aucun résultat pour « $query ».',
              style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
