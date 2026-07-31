import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/subscription_service.dart';
import '../shared/contact_support_screen.dart';
import '../shared/system_notifications_screen.dart';
import 'tailor_dashboard.dart';
import 'tailor_measurements_screen.dart';
import 'tailor_photos_screen.dart';

class TailorShell extends StatefulWidget {
  const TailorShell({super.key});

  @override
  State<TailorShell> createState() => _TailorShellState();
}

class _TailorShellState extends State<TailorShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().refreshUser();
    });
  }

  void _onNavTap(int i) => setState(() => _index = i);

  static const _navItems = [
    NavItem(icon: Icons.checklist_rounded,       label: 'Tâches'),
    NavItem(icon: Icons.straighten_rounded,      label: 'Mesures'),
    NavItem(icon: Icons.photo_library_outlined,  label: 'Photos'),
    NavItem(icon: Icons.person_rounded,          label: 'Profil'),
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
                      TailorDashboard(onNavTap: _onNavTap),
                      // Pas de `const` : lit OrderService directement dans build().
                      TailorMeasurementsScreen(),
                      TailorPhotosScreen(),
                      _TailorProfile(),
                    ],
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
// Onglet Profil Couturier
// ─────────────────────────────────────────────────────────────────────────────
class _TailorProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final auth = context.read<AuthProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 120,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            UserAvatar(initials: user.initials, size: 80),
            const SizedBox(height: AppSpacing.md),
            Text(user.fullName, style: AppTextStyles.headlineLgMobile),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              user.atelierName ?? '',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                boxShadow: AppColors.softShadow,
              ),
              child: ListTile(
                leading: Icon(Icons.storefront_outlined, color: AppColors.secondary, size: 22),
                title: Text('Atelier', style: AppTextStyles.labelCaps),
                subtitle: Text(user.atelierName ?? '—', style: AppTextStyles.bodyLg),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                boxShadow: AppColors.softShadow,
              ),
              child: ListTile(
                leading: Icon(Icons.phone_outlined, color: AppColors.secondary, size: 22),
                title: Text('Téléphone', style: AppTextStyles.labelCaps),
                subtitle: Text(user.phone, style: AppTextStyles.bodyLg),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                boxShadow: AppColors.softShadow,
              ),
              child: ListTile(
                leading: Icon(Icons.mail_outline, color: AppColors.secondary, size: 22),
                title: Text('Email', style: AppTextStyles.labelCaps),
                subtitle: Text(user.email, style: AppTextStyles.bodyLg),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined, color: AppColors.secondary),
              title: Text(
                'Signaler un problème',
                style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurface),
              ),
              onTap: () => ContactSupportScreen.show(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                side: const BorderSide(color: AppColors.outlineVariant),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                'Déconnexion',
                style: AppTextStyles.labelCaps.copyWith(color: AppColors.error),
              ),
              onTap: () => auth.signOut(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                side: const BorderSide(color: AppColors.outlineVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
