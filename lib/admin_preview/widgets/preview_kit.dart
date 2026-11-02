import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../models/subscription_plan.dart';
import '../preview_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Kit de la maquette admin web — composants volontairement autonomes pour
// pouvoir être promus tels quels dans `lib/admin/` lors de la migration.
// Tous les tokens viennent de la palette existante (`context.colors`).
// ─────────────────────────────────────────────────────────────────────────────

/// Zone de contenu scrollable, centrée et bornée — évite les lignes de texte
/// de 2 mètres sur un écran 4K.
class PreviewPageBody extends StatelessWidget {
  const PreviewPageBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 1400 ? 44.0 : (width >= 900 ? 32.0 : 18.0);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// En-tête de page : titre éditorial + sous-titre + actions à droite.
class PreviewPageHeader extends StatelessWidget {
  const PreviewPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.displayLg.copyWith(
            fontSize: 30,
            height: 1.15,
            color: c.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
        ),
      ],
    );

    if (actions.isEmpty) return heading;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              const SizedBox(height: 16),
              Wrap(spacing: 10, runSpacing: 10, children: actions),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 24),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        );
      },
    );
  }
}

/// Panneau blanc bordé — la brique de base des tableaux et cartes.
class PreviewPanel extends StatelessWidget {
  const PreviewPanel({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
    this.clip = false,
    required this.child,
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool clip;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.75)),
        boxShadow: c.softShadow,
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: AppTextStyles.titleMd.copyWith(color: c.onSurface),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
          ],
          Padding(padding: title == null ? padding : EdgeInsets.zero, child: child),
        ],
      ),
    );
  }
}

/// Carte KPI avec delta coloré et icône teintée.
class PreviewKpiCard extends StatelessWidget {
  const PreviewKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.delta,
    this.deltaUp = true,
    this.hint,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? delta;
  final bool deltaUp;
  final String? hint;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 150,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlight ? c.tertiaryContainer : c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight
              ? c.tertiary.withValues(alpha: 0.6)
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: accent),
              ),
              const Spacer(),
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (deltaUp ? c.statusDoneBg : c.statusProblemBg),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        deltaUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 12,
                        color: deltaUp ? c.statusDone : c.statusProblem,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        delta!,
                        style: AppTextStyles.labelXs.copyWith(
                          color: deltaUp ? c.statusDone : c.statusProblem,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.statNumber.copyWith(
              fontSize: value.length > 12 ? 23 : 27,
              color: c.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelCaps.copyWith(
              color: highlight ? c.onTertiaryContainer : c.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(
                color: highlight
                    ? c.onTertiaryContainer.withValues(alpha: 0.7)
                    : c.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pastille générique.
class PreviewBadge extends StatelessWidget {
  const PreviewBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.dot = false,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final bool dot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: 11, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelXs.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class PreviewPlanBadge extends StatelessWidget {
  const PreviewPlanBadge({super.key, required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fg, bg) = switch (plan) {
      SubscriptionPlan.free => (c.onSurfaceVariant, c.surfaceContainerHigh),
      SubscriptionPlan.starter => (c.statusInProgress, c.statusInProgressBg),
      SubscriptionPlan.pro => (c.onSecondaryContainer, c.secondaryContainer),
      SubscriptionPlan.enterprise => (c.onTertiaryContainer, c.tertiaryContainer),
    };
    return PreviewBadge(label: plan.name.toUpperCase(), foreground: fg, background: bg);
  }
}

class PreviewStatusBadge extends StatelessWidget {
  const PreviewStatusBadge({super.key, required this.status});

  final PreviewAccountStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fg, bg) = switch (status) {
      PreviewAccountStatus.active => (c.statusDone, c.statusDoneBg),
      PreviewAccountStatus.expiring => (c.statusInProgress, c.statusInProgressBg),
      PreviewAccountStatus.suspended => (c.statusProblem, c.statusProblemBg),
    };
    return PreviewBadge(label: status.label, foreground: fg, background: bg, dot: true);
  }
}

class PreviewRequestStatusBadge extends StatelessWidget {
  const PreviewRequestStatusBadge({super.key, required this.status});

  final PreviewRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fg, bg) = switch (status) {
      PreviewRequestStatus.pending => (c.statusInProgress, c.statusInProgressBg),
      PreviewRequestStatus.approved => (c.statusDone, c.statusDoneBg),
      PreviewRequestStatus.rejected => (c.statusProblem, c.statusProblemBg),
    };
    return PreviewBadge(label: status.label, foreground: fg, background: bg, dot: true);
  }
}

/// Avatar à initiales — remplace `StylistAvatar` (pensé pour du tactile).
class PreviewAvatar extends StatelessWidget {
  const PreviewAvatar({
    super.key,
    required this.initials,
    this.size = 36,
    this.online = false,
  });

  final String initials;
  final double size;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: c.surfaceContainerHigh,
            shape: BoxShape.circle,
            border: Border.all(color: c.outlineVariant, width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: AppTextStyles.titleSm.copyWith(
              fontSize: size * 0.34,
              color: c.onSurface,
            ),
          ),
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: c.statusDone,
                shape: BoxShape.circle,
                border: Border.all(color: c.surfaceContainerLowest, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bouton maison — évite que `ElevatedButton` impose ses paddings tactiles.
class PreviewButton extends StatelessWidget {
  const PreviewButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.primary = false,
    this.danger = false,
    this.small = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary;
  final bool danger;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = primary ? c.primary : (danger ? c.statusProblemBg : Colors.transparent);
    final fg = primary ? c.onPrimary : (danger ? c.statusProblem : c.onSurface);
    final border = primary
        ? Colors.transparent
        : (danger
            ? c.statusProblem.withValues(alpha: 0.35)
            : c.outlineVariant.withValues(alpha: 0.95));

    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: small ? 32 : 38,
            padding: EdgeInsets.symmetric(horizontal: small ? 10 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: small ? 14 : 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTextStyles.labelCaps.copyWith(
                    color: fg,
                    fontSize: small ? 10 : 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Champ de recherche décoratif mais réellement saisissable.
class PreviewSearchField extends StatelessWidget {
  const PreviewSearchField({
    super.key,
    required this.hint,
    this.width,
    this.onChanged,
  });

  final String hint;
  final double? width;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final field = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 17, color: c.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: AppTextStyles.bodySm.copyWith(color: c.onSurface),
              cursorColor: c.onSurface,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTextStyles.bodySm.copyWith(
                  color: c.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return width == null ? field : SizedBox(width: width, child: field);
  }
}

class PreviewFilterChips extends StatelessWidget {
  const PreviewFilterChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          Material(
            color: i == selected ? c.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: i == selected
                        ? Colors.transparent
                        : c.outlineVariant.withValues(alpha: 0.9),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: AppTextStyles.labelCaps.copyWith(
                    color: i == selected ? c.onPrimary : c.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PreviewProgressBar extends StatelessWidget {
  const PreviewProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 7,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: c.surfaceContainerHigh,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class PreviewSectionTitle extends StatelessWidget {
  const PreviewSectionTitle({
    super.key,
    required this.title,
    this.count,
    this.trailing,
  });

  final String title;
  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Text(title, style: AppTextStyles.titleMd.copyWith(color: c.onSurface)),
        if (count != null) ...[
          const SizedBox(width: 8),
          PreviewBadge(
            label: '$count',
            foreground: c.onSurface,
            background: c.surfaceContainerHigh,
          ),
        ],
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tableau de données
// ─────────────────────────────────────────────────────────────────────────────

class AdminColumn {
  const AdminColumn(
    this.label, {
    this.flex = 1,
    this.width,
    this.align = TextAlign.left,
  });

  final String label;
  final int flex;
  final double? width;
  final TextAlign align;
}

class AdminRow {
  const AdminRow(this.cells, {this.onTap});

  final List<Widget> cells;
  final VoidCallback? onTap;
}

class AdminTable extends StatelessWidget {
  const AdminTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 960,
    this.rowHeight = 64,
    this.headerHeight = 42,
  });

  final List<AdminColumn> columns;
  final List<AdminRow> rows;
  final double minWidth;
  final double rowHeight;
  final double headerHeight;

  Alignment _alignment(TextAlign align) => switch (align) {
        TextAlign.right => Alignment.centerRight,
        TextAlign.center => Alignment.center,
        _ => Alignment.centerLeft,
      };

  Widget _cells(
    BuildContext context,
    List<Widget> cells, {
    required double height,
    required bool header,
  }) {
    final c = context.colors;

    Widget cellFor(int i) => Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Align(
            alignment: _alignment(columns[i].align),
            child: header
                ? Text(
                    columns[i].label,
                    style: AppTextStyles.labelCaps.copyWith(
                      color: c.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  )
                : cells[i],
          ),
        );

    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++)
            if (columns[i].width != null)
              SizedBox(width: columns[i].width, child: cellFor(i))
            else
              Expanded(flex: columns[i].flex, child: cellFor(i)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(constraints.maxWidth, minWidth);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                Container(
                  color: c.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _cells(context, const [], height: headerHeight, header: true),
                ),
                for (final row in rows)
                  _HoverRow(
                    onTap: row.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _cells(context, row.cells, height: rowHeight, header: false),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HoverRow extends StatefulWidget {
  const _HoverRow({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: Material(
        color: _hover ? c.surfaceContainerLow.withValues(alpha: 0.65) : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          hoverColor: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: c.outlineVariant.withValues(alpha: 0.6)),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Case à cocher décorative mais animée (sélection multiple factice).
class PreviewCheckbox extends StatefulWidget {
  const PreviewCheckbox({super.key, this.initiallyChecked = false});

  final bool initiallyChecked;

  @override
  State<PreviewCheckbox> createState() => _PreviewCheckboxState();
}

class _PreviewCheckboxState extends State<PreviewCheckbox> {
  late bool _checked = widget.initiallyChecked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => setState(() => _checked = !_checked),
      borderRadius: BorderRadius.circular(5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 17,
        height: 17,
        decoration: BoxDecoration(
          color: _checked ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: _checked ? c.primary : c.outline.withValues(alpha: 0.7),
            width: 1.3,
          ),
        ),
        child: _checked
            ? Icon(Icons.check_rounded, size: 12, color: c.onPrimary)
            : null,
      ),
    );
  }
}

class PreviewPagination extends StatelessWidget {
  const PreviewPagination({
    super.key,
    required this.label,
    required this.page,
    required this.pages,
  });

  final String label;
  final int page;
  final int pages;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget button(IconData icon, {bool enabled = true}) => Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: c.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.outlineVariant),
          ),
          child: Icon(
            icon,
            size: 15,
            color: enabled ? c.onSurface : c.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        );

    return Row(
      children: [
        Text(label, style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
        const Spacer(),
        Text(
          'Page $page sur $pages',
          style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant),
        ),
        button(Icons.chevron_left_rounded, enabled: page > 1),
        button(Icons.chevron_right_rounded, enabled: page < pages),
      ],
    );
  }
}

class PreviewInfoBanner extends StatelessWidget {
  const PreviewInfoBanner({
    super.key,
    required this.icon,
    required this.text,
    this.accent,
  });

  final IconData icon;
  final String text;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = accent ?? c.goldInk;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Graphique de revenus (CustomPainter — aucune dépendance de charting)
// ─────────────────────────────────────────────────────────────────────────────

class PreviewRevenueChart extends StatelessWidget {
  const PreviewRevenueChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 190,
  });

  final List<int> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _RevenuePainter(
              values: values,
              lineColor: c.goldInk,
              fillColor: c.tertiary,
              gridColor: c.outlineVariant,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final label in labels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelXs.copyWith(
                    color: c.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RevenuePainter extends CustomPainter {
  const _RevenuePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<int> values;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const topInset = 8.0;
    final chartHeight = size.height - topInset;
    final minValue = values.reduce(math.min).toDouble();
    final maxValue = values.reduce(math.max).toDouble();
    final range = math.max(maxValue - minValue, 1);

    // Grille horizontale discrète.
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = topInset + chartHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          size.width * (i / (values.length - 1)),
          topInset + chartHeight * (1 - (values[i] - minValue) / range),
        ),
    ];

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final middleX = (previous.dx + current.dx) / 2;
      line.cubicTo(middleX, previous.dy, middleX, current.dy, current.dx, current.dy);
    }

    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fillColor.withValues(alpha: 0.30),
            fillColor.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Point final mis en avant.
    final last = points.last;
    canvas.drawCircle(last, 7, Paint()..color = fillColor.withValues(alpha: 0.25));
    canvas.drawCircle(last, 3.5, Paint()..color = lineColor);
    canvas.drawCircle(last, 1.6, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _RevenuePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.gridColor != gridColor;
}
