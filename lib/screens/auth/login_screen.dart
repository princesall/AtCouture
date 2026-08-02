import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/auth_backdrop.dart';
import '../../core/widgets/premium_button.dart';
import '../../core/widgets/premium_text_field.dart';
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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(_email.text.trim(), _password.text);

    if (!mounted) return;
    if (!success && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: context.colors.error,
        ),
      );
    }
    // La redirection est gérée automatiquement par go_router via AuthProvider
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.primary,
      body: Stack(
        children: [
          const Positioned.fill(child: AuthBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 760;
                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24, isWide ? 48 : 32, 24, 24 + bottomInset,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isWide ? 940 : 440),
                      child: isWide
                          ? IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _BrandPanel(isWide: true)),
                                  const SizedBox(width: 56),
                                  SizedBox(
                                    width: 420,
                                    child: Center(
                                      child: _LoginCard(
                                        formKey: _formKey,
                                        email: _email,
                                        password: _password,
                                        auth: auth,
                                        onSubmit: _submit,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _BrandPanel(isWide: false),
                                const SizedBox(height: 28),
                                _LoginCard(
                                  formKey: _formKey,
                                  email: _email,
                                  password: _password,
                                  auth: auth,
                                  onSubmit: _submit,
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bloc marque (monogramme + wordmark + tagline) ───────────────────────────
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.isWide});
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final crossAxis = isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = isWide ? TextAlign.left : TextAlign.center;

    final content = Column(
      crossAxisAlignment: crossAxis,
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMonogram(size: 60).animate().scale(
              duration: AppConstants.animationSlow,
              curve: Curves.easeOutBack,
              begin: const Offset(0.6, 0.6),
            ),
        const SizedBox(height: 20),
        Text(
          'BIENVENUE',
          textAlign: textAlign,
          style: AppTextStyles.labelCaps.copyWith(
            color: c.tertiaryFixedDim,
            letterSpacing: 3,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        Text(
          'StyleConnect',
          textAlign: textAlign,
          style: AppTextStyles.displayLg.copyWith(
            color: Colors.white,
            fontSize: isWide ? 42 : 32,
          ),
        ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        Text(
          AppConstants.appTagline,
          textAlign: textAlign,
          style: AppTextStyles.bodyLg.copyWith(
            color: Colors.white.withValues(alpha: 0.68),
          ),
        ).animate().fadeIn(delay: 260.ms),
      ],
    );

    if (!isWide) return content;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          const SizedBox(height: 40),
          ..._features.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _FeatureRow(icon: e.value.$1, label: e.value.$2)
                    .animate()
                    .fadeIn(delay: (400 + e.key * 100).ms)
                    .slideX(begin: -0.06, end: 0),
              )),
        ],
      ),
    );
  }

  static const _features = [
    (Icons.receipt_long_rounded, 'Suivi des commandes en temps réel'),
    (Icons.straighten_rounded, 'Mesures et fiches clients centralisées'),
    (Icons.workspace_premium_rounded, 'De l\'atelier solo à l\'entreprise multi-sites'),
  ];
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: c.tertiaryFixedDim),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ),
      ],
    );
  }
}

// ── Carte verre dépoli — formulaire ─────────────────────────────────────────
class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.email,
    required this.password,
    required this.auth,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final AuthProvider auth;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: c.surfaceContainerLowest.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: c.premiumShadow,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Connexion',
                  style: AppTextStyles.titleMd.copyWith(color: c.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Accédez à votre espace de travail',
                  style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                ),
                const SizedBox(height: 26),

                PremiumTextField(
                  controller: email,
                  label: 'Adresse email',
                  hint: 'votre@email.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Email invalide' : null,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: AppSpacing.md),

                PremiumTextField(
                  controller: password,
                  label: 'Mot de passe',
                  hint: '••••••••',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSubmit(),
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Minimum 6 caractères' : null,
                ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.1, end: 0),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/auth/forgot-password'),
                    child: Text(
                      'Mot de passe oublié ?',
                      style: AppTextStyles.bodySm.copyWith(color: c.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                PremiumButton(
                  label: 'Se connecter',
                  variant: PremiumButtonVariant.dark,
                  isLoading: auth.isLoading,
                  onPressed: auth.isLoading ? null : onSubmit,
                ).animate().fadeIn(delay: 450.ms).scale(begin: const Offset(0.95, 0.95)),

                const SizedBox(height: 20),

                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Pas encore de compte ? ',
                      style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => context.push('/auth/register'),
                            child: Text(
                              'Créer un compte',
                              style: AppTextStyles.bodySm.copyWith(
                                color: c.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/suivi'),
                    icon: const Icon(Icons.receipt_long_outlined, size: 16),
                    label: const Text('Suivre une commande sans compte'),
                    style: TextButton.styleFrom(foregroundColor: c.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.06, end: 0),
      ),
    );
  }
}
