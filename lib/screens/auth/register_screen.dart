import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/auth_backdrop.dart';
import '../../core/widgets/premium_button.dart';
import '../../core/widgets/premium_text_field.dart';
import '../../models/subscription_plan.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _atelierController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _atelierController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      fullName: _nameController.text,
      atelierName: _atelierController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (!success && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          // ── Bandeau de marque ──────────────────────────────────────────
          SizedBox(
            height: 168,
            child: Stack(
              children: [
                const Positioned.fill(child: AuthBackdrop()),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 24, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const BrandMonogram(size: 44),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Créez votre atelier',
                                        style: AppTextStyles.headlineSm.copyWith(color: Colors.white),
                                      ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Rejoignez StyleConnect en 1 minute',
                                        style: AppTextStyles.bodySm.copyWith(
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                      ).animate().fadeIn(delay: 100.ms),
                                    ],
                                  ),
                                ),
                              ],
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

          // ── Feuille formulaire ───────────────────────────────────────────
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: AppColors.premiumShadow,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            _PlanPreviewChip(plan: SubscriptionPlan.free)
                                .animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
                            const SizedBox(height: AppSpacing.xl),

                            _SectionLabel('Vos informations'),
                            const SizedBox(height: AppSpacing.sm),
                            PremiumTextField(
                              controller: _nameController,
                              label: 'Nom complet',
                              hint: 'Votre nom',
                              prefixIcon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                              validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            PremiumTextField(
                              controller: _atelierController,
                              label: 'Nom de l\'atelier',
                              hint: 'Atelier Élégance',
                              prefixIcon: Icons.storefront_outlined,
                              textInputAction: TextInputAction.next,
                              validator: (v) => v == null || v.isEmpty ? 'Nom d\'atelier requis' : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            PremiumTextField(
                              controller: _phoneController,
                              label: 'Téléphone',
                              hint: '70 00 00 00',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: (v) => v == null || v.isEmpty ? 'Téléphone requis' : null,
                            ),

                            const SizedBox(height: AppSpacing.xl),
                            _SectionLabel('Connexion'),
                            const SizedBox(height: AppSpacing.sm),
                            PremiumTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'votre@email.com',
                              prefixIcon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email requis';
                                if (!v.contains('@')) return 'Email invalide';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            PremiumTextField(
                              controller: _passwordController,
                              label: 'Mot de passe',
                              obscureText: true,
                              prefixIcon: Icons.lock_outline_rounded,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.length < 6) return 'Minimum 6 caractères';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            PremiumTextField(
                              controller: _confirmController,
                              label: 'Confirmer le mot de passe',
                              obscureText: true,
                              prefixIcon: Icons.lock_outline_rounded,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Les mots de passe ne correspondent pas';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: AppSpacing.xl),
                            PremiumButton(
                              label: 'Créer mon compte',
                              variant: PremiumButtonVariant.gold,
                              isLoading: auth.isLoading,
                              onPressed: auth.isLoading ? null : _submit,
                            ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
                            const SizedBox(height: AppSpacing.md),
                            Center(
                              child: TextButton(
                                onPressed: () => context.pop(),
                                child: Text(
                                  'Déjà un compte ? Se connecter',
                                  style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
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
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.labelCaps.copyWith(color: AppColors.secondary),
    );
  }
}

// ── Aperçu du plan Gratuit inclus ────────────────────────────────────────────
class _PlanPreviewChip extends StatelessWidget {
  const _PlanPreviewChip({required this.plan});
  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: AppColors.onTertiary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan ${plan.name} inclus',
                  style: AppTextStyles.titleSm.copyWith(color: AppColors.primary, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${plan.tailorsLabel} · ${plan.clientsLabel}',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
