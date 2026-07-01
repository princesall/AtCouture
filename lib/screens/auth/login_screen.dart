import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool _obscure   = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      _email.text.trim(),
      _password.text,
    );

    if (!mounted) return;
    if (!success && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
    // La redirection est gérée automatiquement par go_router via AuthProvider
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Header gradient Indigo ───────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.40,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Text(
                        'BIENVENUE',
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.tertiaryFixedDim,
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 6),
                      Text(
                        'StyleConnect',
                        style: AppTextStyles.displayLg.copyWith(
                          color: Colors.white,
                          fontSize: 34,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 6),
                      Text(
                        'Gérez votre atelier avec élégance',
                        style: AppTextStyles.bodyLg.copyWith(
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Formulaire ───────────────────────────────────────────────────
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.33,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.premiumShadow,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Connexion',
                        style: AppTextStyles.titleMd.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Accédez à votre espace de travail',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 28),

                      // Email
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'ADRESSE EMAIL',
                          hintText: 'votre@email.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.onSurfaceVariant, size: 20),
                        ),
                        validator: (v) =>
                            v == null || !v.contains('@') ? 'Email invalide' : null,
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 16),

                      // Mot de passe
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'MOT DE PASSE',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.onSurfaceVariant, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.length < 6 ? 'Minimum 6 caractères' : null,
                      ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.1, end: 0),

                      // Mot de passe oublié
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/auth/forgot-password'),
                          child: Text(
                            'Mot de passe oublié ?',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Bouton connexion
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : Text(
                                  'SE CONNECTER',
                                  style: AppTextStyles.labelCaps.copyWith(
                                    color: AppColors.onPrimary,
                                    fontSize: 13,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 450.ms).scale(begin: const Offset(0.95, 0.95)),

                      const SizedBox(height: 20),

                      // Lien inscription
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Pas encore de compte ? ',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                            children: [
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => context.push('/auth/register'),
                                  child: Text(
                                    'Créer un compte',
                                    style: AppTextStyles.bodySm.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, end: 0),
            ),
          ),
        ],
      ),
    );
  }
}
