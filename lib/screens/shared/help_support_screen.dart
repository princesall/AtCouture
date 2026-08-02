import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';

/// Aide & Support — FAQ statique + contact direct. Accessible depuis les
/// écrans de profil (pour l'instant : admin).
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
  }

  static const _faq = [
    (
      'Comment fonctionne le mode démo ?',
      'Tant qu\'aucun serveur n\'est configuré, StyleConnect fonctionne entièrement en local sur cet appareil : rien n\'est synchronisé ni sauvegardé ailleurs. Les données sont perdues si vous désinstallez l\'application.',
    ),
    (
      'Comment approuver ou refuser un abonnement ?',
      'Depuis l\'onglet Abonnements, ouvrez la demande d\'un styliste ou d\'une entreprise et utilisez les boutons Approuver / Refuser. La personne concernée reçoit automatiquement une notification système.',
    ),
    (
      'Comment suspendre un compte ?',
      'Depuis la fiche d\'un styliste, d\'une entreprise ou d\'un couturier, utilisez l\'option de suspension. Le compte suspendu ne peut plus se connecter tant qu\'il n\'est pas réactivé.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Aide & Support', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('QUESTIONS FRÉQUENTES', style: AppTextStyles.labelCaps.copyWith(color: c.onSurfaceVariant, letterSpacing: 1.2)),
          const SizedBox(height: AppSpacing.sm),
          ..._faq.map((item) => _FaqTile(question: item.$1, answer: item.$2)),

          const SizedBox(height: AppSpacing.xl),
          Text('NOUS CONTACTER', style: AppTextStyles.labelCaps.copyWith(color: c.onSurfaceVariant, letterSpacing: 1.2)),
          const SizedBox(height: AppSpacing.sm),
          _ContactTile(
            icon: Icons.phone_rounded,
            title: '+223 93 16 04 00',
            subtitle: 'Disponible du lundi au vendredi, 8h–18h',
            onTap: () => launchUrl(Uri.parse('tel:+22393160400')),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(question, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600)),
          iconColor: c.primary,
          collapsedIconColor: c.onSurfaceVariant,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(answer, style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
          ],
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
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: c.softShadow,
      ),
      child: ListTile(
        leading: Icon(icon, color: c.secondary, size: 22),
        title: Text(title, style: AppTextStyles.bodyLg),
        subtitle: Text(subtitle, style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant)),
        onTap: onTap,
        trailing: onTap == null ? null : Icon(Icons.chevron_right, color: c.onSurfaceVariant),
      ),
    );
  }
}
