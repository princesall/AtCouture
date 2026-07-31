import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

/// Gestionnaire dédié — plan Entreprise uniquement (permissions.hasDedicatedManager).
/// En démo, l'admin de la plateforme joue ce rôle ; quand Firebase sera
/// branché, ce sera un vrai compte assigné par companyId dans Firestore.
class CompanyDedicatedManagerScreen extends StatelessWidget {
  const CompanyDedicatedManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestionnaire dédié'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Container(
                    width: 56, height: 56,
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.support_agent_rounded, color: AppColors.onTertiary, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Votre gestionnaire dédié', style: AppTextStyles.titleSm.copyWith(color: AppColors.onTertiary)),
                      const SizedBox(height: 4),
                      Text('Assigné à ${user.atelierName ?? 'votre entreprise'}',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.onTertiary.withValues(alpha: 0.85))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              _ContactTile(
                icon: Icons.support_agent_rounded,
                title: 'Support StyleConnect',
                subtitle: 'Gestionnaire de compte StyleConnect Entreprise',
              ),
              _ContactTile(
                icon: Icons.phone_rounded,
                title: '+223 93 16 04 00',
                subtitle: 'Disponible du lundi au vendredi, 8h–18h',
                onTap: () => launchUrl(Uri.parse('tel:+22393160400')),
              ),
              // E-mail de contact pas encore défini — tuile ajoutée une fois
              // l'adresse réelle communiquée.
              const SizedBox(height: AppSpacing.md),
              Text(
                'Votre gestionnaire dédié vous accompagne pour la mise en place de vos ateliers, '
                'la formation de vos équipes et le suivi de votre abonnement Entreprise.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

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
        title: Text(title, style: AppTextStyles.bodyLg),
        subtitle: Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        onTap: onTap,
        trailing: onTap == null ? null : const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
