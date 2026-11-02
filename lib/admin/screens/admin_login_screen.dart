import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../providers/auth_provider.dart';
import '../widgets/admin_dialogs.dart';

/// Connexion à la console. Volontairement séparée de l'écran de connexion
/// mobile : pas d'inscription, pas de Google, contrôle strict du rôle admin.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscure = true;
  String? _localError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _localError = null);

    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(
      _emailController.text.trim(),
      _passwordController.text,
      requireAdmin: true,
    );

    if (!mounted) return;
    if (!ok) {
      setState(() {
        _localError = auth.errorMessage ?? 'Connexion impossible.';
      });
    }
    // Succès : le router (refreshListenable) redirige vers la console.
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Saisissez d\'abord votre email administrateur.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(email);
    if (!mounted) return;
    showAdminSnack(
      context,
      ok
          ? 'Email de réinitialisation envoyé à $email.'
          : (auth.errorMessage ?? 'Envoi impossible.'),
      error: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: c.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final form = _buildForm(context, auth);

          if (!wide) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCompactBrand(context),
                    const SizedBox(height: 32),
                    form,
                  ],
                ),
              ),
            );
          }

          return Row(
            children: [
              Expanded(flex: 5, child: _buildBrandPanel(context)),
              Expanded(flex: 4, child: Center(child: form)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrandPanel(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(gradient: c.heroGradient),
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: c.goldGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  'S',
                  style: AppTextStyles.headlineSm.copyWith(
                    fontSize: 17,
                    height: 1,
                    color: c.onTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'STYLECONNECT',
                style: AppTextStyles.headlineSm.copyWith(
                  fontSize: 15,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 42,
            height: 2,
            color: c.tertiary,
          ),
          const SizedBox(height: 22),
          Text(
            'La plateforme,\nsous contrôle.',
            style: AppTextStyles.displayLg.copyWith(
              fontSize: 42,
              height: 1.12,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              'Gérez les comptes, les abonnements et le support depuis une console '
              'pensée pour le bureau — sans jamais embarquer l\'administration dans '
              'l\'application de vos clients.',
              style: AppTextStyles.bodyLg.copyWith(
                fontSize: 14,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
          ),
          const SizedBox(height: 34),
          _FeatureLine(
            icon: Icons.verified_user_outlined,
            text: 'Accès strictement réservé aux administrateurs',
          ),
          const SizedBox(height: 14),
          _FeatureLine(
            icon: Icons.receipt_long_outlined,
            text: 'Décisions tracées et notifiées automatiquement',
          ),
          const SizedBox(height: 14),
          _FeatureLine(
            icon: Icons.workspace_premium_outlined,
            text: 'Abonnements et expirations pilotés en temps réel',
          ),
          const Spacer(),
          Text(
            '© 2026 StyleConnect · Bamako, Mali',
            style: AppTextStyles.labelXs.copyWith(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBrand(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: c.heroGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            'S',
            style: AppTextStyles.headlineSm.copyWith(
              fontSize: 15,
              height: 1,
              color: c.tertiary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STYLECONNECT',
              style: AppTextStyles.headlineSm.copyWith(
                fontSize: 14,
                letterSpacing: 1.5,
                color: c.onSurface,
              ),
            ),
            Text(
              'CONSOLE ADMIN',
              style: AppTextStyles.labelXs.copyWith(
                color: c.goldInk,
                fontSize: 8,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AuthProvider auth) {
    final c = context.colors;
    final error = _localError ?? auth.errorMessage;
    final loading = auth.isLoading;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Connexion administrateur',
              style: AppTextStyles.headlineLg.copyWith(
                fontSize: 28,
                color: c.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Utilisez votre compte administrateur StyleConnect.',
              style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            _AdminField(
              label: 'EMAIL',
              controller: _emailController,
              hint: 'admin@styleconnect.ml',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Saisissez votre email.';
                if (!email.contains('@')) return 'Email invalide.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _AdminField(
              label: 'MOT DE PASSE',
              controller: _passwordController,
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscure,
              focusNode: _passwordFocus,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: c.onSurfaceVariant,
                ),
                tooltip: _obscure ? 'Afficher' : 'Masquer',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Saisissez votre mot de passe.';
                }
                return null;
              },
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: error),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: Material(
                color: c.primary,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: loading ? null : _submit,
                  borderRadius: BorderRadius.circular(10),
                  child: Center(
                    child: loading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.onPrimary,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login_rounded, size: 17, color: c.onPrimary),
                              const SizedBox(width: 8),
                              Text(
                                'SE CONNECTER',
                                style: AppTextStyles.labelCaps.copyWith(
                                  color: c.onPrimary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: loading ? null : _resetPassword,
                child: Text(
                  'Mot de passe oublié ?',
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 12,
                    color: c.onSurfaceVariant,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            if (kDebugMode && auth.isDemoMode) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.tertiary.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MODE DÉMO (DEBUG)',
                      style: AppTextStyles.labelXs.copyWith(
                        color: c.onTertiaryContainer,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'admin@styleconnect.ml · admin123',
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 12,
                        color: c.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ces identifiants ne sont jamais compilés en release.',
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 10.5,
                        color: c.onTertiaryContainer.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 15, color: c.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous êtes styliste ou chef d\'entreprise ? Utilisez l\'application mobile StyleConnect. '
                      'Cet espace est réservé à l\'administration de la plateforme.',
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 11,
                        height: 1.5,
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: c.tertiary),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminField extends StatelessWidget {
  const _AdminField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.focusNode,
    this.suffix,
    this.onSubmitted,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelCaps.copyWith(
            color: c.onSurfaceVariant,
            fontSize: 9.5,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          focusNode: focusNode,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: AppTextStyles.bodySm.copyWith(
            fontSize: 13.5,
            color: c.onSurface,
          ),
          cursorColor: c.onSurface,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: AppTextStyles.bodySm.copyWith(
              fontSize: 13,
              color: c.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(icon, size: 18, color: c.onSurfaceVariant),
            suffixIcon: suffix,
            filled: true,
            fillColor: c.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.statusProblemBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.statusProblem.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: c.statusProblem),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm.copyWith(
                fontSize: 12,
                color: c.statusProblem,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
