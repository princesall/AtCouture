import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../providers/theme_provider.dart';
import 'pages/dashboard_page.dart';
import 'pages/messages_page.dart';
import 'pages/stylists_page.dart';
import 'pages/subscriptions_page.dart';
import 'widgets/preview_kit.dart';

/// Coquille de la console admin web :
/// sidebar ébène (260 px) → rail icônes (84 px) → drawer sur petit écran.
class AdminPreviewShell extends StatefulWidget {
  const AdminPreviewShell({super.key});

  @override
  State<AdminPreviewShell> createState() => _AdminPreviewShellState();
}

class _AdminPreviewShellState extends State<AdminPreviewShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Permet d'ouvrir directement un écran pour la revue de design :
    //   http://localhost:PORT/?page=1  → Stylistes
    //   http://localhost:PORT/?page=2  → Abonnements
    //   http://localhost:PORT/?page=3  → Messages
    final requested = int.tryParse(Uri.base.queryParameters['page'] ?? '');
    if (requested != null &&
        requested >= 0 &&
        requested < destinations.length) {
      _index = requested;
    }
  }

  static const destinations = <PreviewDestination>[
    PreviewDestination('Tableau de bord', Icons.grid_view_rounded, 'PILOTAGE'),
    PreviewDestination('Stylistes', Icons.storefront_rounded, 'PILOTAGE'),
    PreviewDestination('Abonnements', Icons.workspace_premium_rounded, 'PILOTAGE'),
    PreviewDestination('Messages', Icons.forum_rounded, 'SUPPORT'),
    PreviewDestination('Notifications', Icons.notifications_rounded, 'SUPPORT'),
    PreviewDestination('Journal d\'activité', Icons.history_rounded, 'SYSTÈME'),
    PreviewDestination('Paramètres', Icons.settings_rounded, 'SYSTÈME'),
  ];

  static const _pages = <Widget>[
    DashboardPage(),
    StylistsPage(),
    SubscriptionsPage(),
    MessagesPage(),
    _ComingSoonPage(
      title: 'Notifications',
      description:
          'Diffusion d\'annonces aux stylistes, rappels d\'expiration et messages système. '
          'Cet écran reprend l\'onglet mobile actuel, en version desktop.',
      icon: Icons.notifications_active_rounded,
    ),
    _ComingSoonPage(
      title: 'Journal d\'activité',
      description:
          'Traçabilité des décisions admin : approbations, suspensions, changements de plan. '
          'Nouveau sur web — impossible à porter proprement sur mobile.',
      icon: Icons.receipt_long_rounded,
    ),
    _ComingSoonPage(
      title: 'Paramètres',
      description:
          'Gestion des administrateurs, sécurité (MFA), App Check et paramètres de la plateforme.',
      icon: Icons.tune_rounded,
    ),
  ];

  void _select(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showSidebar = width >= 880;
        final expanded = width >= 1240;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: c.background,
          drawer: showSidebar
              ? null
              : Drawer(
                  width: 280,
                  backgroundColor: Colors.transparent,
                  child: AdminSidebar(
                    expanded: true,
                    selected: _index,
                    onSelect: (index) {
                      Navigator.of(context).pop();
                      _select(index);
                    },
                  ),
                ),
          body: Row(
            children: [
              if (showSidebar)
                AdminSidebar(
                  expanded: expanded,
                  selected: _index,
                  onSelect: _select,
                ),
              Expanded(
                child: Column(
                  children: [
                    AdminTopbar(
                      title: destinations[_index].label,
                      onMenu: showSidebar
                          ? null
                          : () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    Expanded(
                      child: IndexedStack(index: _index, children: _pages),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PreviewDestination {
  const PreviewDestination(this.label, this.icon, this.section);

  final String label;
  final IconData icon;
  final String section;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────────────────────

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.expanded,
    required this.selected,
    required this.onSelect,
  });

  final bool expanded;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? c.surfaceContainerLow : const Color(0xFF121212);
    final foreground = isDark ? c.onSurface : const Color(0xFFF7F7F5);
    final muted = foreground.withValues(alpha: 0.52);
    final activeBackground =
        isDark ? c.surfaceContainerHigh : Colors.white.withValues(alpha: 0.07);
    final accent = c.tertiary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: expanded ? 260 : 84,
      decoration: BoxDecoration(
        color: background,
        border: Border(
          right: BorderSide(color: foreground.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Brand(expanded: expanded, foreground: foreground, accent: accent),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 6, bottom: 12),
                children: _buildNavigation(
                  context: context,
                  foreground: foreground,
                  muted: muted,
                  activeBackground: activeBackground,
                  accent: accent,
                ),
              ),
            ),
            _SidebarFooter(
              expanded: expanded,
              foreground: foreground,
              muted: muted,
              accent: accent,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNavigation({
    required BuildContext context,
    required Color foreground,
    required Color muted,
    required Color activeBackground,
    required Color accent,
  }) {
    final children = <Widget>[];
    String? currentSection;

    for (var i = 0; i < _AdminPreviewShellState.destinations.length; i++) {
      final destination = _AdminPreviewShellState.destinations[i];

      if (destination.section != currentSection) {
        currentSection = destination.section;
        if (expanded) {
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 20, 6),
              child: Text(
                destination.section,
                style: AppTextStyles.labelXs.copyWith(
                  color: muted.withValues(alpha: 0.75),
                  fontSize: 9,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          );
        } else if (i != 0) {
          children.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: Divider(
                height: 1,
                color: foreground.withValues(alpha: 0.08),
              ),
            ),
          );
        }
      }

      final active = i == selected;
      final item = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelect(i),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 42,
            margin: EdgeInsets.symmetric(horizontal: expanded ? 12 : 10, vertical: 2),
            padding: EdgeInsets.symmetric(horizontal: expanded ? 10 : 0),
            decoration: BoxDecoration(
              color: active ? activeBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment:
                  expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                if (active)
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                if (active) const SizedBox(width: 9),
                Icon(
                  destination.icon,
                  size: 19,
                  color: active ? accent : muted,
                ),
                if (expanded) ...[
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSm.copyWith(
                        fontSize: 13.5,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color: active ? foreground : muted,
                      ),
                    ),
                  ),
                  if (i == 3) _CountPill(count: 3, muted: muted),
                ],
              ],
            ),
          ),
        ),
      );

      children.add(
        expanded ? item : Tooltip(message: destination.label, child: item),
      );
    }

    return children;
  }
}

class _Brand extends StatelessWidget {
  const _Brand({
    required this.expanded,
    required this.foreground,
    required this.accent,
  });

  final bool expanded;
  final Color foreground;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(expanded ? 22 : 0, 24, expanded ? 18 : 0, 20),
      child: Row(
        mainAxisAlignment:
            expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accent.withValues(alpha: 0.65)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'S',
              style: AppTextStyles.headlineSm.copyWith(
                fontSize: 15,
                height: 1,
                color: const Color(0xFF121212),
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STYLECONNECT',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineSm.copyWith(
                      fontSize: 14,
                      letterSpacing: 1.4,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'CONSOLE ADMIN',
                    style: AppTextStyles.labelXs.copyWith(
                      color: accent,
                      fontSize: 8,
                      letterSpacing: 2.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count, required this.muted});

  final int count;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.labelXs.copyWith(color: muted, fontSize: 9),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.expanded,
    required this.foreground,
    required this.muted,
    required this.accent,
  });

  final bool expanded;
  final Color foreground;
  final Color muted;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final toggle = InkWell(
      onTap: () => context.read<ThemeProvider>().toggle(),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: foreground.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment:
              expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 16,
              color: muted,
            ),
            if (expanded) ...[
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Mode sombre',
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 12,
                    color: muted,
                  ),
                ),
              ),
              Switch.adaptive(
                value: isDark,
                onChanged: (_) => context.read<ThemeProvider>().toggle(),
                activeThumbColor: accent,
                activeTrackColor: accent.withValues(alpha: 0.35),
                inactiveThumbColor: muted,
                inactiveTrackColor: foreground.withValues(alpha: 0.12),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(expanded ? 14 : 10, 10, expanded ? 14 : 10, 16),
      child: Column(
        children: [
          toggle,
          const SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(expanded ? 10 : 6),
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: foreground.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment:
                  expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.45)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'AS',
                    style: AppTextStyles.labelCaps.copyWith(
                      color: accent,
                      fontSize: 10,
                    ),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Abdoulaye Sall',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSm.copyWith(
                            fontSize: 12.5,
                            color: foreground,
                          ),
                        ),
                        Text(
                          'Super administrateur',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelXs.copyWith(
                            color: muted,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Se déconnecter',
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Topbar
// ─────────────────────────────────────────────────────────────────────────────

class AdminTopbar extends StatelessWidget {
  const AdminTopbar({super.key, required this.title, this.onMenu});

  final String title;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: c.background,
        border: Border(
          bottom: BorderSide(color: c.outlineVariant.withValues(alpha: 0.7)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Row(
            children: [
              if (onMenu != null) ...[
                _TopbarIcon(icon: Icons.menu_rounded, onTap: onMenu),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (width >= 640)
                      Text(
                        'Console',
                        style: AppTextStyles.bodySm.copyWith(
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    if (width >= 640) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: c.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSm.copyWith(
                          fontSize: 14,
                          color: c.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (width >= 900)
                PreviewSearchField(
                  hint: 'Rechercher un styliste, un atelier…',
                  width: width >= 1320 ? 320 : 240,
                ),
              if (width >= 900) const SizedBox(width: 10),
              if (width >= 1120) ...[
                _PeriodPill(label: '30 derniers jours'),
                const SizedBox(width: 10),
              ],
              _TopbarIcon(
                icon: Icons.notifications_none_rounded,
                badge: true,
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 12),
              const PreviewAvatar(initials: 'AS', size: 34),
              if (width >= 1080) ...[
                const SizedBox(width: 9),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Abdoulaye Sall',
                      style: AppTextStyles.titleSm.copyWith(
                        fontSize: 12.5,
                        color: c.onSurface,
                      ),
                    ),
                    Text(
                      'Super administrateur',
                      style: AppTextStyles.labelXs.copyWith(
                        color: c.onSurfaceVariant,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TopbarIcon extends StatelessWidget {
  const _TopbarIcon({required this.icon, this.onTap, this.badge = false, this.tooltip});

  final IconData icon;
  final VoidCallback? onTap;
  final bool badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final button = Material(
      color: c.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.outlineVariant.withValues(alpha: 0.9)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 18, color: c.onSurfaceVariant),
              if (badge)
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: c.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.surfaceContainerLowest,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: c.onSurfaceVariant),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 12,
              color: c.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: c.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Écran d'attente pour les destinations non maquettées
// ─────────────────────────────────────────────────────────────────────────────

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PreviewPageBody(
      children: [
        PreviewPageHeader(
          title: title,
          subtitle: 'Structure de navigation validée — contenu à porter ensuite.',
        ),
        const SizedBox(height: 24),
        PreviewPanel(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 56),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: c.tertiaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 26, color: c.onTertiaryContainer),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: AppTextStyles.headlineMd.copyWith(color: c.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySm.copyWith(
                        color: c.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
