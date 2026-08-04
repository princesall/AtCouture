import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/auth_backdrop.dart';
import '../../core/widgets/google_sign_in_button.dart';
import '../../core/widgets/premium_button.dart';
import '../../core/widgets/premium_text_field.dart';
import '../../models/subscription_plan.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

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
  XFile? _logoFile;

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (picked == null) return;
    setState(() => _logoFile = picked);
  }

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
      logoPath: _logoFile?.path,
    );

    if (!mounted) return;
    if (!success && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: context.colors.error),
      );
    }
  }

  Future<void> _submitGoogle() async {
    final auth = context.read<AuthProvider>();
    final result = await auth.signInWithGoogle();

    if (!mounted) return;
    if (result == null) {
      if (auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage!), backgroundColor: context.colors.error),
        );
      }
      return;
    }
    if (result is GoogleSignInNeedsProfile) {
      context.push('/auth/complete-profile', extra: result);
    }
    // GoogleSignInExisting : AuthProvider est déjà authenticated, le router
    // redirige automatiquement vers le bon espace.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.primary,
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
                color: c.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: c.premiumShadow,
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
                            Center(child: _LogoPicker(file: _logoFile, onTap: _pickLogo)),
                            const SizedBox(height: AppSpacing.md),
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
                                  style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(child: Divider(color: c.outlineVariant)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                  child: Text('OU', style: AppTextStyles.labelCaps.copyWith(color: c.onSurfaceVariant)),
                                ),
                                Expanded(child: Divider(color: c.outlineVariant)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            GoogleSignInButton(
                              label: 'Continuer avec Google',
                              isLoading: auth.isLoading,
                              onPressed: auth.isLoading ? null : _submitGoogle,
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

// ── Sélecteur du logo de l'atelier (optionnel, à la création du compte) ─────
class _LogoPicker extends StatelessWidget {
  const _LogoPicker({required this.file, required this.onTap});
  final XFile? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.surfaceContainerLowest,
                  border: Border.all(color: c.outlineVariant.withValues(alpha: 0.5), width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: file == null
                    ? Icon(Icons.storefront_outlined, color: c.onSurfaceVariant, size: 32)
                    : FutureBuilder<Uint8List>(
                        future: file!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Container(color: c.surfaceContainerLow);
                          }
                          return Image.memory(snapshot.data!, width: 88, height: 88, fit: BoxFit.cover);
                        },
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: c.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.background, width: 2),
                  ),
                  child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            file == null ? 'Ajouter le logo de l\'atelier' : 'Modifier le logo',
            style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
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
      style: AppTextStyles.labelCaps.copyWith(color: context.colors.secondary),
    );
  }
}

// ── Aperçu du plan Gratuit inclus ────────────────────────────────────────────
class _PlanPreviewChip extends StatelessWidget {
  const _PlanPreviewChip({required this.plan});
  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: c.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: c.goldGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.workspace_premium_rounded, color: c.onTertiary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan ${plan.name} inclus',
                  style: AppTextStyles.titleSm.copyWith(color: c.primary, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${plan.tailorsLabel} · ${plan.clientsLabel}',
                  style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
