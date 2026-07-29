import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/admin_demo_data.dart';
import '../../providers/auth_provider.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final auth = context.read<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(children: [
        // ── Avatar + nom ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                boxShadow: [BoxShadow(color: AppColors.tertiary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Center(child: Text(
                user.initials,
                style: AppTextStyles.headlineLg.copyWith(color: AppColors.onTertiary, fontSize: 28),
              )),
            ),
            const SizedBox(height: 14),
            Text(user.fullName, style: AppTextStyles.headlineLgMobile.copyWith(color: Colors.white)),
            const SizedBox(height: 4),
            Text(user.email, style: AppTextStyles.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.65))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.admin_panel_settings_rounded, color: AppColors.tertiaryFixedDim, size: 14),
                const SizedBox(width: 6),
                Text('ADMINISTRATEUR', style: AppTextStyles.labelXs.copyWith(color: AppColors.tertiaryFixedDim, letterSpacing: 1.2)),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 28),

        // ── Infos ─────────────────────────────────────────────────────────
        _SectionLabel('Informations personnelles'),
        const SizedBox(height: 12),
        _InfoTile(icon: Icons.phone_outlined, label: 'Téléphone', value: user.phone),
        const SizedBox(height: 10),
        _InfoTile(icon: Icons.mail_outline_rounded, label: 'Email', value: user.email),

        const SizedBox(height: 28),
        _SectionLabel('Statistiques globales'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatMiniCard(label: 'Stylistes', value: AdminDemoData.totalStylists.toString(), icon: Icons.storefront_rounded, color: AppColors.secondary)),
          const SizedBox(width: 12),
          Expanded(child: _StatMiniCard(label: 'Couturiers', value: AdminDemoData.totalTailors.toString(), icon: Icons.content_cut_rounded, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _StatMiniCard(label: 'Commandes', value: AdminDemoData.activeOrders.toString(), icon: Icons.receipt_long_rounded, color: AppColors.surfaceTint)),
        ]),

        const SizedBox(height: 28),
        _SectionLabel('Paramètres'),
        const SizedBox(height: 12),
        _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
        const SizedBox(height: 10),
        _SettingsTile(icon: Icons.lock_outline_rounded, label: 'Changer le mot de passe', onTap: () {}),
        const SizedBox(height: 10),
        _SettingsTile(icon: Icons.language_rounded, label: 'Langue : Français', onTap: () {}),
        const SizedBox(height: 10),
        _SettingsTile(icon: Icons.help_outline_rounded, label: 'Aide & Support', onTap: () {}),

        const SizedBox(height: 28),
        // ── Déconnexion ───────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
            label: Text('SE DÉCONNECTER', style: AppTextStyles.labelCaps.copyWith(color: AppColors.error, letterSpacing: 1.2)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Text('StyleConnect v1.0.0 — Bamako, Mali', style: AppTextStyles.labelXs.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5))),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(label.toUpperCase(), style: AppTextStyles.labelCaps.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1.2)),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)), boxShadow: AppColors.softShadow),
    child: Row(children: [
      Icon(icon, color: AppColors.secondary, size: 20),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.labelCaps),
        Text(value, style: AppTextStyles.bodyLg),
      ]),
    ]),
  );
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({required this.label, required this.value, required this.icon, required this.color});
  final String label; final String value; final IconData icon; final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.1))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 8),
      Text(value, style: AppTextStyles.statNumber.copyWith(color: color, fontSize: 22)),
      Text(label, style: AppTextStyles.labelXs.copyWith(color: color.withValues(alpha: 0.7))),
    ]),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)), boxShadow: AppColors.softShadow),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: AppTextStyles.bodyLg)),
        const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant, size: 20),
      ]),
    ),
  );
}
