import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../data/admin_demo_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../shared/change_password_dialog.dart';
import '../shared/help_support_screen.dart';
import '../shared/system_notifications_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final auth = context.read<AuthProvider>();
    final c = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(children: [
        // ── Avatar + nom ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: c.heroGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: c.goldGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                boxShadow: [BoxShadow(color: c.tertiary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Center(child: Text(
                user.initials,
                style: AppTextStyles.headlineLg.copyWith(color: c.onTertiary, fontSize: 28),
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
                Icon(Icons.admin_panel_settings_rounded, color: c.tertiaryFixedDim, size: 14),
                const SizedBox(width: 6),
                Text('ADMINISTRATEUR', style: AppTextStyles.labelXs.copyWith(color: c.tertiaryFixedDim, letterSpacing: 1.2)),
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
          Expanded(child: _StatMiniCard(label: 'Stylistes', value: AdminDemoData.totalStylists.toString(), icon: Icons.storefront_rounded, color: c.secondary)),
          const SizedBox(width: 12),
          Expanded(child: _StatMiniCard(label: 'Couturiers', value: AdminDemoData.totalTailors.toString(), icon: Icons.content_cut_rounded, color: c.primary)),
          const SizedBox(width: 12),
          Expanded(child: _StatMiniCard(label: 'Commandes', value: AdminDemoData.activeOrders.toString(), icon: Icons.receipt_long_rounded, color: c.surfaceTint)),
        ]),

        const SizedBox(height: 28),
        _SectionLabel('Paramètres'),
        const SizedBox(height: 12),
        const _ThemeToggleTile(),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () => SystemNotificationsScreen.show(context),
        ),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.lock_outline_rounded,
          label: 'Changer le mot de passe',
          onTap: () => ChangePasswordDialog.show(context),
        ),
        const SizedBox(height: 10),
        _SettingsTile(
          icon: Icons.help_outline_rounded,
          label: 'Aide & Support',
          onTap: () => HelpSupportScreen.show(context),
        ),

        const SizedBox(height: 28),
        // ── Déconnexion ───────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => auth.signOut(),
            icon: Icon(Icons.logout_rounded, size: 18, color: c.error),
            label: Text('SE DÉCONNECTER', style: AppTextStyles.labelCaps.copyWith(color: c.error, letterSpacing: 1.2)),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.error,
              side: BorderSide(color: c.error.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Text('StyleConnect v1.0.0 — Bamako, Mali', style: AppTextStyles.labelXs.copyWith(color: c.onSurfaceVariant.withValues(alpha: 0.5))),
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
    child: Text(label.toUpperCase(), style: AppTextStyles.labelCaps.copyWith(color: context.colors.onSurfaceVariant, letterSpacing: 1.2)),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surfaceContainerLowest, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.outlineVariant.withValues(alpha: 0.3)), boxShadow: c.softShadow),
      child: Row(children: [
        Icon(icon, color: c.secondary, size: 20),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.labelCaps.copyWith(color: c.onSurface)),
          Text(value, style: AppTextStyles.bodyLg.copyWith(color: c.onSurface)),
        ]),
      ]),
    );
  }
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

class _ThemeToggleTile extends StatelessWidget {
  const _ThemeToggleTile();
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: c.surfaceContainerLowest, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.outlineVariant.withValues(alpha: 0.3)), boxShadow: c.softShadow),
      child: Row(children: [
        Icon(theme.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: c.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(theme.isDarkMode ? 'Mode sombre' : 'Mode clair', style: AppTextStyles.bodyLg.copyWith(color: c.onSurface))),
        Switch(value: theme.isDarkMode, onChanged: (_) => theme.toggle(), activeTrackColor: c.primary),
      ]),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: c.surfaceContainerLowest, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.outlineVariant.withValues(alpha: 0.3)), boxShadow: c.softShadow),
        child: Row(children: [
          Icon(icon, color: c.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTextStyles.bodyLg.copyWith(color: c.onSurface))),
          Icon(Icons.chevron_right_rounded, color: c.onSurfaceVariant, size: 20),
        ]),
      ),
    );
  }
}
