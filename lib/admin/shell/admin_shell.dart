import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../data/admin_demo_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/shared/change_password_dialog.dart';
import '../../screens/shared/system_notifications_screen.dart';
import '../../services/support_message_service.dart';
import '../pages/admin_companies_page.dart';
import '../pages/admin_dashboard_page.dart';
import '../pages/admin_messages_page.dart';
import '../pages/admin_platform_page.dart';
import '../pages/admin_profile_page.dart';
import '../pages/admin_stylists_page.dart';
import '../pages/admin_subscriptions_page.dart';
import '../widgets/admin_dialogs.dart';

/// Coquille desktop de la console admin.
///
/// Un seul endroit décide de la navigation et du chrome ; chaque page reste
/// responsable de ses données et de ses actions. La sidebar se réduit en rail
/// d'icônes puis en drawer selon la largeur, comme validé dans la maquette.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();

  int _index = 0;
  String _stylistQuery = '';

  static const destinations = <AdminDestination>[
    AdminDestination('Tableau de bord', Icons.grid_view_rounded, 'PILOTAGE'),
    AdminDestination('Stylistes', Icons.storefront_rounded, 'PILOTAGE'),
    AdminDestination('Abonnements', Icons.workspace_premium_rounded, 'PILOTAGE'),
    AdminDestination('Entreprises', Icons.apartment_rounded, 'PILOTAGE'),
    AdminDestination('Messages', Icons.forum_rounded, 'SUPPORT'),
    AdminDestination('Mon compte', Icons.person_outline_rounded, 'SYSTÈME'),
    AdminDestination('Plateforme', Icons.monitor_heart_rounded, 'SYSTÈME'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() => _index = index);
  }

  void _submitSearch(String value) {
    setState(() {
      _stylistQuery = value.trim();
      _index = 1;
    });
  }

  Future<void> _handleAccountAction(String action) async {
    switch (action) {
      case 'profile':
        _select(5);
        return;
      case 'password':
        await ChangePasswordDialog.show(context);
        return;
      case 'logout':
        final confirmed = await adminConfirm(
          context,
          title: 'Se déconnecter ?',
          message:
              'Vous devrez saisir vos identifiants administrateur pour revenir sur la console.',
          confirmLabel: 'Se déconnecter',
          danger: true,
        );
        if (!confirmed || !mounted) return;
        await context.read<AuthProvider>().signOut();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showSidebar = width >= 880;
        final expanded = width >= 1240;

        final pages = <Widget>[
          AdminDashboardPage(onNavigate: _select),
          AdminStylistsPage(initialQuery: _stylistQuery),
          const AdminSubscriptionsPage(),
          const AdminCompaniesPage(),
          const AdminMessagesPage(),
          const AdminProfilePage(),
          AdminPlatformPage(onNavigate: _select),
        ];

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
                      searchController: _searchController,
                      onSearch: _submitSearch,
                      onMenu: showSidebar
                          ? null
                          : () => _scaffoldKey.currentState?.openDrawer(),
                      onAccountAction: _handleAccountAction,
                    ),
                    Expanded(
                      child: IndexedStack(index: _index, children: pages),
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

class AdminDestination {
  const AdminDestination(this.label, this.icon, this.section);

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
            _SidebarBrand(
              expanded: expanded,
              foreground: foreground,
              accent: accent,
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  AdminDemoData.revision,
                  SupportMessageService.instance,
                ]),
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                  children: _buildNavigation(
                    foreground: foreground,
                    muted: muted,
                    activeBackground: activeBackground,
                    accent: accent,
                  ),
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
    required Color foreground,
    required Color muted,
    required Color activeBackground,
    required Color accent,
  }) {
    final children = <Widget>[];
    String? currentSection;

    for (var i = 0; i < _AdminShellState.destinations.length; i++) {
      final destination = _AdminShellState.destinations[i];

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
                  _navBadge(i, muted: muted, accent: accent),
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

  Widget _navBadge(int index, {required Color muted, required Color accent}) {
    final count = switch (index) {
      2 => AdminDemoData.pendingRequests,
      4 => SupportMessageService.instance.unreadCount,
      _ => 0,
    };
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: index == 2 ? accent.withValues(alpha: 0.22) : muted.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.labelXs.copyWith(
          color: index == 2 ? accent : muted,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({
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
    final user = context.watch<AuthProvider>().user;

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
                    user?.initials ?? 'AD',
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
                          user?.fullName ?? 'Administrateur',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSm.copyWith(
                            fontSize: 12.5,
                            color: foreground,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
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
                      onTap: () => context.read<AuthProvider>().signOut(),
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
  const AdminTopbar({
    super.key,
    required this.title,
    required this.searchController,
    required this.onSearch,
    required this.onAccountAction,
    this.onMenu,
  });

  final String title;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onAccountAction;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = context.watch<AuthProvider>().user;

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
                SizedBox(
                  width: width >= 1320 ? 320 : 240,
                  child: _TopbarSearch(
                    controller: searchController,
                    onSubmitted: onSearch,
                  ),
                ),
              if (width >= 900) const SizedBox(width: 10),
              AnimatedBuilder(
                animation: Listenable.merge([
                  AdminDemoData.revision,
                  SupportMessageService.instance,
                ]),
                builder: (context, _) => _TopbarIcon(
                  icon: Icons.notifications_none_rounded,
                  badge: SupportMessageService.instance.unreadCount > 0,
                  tooltip: 'Notifications',
                  onTap: () => SystemNotificationsScreen.show(context),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                tooltip: 'Compte',
                offset: const Offset(0, 46),
                onSelected: onAccountAction,
                color: c.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: c.outlineVariant),
                ),
                itemBuilder: (context) => [
                  _accountItem(context, 'profile', Icons.person_outline_rounded, 'Mon compte'),
                  _accountItem(context, 'password', Icons.lock_outline_rounded, 'Changer le mot de passe'),
                  const PopupMenuDivider(),
                  _accountItem(context, 'logout', Icons.logout_rounded, 'Se déconnecter', danger: true),
                ],
                child: Row(
                  children: [
                    AdminTopbarAvatar(initials: user?.initials ?? 'AD'),
                    if (width >= 1080) ...[
                      const SizedBox(width: 9),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Administrateur',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSm.copyWith(
                              fontSize: 12.5,
                              color: c.onSurface,
                            ),
                          ),
                          Text(
                            user?.role.label ?? 'Administrateur',
                            style: AppTextStyles.labelXs.copyWith(
                              color: c.onSurfaceVariant,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
              const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: c.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PopupMenuItem<String> _accountItem(
    BuildContext context,
    String value,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    final c = context.colors;
    return PopupMenuItem<String>(
      value: value,
      height: 42,
      child: Row(
        children: [
          Icon(icon, size: 16, color: danger ? c.statusProblem : c.onSurface),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 12.5,
              color: danger ? c.statusProblem : c.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminTopbarAvatar extends StatelessWidget {
  const AdminTopbarAvatar({super.key, required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: c.surfaceContainerHigh,
        shape: BoxShape.circle,
        border: Border.all(color: c.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.labelCaps.copyWith(
          color: c.onSurface,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _TopbarSearch extends StatelessWidget {
  const _TopbarSearch({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
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
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.bodySm.copyWith(color: c.onSurface),
              cursorColor: c.onSurface,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Rechercher un styliste, un atelier…',
                hintStyle: AppTextStyles.bodySm.copyWith(
                  color: c.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopbarIcon extends StatelessWidget {
  const _TopbarIcon({
    required this.icon,
    this.onTap,
    this.badge = false,
    this.tooltip,
  });

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
