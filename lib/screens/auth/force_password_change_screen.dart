import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/premium_button.dart';
import '../../core/widgets/premium_text_field.dart';
import '../../providers/auth_provider.dart';

/// Étape obligatoire pour tout compte créé avec un mot de passe temporaire
/// (Couturier créé par un styliste, ou Chef d'atelier créé par un Chef
/// d'Entreprise — voir CompanyService.createTailor / createAtelierHead) :
/// tant que AppUser.mustChangePassword est true, AppRouter.redirect renvoie
/// systématiquement ici, quel que soit l'écran visé. Une fois le nouveau mot
/// de passe validé, le router laisse automatiquement passer vers l'espace
/// normal du rôle.
class ForcePasswordChangeScreen extends StatefulWidget {
  const ForcePasswordChangeScreen({super.key});

  @override
  State<ForcePasswordChangeScreen> createState() => _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState extends State<ForcePasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tempPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _tempPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      currentPassword: _tempPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    if (!success && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: context.colors.error),
      );
    }
    // Succès : mustChangePassword passe à false côté AuthProvider, le
    // router redirige automatiquement vers l'espace du rôle.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final c = context.colors;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.primaryContainer,
                          ),
                          child: Icon(Icons.lock_reset_rounded, color: c.onPrimaryContainer, size: 30),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Sécurisez votre compte',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMd.copyWith(color: c.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Votre compte a été créé avec un mot de passe temporaire. '
                        'Définissez votre propre mot de passe pour continuer.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PremiumTextField(
                        controller: _tempPasswordController,
                        label: 'Mot de passe temporaire',
                        hint: 'Reçu de votre atelier',
                        prefixIcon: Icons.vpn_key_outlined,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        autofocus: true,
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),
                      const SizedBox(height: AppSpacing.md),
                      PremiumTextField(
                        controller: _newPasswordController,
                        label: 'Nouveau mot de passe',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) => v == null || v.length < 6 ? 'Minimum 6 caractères' : null,
                      ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.06, end: 0),
                      const SizedBox(height: AppSpacing.md),
                      PremiumTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirmer le nouveau mot de passe',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (v) =>
                            v != _newPasswordController.text ? 'Les mots de passe ne correspondent pas' : null,
                      ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.06, end: 0),
                      const SizedBox(height: AppSpacing.xl),
                      PremiumButton(
                        label: 'Valider et continuer',
                        variant: PremiumButtonVariant.gold,
                        isLoading: auth.isChangingPassword,
                        onPressed: auth.isChangingPassword ? null : _submit,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: TextButton(
                          onPressed: auth.isChangingPassword ? null : () => auth.signOut(),
                          child: Text(
                            'Se déconnecter',
                            style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
