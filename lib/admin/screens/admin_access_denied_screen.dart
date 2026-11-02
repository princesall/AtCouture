import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../providers/auth_provider.dart';
import '../widgets/admin_kit.dart';

/// Affiché lorsqu'une session restaurée appartient à un compte non-admin.
/// La console ne doit jamais laisser passer un styliste, même connecté.
class AdminAccessDeniedScreen extends StatelessWidget {
  const AdminAccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: c.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.outlineVariant),
              boxShadow: c.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: c.statusProblemBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.gpp_bad_outlined,
                    size: 26,
                    color: c.statusProblem,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Accès refusé',
                  style: AppTextStyles.headlineMd.copyWith(
                    fontSize: 22,
                    color: c.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Le compte ${auth.user?.email ?? ''} n\'a pas les droits administrateur. '
                  'Utilisez l\'application mobile StyleConnect pour votre espace, ou contactez un administrateur.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm.copyWith(
                    color: c.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: AdminButton(
                    label: 'Se déconnecter',
                    icon: Icons.logout_rounded,
                    danger: true,
                    onTap: () => context.read<AuthProvider>().signOut(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
