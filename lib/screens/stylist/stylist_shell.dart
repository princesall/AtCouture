import 'package:flutter/material.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';
import 'package:provider/provider.dart';

import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/subscription_service.dart';
import '../shared/system_notifications_screen.dart';
import 'profile_tab_content.dart';
import 'stylist_clients_screen.dart';
import 'stylist_dashboard.dart';
import 'stylist_orders_screen.dart';
import 'stylist_tailors_screen.dart';

class StylistShell extends StatefulWidget {
  const StylistShell({super.key});

  @override
  State<StylistShell> createState() => _StylistShellState();
}

class _StylistShellState extends State<StylistShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Récupère les éventuels changements de plan effectués côté admin
    // (approbation, renouvellement) depuis la dernière connexion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().refreshUser();
    });
  }

  void _onNavTap(int i) => setState(() => _index = i);

  static const _navItems = [
    NavItem(icon: PhosphorIconsRegular.squaresFour,   label: 'Accueil'),
    NavItem(icon: PhosphorIconsRegular.users,         label: 'Clients'),
    NavItem(icon: PhosphorIconsRegular.clipboardText, label: 'Commandes'),
    NavItem(icon: PhosphorIconsRegular.scissors,      label: 'Couturiers'),
    NavItem(icon: PhosphorIconsRegular.user,          label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final unread = SubscriptionService.instance.unreadSystemMessagesCount(user.id);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(children: [
              StitchAppBar(
                title: 'StyleConnect',
                onNotificationTap: () => SystemNotificationsScreen.show(context),
              ),
              const OfflineBanner(),
              Expanded(
                child: Stack(children: [
                  // ── Contenu de l'onglet actif ────────────────────────────
                  IndexedStack(
                    index: _index,
                    children: [
                      StylistDashboard(onNavTap: _onNavTap),
                      // Pas de `const` : ces écrans lisent OrderService/
                      // CompanyService (de simples singletons, pas des
                      // ChangeNotifier) directement dans build(). Avec un
                      // widget `const`, Flutter réutilise l'instance et ne
                      // rappelle jamais build() en changeant d'onglet, donc
                      // les données restent figées après le tout premier
                      // affichage (ex: un client ajouté via l'onglet
                      // Commandes n'apparaissait jamais dans l'onglet
                      // Clients). Sans `const`, chaque changement d'onglet
                      // reconstruit l'écran et relit les données à jour.
                      StylistClientsScreen(),
                      StylistOrdersScreen(),
                      StylistTailorsScreen(),
                      ProfileTabContent(),
                    ],
                  ),

                  // ── FAB mesures (onglet Accueil) ─────────────────────────
                  if (_index == 0)
                    Positioned(
                      bottom: 84,
                      right: 20,
                      child: FloatingActionButton(
                        onPressed: () => _onNavTap(2),
                        backgroundColor: c.primary,
                        foregroundColor: c.onPrimary,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Icon(PhosphorIconsRegular.plus, size: 22, color: c.onPrimary),
                      ),
                    ),
                ]),
              ),
            ]),

            // ── GlassNavBar flottante ──────────────────────────────────────
            GlassNavBar(
              items: _navItems,
              currentIndex: _index,
              onTap: _onNavTap,
            ),

            // ── Badge rouge de notifications non lues ───────────────────────
            if (unread > 0)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 56,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

