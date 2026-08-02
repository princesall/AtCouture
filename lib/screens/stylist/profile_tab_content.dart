import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/plan_guard.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../company/company_customization_screen.dart';
import '../company/company_data_export_screen.dart';
import '../company/company_dedicated_manager_screen.dart';
import '../shared/calendar_screen.dart';
import '../shared/contact_support_screen.dart';
import '../shared/reminders_screen.dart';
import '../shared/subscription_dialog.dart';

/// Onglet Profil réutilisable — utilisé dans StylistShell ET CompanyShell.
/// Affiche dynamiquement les infos adaptées au rôle (Atelier vs Entreprise).
class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final auth = context.read<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final c = context.colors;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 120),
        child: Column(children: [
          const SizedBox(height: AppSpacing.lg),
          UserAvatar(initials: user.initials, size: 80, dark: user.isCompanyOwner, imageUrl: user.photoUrl),
          const SizedBox(height: AppSpacing.md),
          Text(user.fullName, style: AppTextStyles.headlineLgMobile),
          const SizedBox(height: AppSpacing.xxs),
          Text(user.email, style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          PlanBadge(planName: user.plan.name),
          const SizedBox(height: AppSpacing.xl),
          _ProfileTile(
            icon: user.isCompanyOwner ? Icons.apartment_rounded : Icons.storefront_outlined,
            title: user.isCompanyOwner ? 'Entreprise' : 'Atelier',
            subtitle: user.atelierName ?? '—',
          ),
          _ProfileTile(icon: Icons.phone_outlined, title: 'Téléphone', subtitle: user.phone),
          _ProfileTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Abonnement',
            subtitle: '${user.plan.priceLabel} — Voir les offres',
            onTap: () => SubscriptionDialog.show(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Fonctionnalités', style: AppTextStyles.labelCaps.copyWith(color: c.onSurfaceVariant)),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileMenuTile(
            icon: Icons.calendar_month_rounded,
            title: 'Calendrier des livraisons',
            isAllowed: user.permissions.hasCalendar,
            lockedMessage: user.permissions.calendarLockedMessage,
            onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
          ),
          _ProfileMenuTile(
            icon: Icons.notifications_active_outlined,
            title: 'Rappels automatiques',
            isAllowed: user.permissions.hasReminders,
            lockedMessage: user.permissions.remindersLockedMessage,
            onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen())),
          ),
          if (user.isCompanyOwner) ...[
            _ProfileMenuTile(
              icon: Icons.upload_file_rounded,
              title: 'Export de données',
              isAllowed: user.permissions.hasApiExport,
              lockedMessage: user.permissions.apiExportLockedMessage,
              onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyDataExportScreen())),
            ),
            _ProfileMenuTile(
              icon: Icons.support_agent_rounded,
              title: 'Gestionnaire dédié',
              isAllowed: user.permissions.hasDedicatedManager,
              lockedMessage: user.permissions.dedicatedManagerLockedMessage,
              onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyDedicatedManagerScreen())),
            ),
            _ProfileMenuTile(
              icon: Icons.palette_outlined,
              title: 'Personnalisation',
              isAllowed: user.permissions.hasCustomization,
              lockedMessage: user.permissions.customizationLockedMessage,
              onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyCustomizationScreen())),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: c.outlineVariant),
            ),
            child: SwitchListTile(
              secondary: Icon(theme.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: c.secondary),
              title: Text(theme.isDarkMode ? 'Mode sombre' : 'Mode clair', style: AppTextStyles.labelCaps.copyWith(color: c.onSurface)),
              value: theme.isDarkMode,
              onChanged: (_) => theme.toggle(),
              activeTrackColor: c.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: Icon(Icons.support_agent_outlined, color: c.secondary),
            title: Text('Signaler un problème', style: AppTextStyles.labelCaps.copyWith(color: c.onSurface)),
            onTap: () => ContactSupportScreen.show(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), side: BorderSide(color: c.outlineVariant)),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: Icon(Icons.logout, color: c.error),
            title: Text('Déconnexion', style: AppTextStyles.labelCaps.copyWith(color: c.error)),
            onTap: () => auth.signOut(),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), side: BorderSide(color: c.outlineVariant)),
          ),
        ]),
      ),
    );
  }
}

/// Tuile de menu pour une fonctionnalité conditionnée au plan. Si non
/// autorisée, affiche un cadenas et ouvre le dialog d'upsell au lieu de
/// naviguer (voir PlanGuard — même pattern que le reste de l'app).
class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.isAllowed,
    required this.lockedMessage,
    required this.onOpen,
  });

  final IconData icon;
  final String title;
  final bool isAllowed;
  final String lockedMessage;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: c.softShadow,
      ),
      child: ListTile(
        leading: Icon(icon, color: isAllowed ? c.secondary : c.onSurfaceVariant, size: 22),
        title: Text(title, style: AppTextStyles.bodyLg),
        trailing: isAllowed
            ? Icon(Icons.chevron_right, color: c.onSurfaceVariant)
            : const PlanLockBadge(),
        onTap: () {
          if (PlanGuard.requireFeature(
            context: context,
            isAllowed: isAllowed,
            featureName: title,
            lockedMessage: lockedMessage,
          )) {
            onOpen();
          }
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon; final String title; final String subtitle; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: c.softShadow,
      ),
      child: ListTile(
        leading: Icon(icon, color: c.secondary, size: 22),
        title: Text(title, style: AppTextStyles.labelCaps),
        subtitle: Text(subtitle, style: AppTextStyles.bodyLg),
        trailing: onTap != null ? Icon(Icons.chevron_right, color: c.onSurfaceVariant) : null,
        onTap: onTap,
      ),
    );
  }
}
