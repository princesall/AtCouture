import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/premium_button.dart';
import '../../core/widgets/premium_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';

/// Dernière étape après une première connexion Google (voir
/// AuthProvider.signInWithGoogle) : Google ne fournit ni nom d'atelier ni
/// téléphone, donc on les demande ici avant de finaliser la création du
/// compte styliste. Route publique (/auth/complete-profile), atteinte
/// uniquement via context.push(extra: GoogleSignInNeedsProfile).
class GoogleProfileCompletionScreen extends StatefulWidget {
  const GoogleProfileCompletionScreen({super.key, required this.pending});

  final GoogleSignInNeedsProfile pending;

  @override
  State<GoogleProfileCompletionScreen> createState() => _GoogleProfileCompletionScreenState();
}

class _GoogleProfileCompletionScreenState extends State<GoogleProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _atelierController = TextEditingController();
  late final _phoneController = TextEditingController();
  XFile? _logoFile;

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (picked == null) return;
    setState(() => _logoFile = picked);
  }

  @override
  void dispose() {
    _atelierController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.completeGoogleSignUp(
      uid: widget.pending.uid,
      email: widget.pending.email,
      fullName: widget.pending.fullName,
      atelierName: _atelierController.text,
      phone: _phoneController.text,
      // Logo de l'atelier choisi ici prioritaire sur la photo du compte
      // Google (qui n'est qu'un repli si le styliste n'ajoute pas de logo).
      photoUrl: _logoFile?.path ?? widget.pending.photoUrl,
    );

    if (!mounted) return;
    if (!success && auth.errorMessage != null) {
      // Voir login_screen.dart : context.colors (context.watch<ThemeProvider>())
      // ne doit jamais être appelé hors du cycle de build.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: context.read<ThemeProvider>().colors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final c = context.colors;

    return Scaffold(
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
                      child: _LogoPicker(
                        file: _logoFile,
                        fallbackUrl: widget.pending.photoUrl,
                        fallbackInitial: widget.pending.fullName.isNotEmpty
                            ? widget.pending.fullName[0].toUpperCase()
                            : '?',
                        onTap: _pickLogo,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Encore une étape, ${widget.pending.fullName.isEmpty ? '' : widget.pending.fullName.split(' ').first}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMd.copyWith(color: c.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quelques infos pour créer votre atelier sur StyleConnect.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PremiumTextField(
                      controller: _atelierController,
                      label: 'Nom de l\'atelier',
                      hint: 'Atelier Élégance',
                      prefixIcon: Icons.storefront_outlined,
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                      validator: (v) => v == null || v.isEmpty ? 'Nom d\'atelier requis' : null,
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),
                    const SizedBox(height: AppSpacing.md),
                    PremiumTextField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      hint: '70 00 00 00',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) => v == null || v.isEmpty ? 'Téléphone requis' : null,
                    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.06, end: 0),
                    const SizedBox(height: AppSpacing.xl),
                    PremiumButton(
                      label: 'Terminer',
                      variant: PremiumButtonVariant.gold,
                      isLoading: auth.isLoading,
                      onPressed: auth.isLoading ? null : _submit,
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
}

// ── Sélecteur du logo de l'atelier (optionnel), avec repli sur la photo du
// compte Google puis sur l'initiale du nom si aucune image n'est disponible.
class _LogoPicker extends StatelessWidget {
  const _LogoPicker({
    required this.file,
    required this.fallbackUrl,
    required this.fallbackInitial,
    required this.onTap,
  });

  final XFile? file;
  final String? fallbackUrl;
  final String fallbackInitial;
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.primaryContainer,
                  border: Border.all(color: c.outlineVariant.withValues(alpha: 0.5), width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImage(context),
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

  Widget _buildImage(BuildContext context) {
    final c = context.colors;
    if (file != null) {
      return FutureBuilder<Uint8List>(
        future: file!.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(color: c.surfaceContainerLow);
          }
          return Image.memory(snapshot.data!, width: 72, height: 72, fit: BoxFit.cover);
        },
      );
    }
    if (fallbackUrl != null) {
      return Image.network(fallbackUrl!, width: 72, height: 72, fit: BoxFit.cover);
    }
    return Center(
      child: Text(
        fallbackInitial,
        style: AppTextStyles.titleMd.copyWith(color: c.onPrimaryContainer),
      ),
    );
  }
}
