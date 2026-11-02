import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../providers/auth_provider.dart';

/// Écran affiché sur mobile quand un compte administrateur se connecte.
///
/// Depuis la séparation des espaces, l'administration vit exclusivement sur
/// la console web : l'app mobile ne contient plus aucun écran admin. On
/// explique la situation et on propose d'ouvrir la console dans le navigateur.
class AdminWebOnlyScreen extends StatelessWidget {
  const AdminWebOnlyScreen({super.key});

  Future<void> _openConsole(BuildContext context) async {
    final uri = Uri.parse(AppConstants.adminConsoleUrl);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir la console. Rendez-vous sur ${AppConstants.adminConsoleUrl}'),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir la console. Rendez-vous sur ${AppConstants.adminConsoleUrl}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: c.goldGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 30,
                      color: c.onTertiary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Espace administrateur sur le web',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineLgMobile.copyWith(
                      color: c.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'L\'administration de StyleConnect est désormais séparée de '
                    'l\'application mobile. Votre console vous attend dans le navigateur, '
                    'avec les tableaux, les filtres et les outils de pilotage.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySm.copyWith(
                      color: c.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.outlineVariant),
                      boxShadow: c.softShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: c.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            user?.initials ?? 'AD',
                            style: AppTextStyles.titleSm.copyWith(
                              color: c.onSurface,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Administrateur',
                                style: AppTextStyles.titleSm.copyWith(
                                  fontSize: 14,
                                  color: c.onSurface,
                                ),
                              ),
                              Text(
                                user?.email ?? '',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: c.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.verified_user_rounded,
                          size: 18,
                          color: c.goldInk,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => _openConsole(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        'OUVRIR LA CONSOLE ADMIN',
                        style: AppTextStyles.labelCaps.copyWith(
                          color: c.onPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.read<AuthProvider>().signOut(),
                    child: Text(
                      'Se déconnecter',
                      style: AppTextStyles.bodySm.copyWith(
                        color: c.onSurfaceVariant,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: c.onSurfaceVariant,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'L\'application mobile reste dédiée aux stylistes, chefs d\'atelier, '
                            'chefs d\'entreprise et couturiers. Aucune donnée d\'administration '
                            'n\'y est plus accessible.',
                            style: AppTextStyles.bodySm.copyWith(
                              fontSize: 11.5,
                              height: 1.5,
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
