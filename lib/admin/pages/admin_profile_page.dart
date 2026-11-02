import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/shared/change_password_dialog.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_kit.dart';

/// Compte administrateur : identité, sécurité, préférences et déconnexion.
class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.user;

    if (user == null) {
      return const AdminPageBody(
        children: [
          AdminEmptyState(
            icon: Icons.person_off_outlined,
            title: 'Session introuvable',
            message: 'Reconnectez-vous pour accéder à votre compte.',
          ),
        ],
      );
    }

    return AdminPageBody(
      children: [
        const AdminPageHeader(
          title: 'Mon compte',
          subtitle: 'Identité, sécurité et préférences de la console',
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final identity = _IdentityCard(auth: auth);
            final security = _SecurityPanel(
              darkMode: theme.isDarkMode,
              onToggleTheme: () => context.read<ThemeProvider>().toggle(),
              demoMode: auth.isDemoMode,
            );
            if (!wide) {
              return Column(
                children: [
                  identity,
                  const SizedBox(height: 18),
                  security,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: identity),
                const SizedBox(width: 18),
                Expanded(flex: 3, child: security),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        AdminInfoBanner(
          icon: Icons.shield_outlined,
          text:
              'Cette console est réservée aux administrateurs. Les comptes non-admin sont automatiquement déconnectés.',
          accent: c.secondary,
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.auth});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = auth.user!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: c.heroGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: c.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: c.goldGradient,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  user.initials,
                  style: AppTextStyles.headlineSm.copyWith(
                    fontSize: 22,
                    height: 1,
                    color: c.onTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMd.copyWith(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminBadge(
                label: user.role.label.toUpperCase(),
                foreground: c.onTertiary,
                background: c.tertiary,
              ),
              if (user.createdAt != null)
                AdminBadge(
                  label:
                      'DEPUIS ${Formatters.date.format(user.createdAt!).toUpperCase()}',
                  foreground: Colors.white.withValues(alpha: 0.85),
                  background: Colors.white.withValues(alpha: 0.12),
                ),
              if (auth.isDemoMode)
                AdminBadge(
                  label: 'MODE DÉMO',
                  foreground: Colors.white.withValues(alpha: 0.85),
                  background: Colors.white.withValues(alpha: 0.12),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 15,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user.isActive
                      ? 'Compte actif · accréditation administrateur'
                      : 'Compte suspendu',
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecurityPanel extends StatelessWidget {
  const _SecurityPanel({
    required this.darkMode,
    required this.onToggleTheme,
    required this.demoMode,
  });

  final bool darkMode;
  final VoidCallback onToggleTheme;
  final bool demoMode;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminPanel(
      title: 'Sécurité & préférences',
      subtitle: demoMode
          ? 'Mode démo (debug) — données locales, pas de Firebase'
          : 'Session Firebase active',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            _SettingRow(
              icon: Icons.lock_outline_rounded,
              title: 'Mot de passe',
              subtitle: 'Modifier le mot de passe du compte administrateur',
              trailing: AdminButton(
                label: 'Changer',
                small: true,
                onTap: () => ChangePasswordDialog.show(context),
              ),
            ),
            Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
            _SettingRow(
              icon: darkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              title: 'Apparence',
              subtitle: darkMode ? 'Thème sombre activé' : 'Thème clair activé',
              trailing: Switch.adaptive(
                value: darkMode,
                onChanged: (_) => onToggleTheme(),
                activeThumbColor: c.goldInk,
                activeTrackColor: c.tertiary.withValues(alpha: 0.4),
                inactiveThumbColor: c.onSurfaceVariant,
                inactiveTrackColor: c.surfaceContainerHigh,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
            _SettingRow(
              icon: Icons.devices_other_rounded,
              title: 'Application mobile',
              subtitle:
                  'L\'espace client reste sur mobile. La console admin est exclusivement web.',
              trailing: AdminBadge(
                label: 'WEB',
                foreground: c.onSurfaceVariant,
                background: c.surfaceContainerHigh,
              ),
            ),
            Divider(height: 1, color: c.outlineVariant.withValues(alpha: 0.7)),
            _SettingRow(
              icon: Icons.logout_rounded,
              title: 'Déconnexion',
              subtitle: 'Terminer la session sur ce navigateur',
              trailing: AdminButton(
                label: 'Se déconnecter',
                icon: Icons.logout_rounded,
                small: true,
                danger: true,
                onTap: () async {
                  final confirmed = await adminConfirm(
                    context,
                    title: 'Se déconnecter ?',
                    message:
                        'Vous devrez saisir vos identifiants administrateur pour revenir sur la console.',
                    confirmLabel: 'Se déconnecter',
                    danger: true,
                  );
                  if (!confirmed || !context.mounted) return;
                  await context.read<AuthProvider>().signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: c.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSm.copyWith(
                    fontSize: 13,
                    color: c.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 2,
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 11.5,
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
