import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../providers/auth_provider.dart';
import 'tailor_dashboard.dart';

class TailorShell extends StatefulWidget {
  const TailorShell({super.key});

  @override
  State<TailorShell> createState() => _TailorShellState();
}

class _TailorShellState extends State<TailorShell> {
  int _index = 0;

  void _onNavTap(int i) => setState(() => _index = i);

  static const _navItems = [
    NavItem(icon: Icons.checklist_rounded,       label: 'Tâches'),
    NavItem(icon: Icons.straighten_rounded,      label: 'Mesures'),
    NavItem(icon: Icons.photo_library_outlined,  label: 'Photos'),
    NavItem(icon: Icons.person_rounded,          label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Contenu de l'onglet actif ────────────────────────────────────
          IndexedStack(
            index: _index,
            children: [
              TailorDashboard(onNavTap: _onNavTap),
              _PlaceholderTab(
                title: 'Mesures',
                subtitle: 'Consultez les mesures de vos clients',
                icon: Icons.straighten_outlined,
              ),
              _PlaceholderTab(
                title: 'Photos',
                subtitle: 'Galerie des modèles et avancement',
                icon: Icons.photo_library_outlined,
              ),
              _TailorProfile(),
            ],
          ),

          // ── GlassNavBar flottante ────────────────────────────────────────
          GlassNavBar(
            items: _navItems,
            currentIndex: _index,
            onTap: _onNavTap,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onglet placeholder
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
