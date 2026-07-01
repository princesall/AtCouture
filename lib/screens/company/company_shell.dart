import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/subscription_service.dart';
import '../shared/system_notifications_screen.dart';
import '../stylist/profile_tab_content.dart';
import 'company_ateliers_screen.dart';
import 'company_clients_screen.dart';
import 'company_dashboard.dart';
import 'company_orders_screen.dart';
import 'company_tailors_screen.dart';

/// Shell de l'espace Chef d'Entreprise (plan Entreprise, role==companyOwner).
/// 5 onglets : Accueil (vue consolidée), Ateliers, Couturiers (global),
/// Commandes (global), Profil.
///
/// SÉCURITÉ : cet écran n'est utile (et accessible via le router) que pour
/// role==companyOwner, MAIS on revérifie ici le plan EFFECTIF (via
/// `user.permissions`, qui tient compte de l'expiration de l'abonnement).
/// Si l'abonnement Entreprise a expiré sans être renouvelé, ce compte est
/// AUTOMATIQUEMENT rétrogradé aux droits du plan Gratuit — sans perdre la
/// moindre donnée (ses ateliers, couturiers, clients, commandes restent
/// intacts en base) — jusqu'au renouvellement, qui restaure immédiatement
/// l'accès complet.
class CompanyShell extends StatefulWidget {
  const CompanyShell({super.key});
  @override
  State<CompanyShell> createState() => _CompanyShellState();
}

class _CompanyShellState extends State<CompanyShell> {
  int _index = 0;
  void _onNavTap(int i) => setState(() => _index = i);

  static const _navItems = [
    NavItem(icon: Icons.dashboard_rounded,        label: 'Accueil'),
    NavItem(icon: Icons.storefront_rounded,       label: 'Ateliers'),
    NavItem(icon: Icons.people_alt_rounded,       label: 'Clients'),
    NavItem(icon: Icons.content_cut_rounded,      label: 'Couturiers'),
    NavItem(icon: Icons.receipt_long_rounded,     label: 'Commandes'),
    NavItem(icon: Icons.person_rounded,           label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final permissions = user.permissions;
    final unread = SubscriptionService.instance.unreadSystemMessagesCount(user.id);

    // ── Garde-fou : plan EFFECTIF (expiration prise en compte) ───────────
    // Le plan attribué par l'admin (user.plan) est l'unique source de vérité,
    // mais s'il a expiré sans renouvellement, permissions.canManageMultipleAteliers
    // redevient automatiquement false — l'utilisateur retombe sur le plan
    // Gratuit tant qu'il n'a pas renouvelé, sans perte de données.
    if (!permissions.canManageMultipleAteliers) {
      return _PlanMismatchScreen(
        currentPlan: user.plan.name,
        isExpired: permissions.isExpired,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(children: [
          Column(children: [
            StitchAppBar(
              title: 'StyleConnect',
              onNotificationTap: () => SystemNotificationsScreen.show(context),
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  CompanyDashboard(onNavTap: _onNavTap),
                  const CompanyAteliersScreen(),
                  const CompanyClientsScreen(),
                  const CompanyTailorsScreen(),
                  const CompanyOrdersScreen(),
                  const ProfileTabContent(),
                ],
              ),
            ),
          ]),
          GlassNavBar(items: _navItems, currentIndex: _index, onTap: _onNavTap),
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
        ]),
      ),
    );
  }
}

/// Écran affiché quand le plan EFFECTIF (expiration comprise) ne permet plus
/// la gestion multi-ateliers. Distingue clairement le cas "abonnement expiré,
/// en attente de renouvellement" du cas "jamais eu ce plan" pour rassurer
/// l'utilisateur que ses données sont toujours là.
class _PlanMismatchScreen extends StatelessWidget {
  const _PlanMismatchScreen({required this.currentPlan, required this.isExpired});
  final String currentPlan;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                child: Icon(isExpired ? Icons.hourglass_bottom_rounded : Icons.lock_rounded, color: AppColors.onTertiary, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                isExpired ? 'Abonnement Entreprise expiré' : 'Accès non autorisé',
                style: AppTextStyles.titleMd.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isExpired
                    ? 'Votre abonnement Entreprise a expiré. Vos ateliers, couturiers, clients et commandes sont conservés intacts, mais la gestion multi-ateliers est temporairement verrouillée.\n\nRenouvelez votre abonnement auprès de l\'administrateur pour retrouver immédiatement l\'accès complet.'
                    : 'La gestion multi-ateliers est réservée au plan Entreprise.\nVotre plan actuel : $currentPlan\n\nContactez l\'administrateur pour mettre à niveau votre abonnement.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.read<AuthProvider>().signOut(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: Text('SE DÉCONNECTER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.onPrimary)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
