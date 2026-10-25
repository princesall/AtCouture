import 'package:flutter/material.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../shared/system_notifications_screen.dart';
import 'admin_dashboard.dart';
import 'admin_messages_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_stylists_screen.dart';
import 'admin_subscriptions_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  void _onNavTap(int i) => setState(() => _index = i);

  static const _navItems = [
    NavItem(icon: PhosphorIconsRegular.squaresFour,      label: 'Accueil'),
    NavItem(icon: PhosphorIconsRegular.storefront,       label: 'Stylistes'),
    NavItem(icon: PhosphorIconsRegular.crown,            label: 'Abonnements'),
    NavItem(icon: PhosphorIconsRegular.chatCircleDots,   label: 'Messages'),
    NavItem(icon: PhosphorIconsRegular.user,             label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(children: [
          // ── AppBar ────────────────────────────────────────────────────
          Column(children: [
            StitchAppBar(
              title: 'StyleConnect',
              onNotificationTap: () => SystemNotificationsScreen.show(context),
            ),
            const OfflineBanner(),
            // ── Contenu ─────────────────────────────────────────────────
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  AdminDashboard(onNavTap: _onNavTap, onDataChanged: () => setState(() {})),
                  // Pas de `const` : lit AdminDemoData/CompanyService directement dans build().
                  AdminStylistsScreen(),
                  AdminSubscriptionsScreen(),
                  AdminMessagesScreen(),
                  AdminProfileScreen(),
                ],
              ),
            ),
          ]),

          // ── GlassNavBar flottante ─────────────────────────────────────
          GlassNavBar(
            items: _navItems,
            currentIndex: _index,
            onTap: _onNavTap,
          ),
        ]),
      ),
    );
  }
}
