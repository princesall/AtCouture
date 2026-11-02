import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../models/subscription_plan.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Kit de la console admin web (production).
//
// Promu depuis la maquette validée, mais sans aucune donnée factice : ces
// composants ne reçoivent que des valeurs réelles fournies par les pages.
// Tous les tokens viennent de la palette existante (`context.colors`), donc
// le mode clair/sombre de l'app est respecté sans duplication de couleurs.
// ─────────────────────────────────────────────────────────────────────────────

/// Zone de contenu scrollable, centrée et bornée.
class AdminPageBody extends StatelessWidget {
  const AdminPageBody({super.key, required this.children});

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

/// En-tête de page : titre éditorial, sous-titre, actions à droite.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
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

/// Panneau bordé — brique de base des tableaux et cartes.
class AdminPanel extends StatelessWidget {
  const AdminPanel({
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

/// Carte KPI. `hero` réserve le dégradé sombre au KPI principal (revenus).
class AdminKpiCard extends StatelessWidget {
  const AdminKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.delta,
    this.deltaUp = true,
    this.hint,
    this.highlight = false,
    this.hero = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? delta;
  final bool deltaUp;
  final String? hint;
  final bool highlight;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final foreground = hero ? Colors.white : c.onSurface;
    final muted = hero
        ? Colors.white.withValues(alpha: 0.68)
        : c.onSurfaceVariant;
    final labelColor = hero
        ? Colors.white.withValues(alpha: 0.72)
        : (highlight ? c.onTertiaryContainer : c.onSurfaceVariant);

    return Container(
      height: 150,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: hero ? c.heroGradient : null,
        color: hero
            ? null
            : (highlight ? c.tertiaryContainer : c.surfaceContainerLowest),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hero
              ? Colors.transparent
              : (highlight
                  ? c.tertiary.withValues(alpha: 0.6)
                  : c.outlineVariant.withValues(alpha: 0.75)),
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
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: accent),
              ),
              const Spacer(),
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hero
                        ? Colors.white.withValues(alpha: 0.12)
                        : (deltaUp ? c.statusDoneBg : c.statusProblemBg),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        deltaUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: hero
                            ? c.tertiary
                            : (deltaUp ? c.statusDone : c.statusProblem),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        delta!,
                        style: AppTextStyles.labelXs.copyWith(
                          color: hero
                              ? c.tertiary
                              : (deltaUp ? c.statusDone : c.statusProblem),
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
              color: foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelCaps.copyWith(
              color: labelColor,
              letterSpacing: 1,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pastille générique.
class AdminBadge extends StatelessWidget {
  const AdminBadge({
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelXs.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de plan. Un chef d'atelier rattaché à une entreprise n'est pas un
/// abonné distinct : on affiche « CHEF D'ATELIER » au lieu du plan Entreprise
/// hérité, sinon l'admin croit à deux abonnements (même règle que l'ancien
/// écran mobile).
class AdminPlanBadge extends StatelessWidget {
  const AdminPlanBadge({
    super.key,
    required this.plan,
    this.isCompanyStaff = false,
  });

  final SubscriptionPlan plan;
  final bool isCompanyStaff;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (isCompanyStaff) {
      return AdminBadge(
        label: 'CHEF D\'ATELIER',
        foreground: c.onSurfaceVariant,
        background: c.surfaceContainerHigh,
      );
    }
    final (fg, bg) = switch (plan) {
      SubscriptionPlan.free => (c.onSurfaceVariant, c.surfaceContainerHigh),
      SubscriptionPlan.starter => (c.statusInProgress, c.statusInProgressBg),
      SubscriptionPlan.pro => (c.onSecondaryContainer, c.secondaryContainer),
      SubscriptionPlan.enterprise => (c.onTertiaryContainer, c.tertiaryContainer),
    };
    return AdminBadge(label: plan.name.toUpperCase(), foreground: fg, background: bg);
  }
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({
    super.key,
    required this.isActive,
    this.expiringSoon = false,
  });

  final bool isActive;
  final bool expiringSoon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (!isActive) {
      return AdminBadge(
        label: 'Suspendu',
        foreground: c.statusProblem,
        background: c.statusProblemBg,
        dot: true,
      );
    }
    if (expiringSoon) {
      return AdminBadge(
        label: 'Expire bientôt',
        foreground: c.statusInProgress,
        background: c.statusInProgressBg,
        dot: true,
      );
    }
    return AdminBadge(
      label: 'Actif',
      foreground: c.statusDone,
      background: c.statusDoneBg,
      dot: true,
    );
  }
}

/// Avatar à initiales, avec point de présence optionnel.
class AdminAvatar extends StatelessWidget {
  const AdminAvatar({
    super.key,
    required this.initials,
    this.size = 36,
    this.online = false,
  });

  factory AdminAvatar.fromName(
    String name, {
    bool online = false,
    double size = 36,
  }) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'
        : (name.isNotEmpty ? name[0] : '?');
    return AdminAvatar(
      initials: initials.toUpperCase(),
      online: online,
      size: size,
    );
  }

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

/// Bouton maison — paddings desktop, sans dépendre des thèmes tactiles.
class AdminButton extends StatelessWidget {
  const AdminButton({
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

/// Action compacte icône seule — utilisée dans les colonnes de tableau trop
/// étroites pour un bouton libellé (demandes, renouvellements).
class AdminIconAction extends StatelessWidget {
  const AdminIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.background,
    this.onTap,
    this.size = 30,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final Color background;
  final VoidCallback? onTap;
  final double size;

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
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.53, color: color),
          ),
        ),
      ),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.hint,
    this.width,
    this.controller,
    this.onChanged,
    this.onSubmitted,
  });

  final String hint;
  final double? width;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

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
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
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

class AdminFilterChips extends StatelessWidget {
  const AdminFilterChips({
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

class AdminProgressBar extends StatelessWidget {
  const AdminProgressBar({
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

class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle({
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
          AdminBadge(
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
    this.rowHeight = 60,
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

class AdminPagination extends StatelessWidget {
  const AdminPagination({
    super.key,
    required this.label,
    required this.page,
    required this.pages,
    this.onPrevious,
    this.onNext,
  });

  final String label;
  final int page;
  final int pages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget button(IconData icon, {VoidCallback? onTap}) => Material(
          color: c.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.outlineVariant),
              ),
              child: Icon(
                icon,
                size: 15,
                color: onTap == null
                    ? c.onSurfaceVariant.withValues(alpha: 0.4)
                    : c.onSurface,
              ),
            ),
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
        button(Icons.chevron_left_rounded, onTap: onPrevious),
        button(Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class AdminInfoBanner extends StatelessWidget {
  const AdminInfoBanner({
    super.key,
    required this.icon,
    required this.text,
    this.accent,
    this.action,
  });

  final IconData icon;
  final String text;
  final Color? accent;
  final Widget? action;

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
          if (action != null) ...[const SizedBox(width: 10), action!],
        ],
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
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
              child: Icon(icon, size: 22, color: c.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSm.copyWith(color: c.onSurface),
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}
