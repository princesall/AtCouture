import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';

/// Onglet Profil réutilisable — utilisé dans StylistShell ET CompanyShell.
/// Affiche dynamiquement les infos adaptées au rôle (Atelier vs Entreprise).
class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final auth = context.read<AuthProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 120),
        child: Column(children: [
          const SizedBox(height: AppSpacing.lg),
          UserAvatar(initials: user.initials, size: 80, dark: user.isCompanyOwner),
          const SizedBox(height: AppSpacing.md),
          Text(user.fullName, style: AppTextStyles.headlineLgMobile),
          const SizedBox(height: AppSpacing.xxs),
          Text(user.email, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          PlanBadge(planName: user.plan.name),
          const SizedBox(height: AppSpacing.xl),
          _ProfileTile(
            icon: user.isCompanyOwner ? Icons.apartment_rounded : Icons.storefront_outlined,
            title: user.isCompanyOwner ? 'Entreprise' : 'Atelier',
            subtitle: user.atelierName ?? '—',
          ),
          _ProfileTile(icon: Icons.phone_outlined, title: 'Téléphone', subtitle: user.phone),
          _ProfileTile(icon: Icons.workspace_premium_outlined, title: 'Abonnement', subtitle: user.plan.priceLabel),
          const SizedBox(height: AppSpacing.xl),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text('Déconnexion', style: AppTextStyles.labelCaps.copyWith(color: AppColors.error)),
            onTap: () => auth.signOut(),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), side: const BorderSide(color: AppColors.outlineVariant)),
          ),
        ]),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon; final String title; final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: AppColors.softShadow,
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.secondary, size: 22),
        title: Text(title, style: AppTextStyles.labelCaps),
        subtitle: Text(subtitle, style: AppTextStyles.bodyLg),
      ),
    );
  }
}
