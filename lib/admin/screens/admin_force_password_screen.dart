import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../providers/auth_provider.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/admin_kit.dart';

/// Changement obligatoire du mot de passe pour un compte admin créé avec un
/// mot de passe temporaire (`mustChangePassword == true`).
class AdminForcePasswordScreen extends StatefulWidget {
  const AdminForcePasswordScreen({super.key});

  @override
  State<AdminForcePasswordScreen> createState() =>
      _AdminForcePasswordScreenState();
}

class _AdminForcePasswordScreenState extends State<AdminForcePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      showAdminSnack(
        context,
        auth.errorMessage ?? 'Changement de mot de passe impossible.',
        error: true,
      );
    }
    // Succès : mustChangePassword passe à false, le router redirige vers /.
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: c.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.outlineVariant),
                boxShadow: c.softShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nouveau mot de passe requis',
                      style: AppTextStyles.headlineMd.copyWith(
                        fontSize: 21,
                        color: c.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Votre compte a été créé avec un mot de passe temporaire. '
                      'Choisissez un mot de passe personnel pour accéder à la console.',
                      style: AppTextStyles.bodySm.copyWith(
                        color: c.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _field(
                      context,
                      label: 'MOT DE PASSE TEMPORAIRE',
                      controller: _currentController,
                      obscure: true,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      context,
                      label: 'NOUVEAU MOT DE PASSE',
                      controller: _newController,
                      obscure: true,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Au moins 6 caractères.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _field(
                      context,
                      label: 'CONFIRMER',
                      controller: _confirmController,
                      obscure: true,
                      validator: (value) {
                        if (value != _newController.text) {
                          return 'Les mots de passe ne correspondent pas.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 44,
                      child: AdminButton(
                        label: 'Enregistrer',
                        icon: Icons.check_rounded,
                        primary: true,
                        onTap: _loading ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    FormFieldValidator<String>? validator,
  }) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelCaps.copyWith(
            color: c.onSurfaceVariant,
            fontSize: 9.5,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: AppTextStyles.bodySm.copyWith(
            fontSize: 13,
            color: c.onSurface,
          ),
          cursorColor: c.onSurface,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: c.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.goldInk, width: 1.3),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.statusProblem),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.statusProblem, width: 1.3),
            ),
            errorStyle: AppTextStyles.bodySm.copyWith(
              fontSize: 11,
              color: c.statusProblem,
            ),
          ),
        ),
      ],
    );
  }
}
