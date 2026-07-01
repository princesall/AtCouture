import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/premium_button.dart';
import '../../core/widgets/premium_text_field.dart';
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
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Inscription'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Créez votre atelier',
                style: AppTextStyles.headlineLgMobile,
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Plan Gratuit inclus — 1 couturier, 20 clients',
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PremiumTextField(
                controller: _nameController,
                label: 'Nom complet',
                hint: 'Votre nom',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumTextField(
                controller: _atelierController,
                label: 'Nom de l\'atelier',
                hint: 'Atelier Élégance',
                prefixIcon: Icons.storefront_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nom d\'atelier requis' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'votre@email.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumTextField(
                controller: _phoneController,
                label: 'Téléphone',
                hint: '70 00 00 00',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Téléphone requis' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumTextField(
                controller: _passwordController,
                label: 'Mot de passe',
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'Minimum 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumTextField(
                controller: _confirmController,
                label: 'Confirmer le mot de passe',
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
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
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Déjà un compte ? Se connecter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
