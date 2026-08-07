import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/premium_button.dart';
import '../../core/widgets/premium_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

/// Dialogue générique de changement de mot de passe, utilisable depuis
/// n'importe quel écran de profil (admin, styliste, entreprise, couturier).
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour')),
      );
    } else if (auth.errorMessage != null) {
      // Voir login_screen.dart : context.colors (context.watch<ThemeProvider>())
      // ne doit jamais être appelé hors du cycle de build — ce dialogue est
      // utilisé par TOUS les rôles (admin/styliste/entreprise/couturier).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: context.read<ThemeProvider>().colors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final c = context.colors;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Changer le mot de passe', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
              const SizedBox(height: AppSpacing.lg),
              PremiumTextField(
                controller: _currentPasswordController,
                label: 'Mot de passe actuel',
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumTextField(
                controller: _newPasswordController,
                label: 'Nouveau mot de passe',
                obscureText: true,
                validator: (v) => v == null || v.length < 6 ? 'Minimum 6 caractères' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumTextField(
                controller: _confirmPasswordController,
                label: 'Confirmer le nouveau mot de passe',
                obscureText: true,
                validator: (v) => v != _newPasswordController.text ? 'Les mots de passe ne correspondent pas' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: auth.isChangingPassword ? null : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PremiumButton(
                      label: 'Valider',
                      isLoading: auth.isChangingPassword,
                      onPressed: auth.isChangingPassword ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
