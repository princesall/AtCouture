import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/premium_button.dart';
import '../../core/widgets/premium_text_field.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(_emailController.text);

    if (!mounted) return;
    if (success) {
      setState(() => _sent = true);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mot de passe oublié'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _sent ? _buildSuccess() : _buildForm(auth),
      ),
    );
  }

  Widget _buildForm(AuthProvider auth) {
    final c = context.colors;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Réinitialisation', style: AppTextStyles.headlineLgMobile),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Entrez votre email pour recevoir un lien de réinitialisation.',
            style: AppTextStyles.bodyLg.copyWith(
              color: c.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PremiumTextField(
            controller: _emailController,
            label: 'Email',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email requis';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          PremiumButton(
            label: 'Envoyer le lien',
            variant: PremiumButtonVariant.gold,
            isLoading: auth.isLoading,
            onPressed: auth.isLoading ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final c = context.colors;
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: c.statusDoneBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 40,
            color: c.statusDone,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Email envoyé',
          style: AppTextStyles.headlineLgMobile,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Consultez votre boîte mail pour réinitialiser votre mot de passe.',
          style: AppTextStyles.bodyLg.copyWith(
            color: c.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        PremiumButton(
          label: 'Retour à la connexion',
          onPressed: () => context.go('/auth/login'),
        ),
      ],
    );
  }
}
