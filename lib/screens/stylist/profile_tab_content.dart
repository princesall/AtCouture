import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/plan_guard.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/platform_config_service.dart';
import '../company/company_customization_screen.dart';
import '../company/company_data_export_screen.dart';
import '../company/company_dedicated_manager_screen.dart';
import '../shared/calendar_screen.dart';
import '../shared/change_password_dialog.dart';
import '../shared/contact_support_screen.dart';
import '../shared/reminders_screen.dart';
import '../shared/subscription_dialog.dart';
import 'edit_profile_dialog.dart';

/// Ouvre la fiche de modification du compte et confirme l'enregistrement.
Future<void> _openEditProfile(BuildContext context, AppUser user) async {
  final saved = await EditProfileDialog.show(context, user);
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Informations mises à jour'),
        backgroundColor: context.colors.success,
      ),
    );
  }
}

/// Onglet Profil réutilisable — utilisé dans StylistShell ET CompanyShell.
/// Affiche dynamiquement les infos adaptées au rôle (Atelier vs Entreprise).
class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final auth = context.read<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final platformConfig = context.watch<PlatformConfigService>();
    final c = context.colors;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          120,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            _EditableProfileLogo(user: user),
            const SizedBox(height: AppSpacing.md),
            Text(user.fullName, style: AppTextStyles.headlineLgMobile),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              user.email,
              style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            PlanBadge(planName: user.plan.name),
            const SizedBox(height: AppSpacing.xl),
            _ProfileTile(
              icon: user.isCompanyOwner
                  ? Icons.apartment_rounded
                  : Icons.storefront_outlined,
              title: user.isCompanyOwner ? 'Entreprise' : 'Atelier',
              subtitle: user.atelierName ?? '—',
              onTap: () => _openEditProfile(context, user),
            ),
            _ProfileTile(
              icon: Icons.phone_outlined,
              title: 'Téléphone',
              subtitle: user.phone,
              onTap: () => _openEditProfile(context, user),
            ),
            _ProfileTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Abonnement',
              subtitle: '${user.plan.priceLabel} — Voir les offres',
              onTap: () => SubscriptionDialog.show(context),
            ),
            _ProfileTile(
              icon: Icons.edit_outlined,
              title: 'Mes informations',
              subtitle: 'Nom, téléphone, atelier, adresse',
              onTap: () => _openEditProfile(context, user),
            ),
            _ProfileTile(
              icon: Icons.lock_outline_rounded,
              title: 'Mot de passe',
              subtitle: 'Modifier votre mot de passe',
              onTap: () => ChangePasswordDialog.show(context),
            ),
            const SizedBox(height: AppSpacing.xl),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Fonctionnalités',
                style: AppTextStyles.labelCaps.copyWith(
                  color: c.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileMenuTile(
              icon: Icons.calendar_month_rounded,
              title: 'Calendrier des livraisons',
              isAllowed: user.permissions.hasCalendar,
              lockedMessage: user.permissions.calendarLockedMessage,
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              ),
            ),
            _ProfileMenuTile(
              icon: Icons.notifications_active_outlined,
              title: 'Rappels automatiques',
              isAllowed: user.permissions.hasReminders,
              lockedMessage: user.permissions.remindersLockedMessage,
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              ),
            ),
            if (user.isCompanyOwner) ...[
              _ProfileMenuTile(
                icon: Icons.upload_file_rounded,
                title: 'Export de données',
                isAllowed: user.permissions.hasApiExport,
                lockedMessage: user.permissions.apiExportLockedMessage,
                onOpen: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompanyDataExportScreen(),
                  ),
                ),
              ),
              _ProfileMenuTile(
                icon: Icons.support_agent_rounded,
                title: 'Gestionnaire dédié',
                isAllowed: user.permissions.hasDedicatedManager,
                lockedMessage: user.permissions.dedicatedManagerLockedMessage,
                onOpen: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompanyDedicatedManagerScreen(),
                  ),
                ),
              ),
              _ProfileMenuTile(
                icon: Icons.palette_outlined,
                title: 'Personnalisation',
                isAllowed: user.permissions.hasCustomization,
                lockedMessage: user.permissions.customizationLockedMessage,
                onOpen: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompanyCustomizationScreen(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: c.outlineVariant),
              ),
              child: SwitchListTile(
                secondary: Icon(
                  theme.isDarkMode
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  color: c.secondary,
                ),
                title: Text(
                  theme.isDarkMode ? 'Mode sombre' : 'Mode clair',
                  style: AppTextStyles.labelCaps.copyWith(color: c.onSurface),
                ),
                value: theme.isDarkMode,
                onChanged: (_) => theme.toggle(),
                activeTrackColor: c.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
            if (platformConfig.isEnabled('supportMessaging')) ...[
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                leading: Icon(Icons.support_agent_outlined, color: c.secondary),
                title: Text(
                  'Signaler un problème',
                  style: AppTextStyles.labelCaps.copyWith(color: c.onSurface),
                ),
                onTap: () => ContactSupportScreen.show(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  side: BorderSide(color: c.outlineVariant),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Icon(Icons.logout, color: c.error),
              title: Text(
                'Déconnexion',
                style: AppTextStyles.labelCaps.copyWith(color: c.error),
              ),
              onTap: () => auth.signOut(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                side: BorderSide(color: c.outlineVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar du profil, cliquable pour ajouter / remplacer / supprimer le logo
/// de l'atelier après la création du compte. Le choix d'image était
/// auparavant limité à l'inscription : une fois le compte créé, il n'existait
/// aucun moyen de corriger ou d'ajouter un logo.
class _EditableProfileLogo extends StatefulWidget {
  const _EditableProfileLogo({required this.user});

  final AppUser user;

  @override
  State<_EditableProfileLogo> createState() => _EditableProfileLogoState();
}

class _EditableProfileLogoState extends State<_EditableProfileLogo> {
  bool _isBusy = false;

  bool get _hasLogo =>
      widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty;

  String get _entityLabel =>
      widget.user.isCompanyOwner ? "l'entreprise" : "l'atelier";

  Future<void> _openLogoActions() async {
    if (_isBusy) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text('Logo de $_entityLabel', style: AppTextStyles.titleSm),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                _hasLogo ? 'Choisir une nouvelle image' : 'Choisir une image',
              ),
              subtitle: const Text('Depuis la galerie de votre appareil'),
              onTap: () => Navigator.pop(sheetContext, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
            if (_hasLogo)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: context.read<ThemeProvider>().colors.error,
                ),
                title: Text(
                  'Supprimer le logo',
                  style: TextStyle(
                    color: context.read<ThemeProvider>().colors.error,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    if (action == 'remove') {
      await _applyLogo(null);
      return;
    }

    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
        // 512 px suffisent pour un logo affiché en 80–120 px, et gardent le
        // fichier à quelques dizaines de Ko — indispensable quand il est
        // stocké en base64 dans users.photoUrl (voir ProfileLogoService).
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'ouvrir la galerie ou l'appareil photo."),
        ),
      );
      return;
    }
    if (picked == null) return;
    await _applyLogo(picked);
  }

  Future<void> _applyLogo(XFile? file) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.updateLogo(file);
    if (!mounted) return;
    setState(() => _isBusy = false);

    final colors = context.read<ThemeProvider>().colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (file == null ? 'Logo supprimé.' : 'Logo mis à jour.')
              : (auth.errorMessage ?? 'Impossible de mettre à jour le logo.'),
        ),
        backgroundColor: success ? colors.primary : colors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        GestureDetector(
          onTap: _openLogoActions,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                initials: widget.user.initials,
                size: 88,
                dark: widget.user.isCompanyOwner,
                imageUrl: widget.user.photoUrl,
              ),
              if (_isBusy)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(88 * 0.32),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: c.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.background, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton.icon(
          onPressed: _isBusy ? null : _openLogoActions,
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: Text(_hasLogo ? 'Modifier le logo' : 'Ajouter le logo'),
        ),
      ],
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
        leading: Icon(
          icon,
          color: isAllowed ? c.secondary : c.onSurfaceVariant,
          size: 22,
        ),
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
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
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
        trailing: onTap != null
            ? Icon(Icons.chevron_right, color: c.onSurfaceVariant)
            : null,
        onTap: onTap,
      ),
    );
  }
}
