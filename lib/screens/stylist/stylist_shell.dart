import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/subscription_service.dart';
import '../shared/system_notifications_screen.dart';
import 'profile_tab_content.dart';
import 'stylist_dashboard.dart';

class StylistShell extends StatefulWidget {
  const StylistShell({super.key});

  @override
  State<StylistShell> createState() => _StylistShellState();
}

class _StylistShellState extends State<StylistShell> {
  int _index = 0;

  void _onNavTap(int i) => setState(() => _index = i);

  static const _navItems = [
    NavItem(icon: Icons.dashboard_rounded,     label: 'Accueil'),
    NavItem(icon: Icons.people_alt_rounded,    label: 'Clients'),
    NavItem(icon: Icons.receipt_long_rounded,  label: 'Commandes'),
    NavItem(icon: Icons.content_cut_rounded,   label: 'Couturiers'),
    NavItem(icon: Icons.person_rounded,        label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final unread = SubscriptionService.instance.unreadSystemMessagesCount(user.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(children: [
              StitchAppBar(
                title: 'StyleConnect',
                onNotificationTap: () => SystemNotificationsScreen.show(context),
              ),
              Expanded(
                child: Stack(children: [
                  // ── Contenu de l'onglet actif ────────────────────────────
                  IndexedStack(
                    index: _index,
                    children: [
                      StylistDashboard(onNavTap: _onNavTap),
                      _PlaceholderTab(
                        title: 'Clients',
                        subtitle: 'Gérez vos fiches clients et mesures',
                        icon: Icons.people_outline,
                      ),
                      _PlaceholderTab(
                        title: 'Commandes',
                        subtitle: 'Créez et suivez vos commandes',
                        icon: Icons.receipt_long_outlined,
                      ),
                      _PlaceholderTab(
                        title: 'Couturiers',
                        subtitle: 'Gérez votre équipe de couture',
                        icon: Icons.content_cut_outlined,
                      ),
                      const ProfileTabContent(),
                    ],
                  ),

                  // ── FAB Nouvelle commande (onglet Commandes) ─────────────
                  if (_index == 2)
                    Positioned(
                      bottom: 92,
                      right: 20,
                      child: FloatingActionButton.extended(
                        onPressed: () {},
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.onSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        icon: const Icon(Icons.add),
                        label: Text('Commande', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSecondary)),
                      ),
                    ),

                  // ── FAB mesures (onglet Accueil) ─────────────────────────
                  if (_index == 0)
                    Positioned(
                      bottom: 92,
                      right: 20,
                      child: FloatingActionButton(
                        onPressed: () => _onNavTap(2),
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.onSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.add),
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
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
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

// ─────────────────────────────────────────────────────────────────────────────
// Onglet placeholder (Clients, Commandes, Couturiers)
// ─────────────────────────────────────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: EmptyState(
        title: title,
        subtitle: '$subtitle\n\nBientôt disponible',
        icon: icon,
      ),
    );
  }
}


