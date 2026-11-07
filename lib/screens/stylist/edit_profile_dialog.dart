import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_color_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/widgets/premium_text_field.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/company_service.dart';

/// Fiche de modification des informations du compte : nom complet, téléphone,
/// nom de l'atelier (ou de l'entreprise) et adresse.
///
/// Jusqu'ici seul le logo était modifiable : le nom, le téléphone et le nom de
/// l'atelier étaient affichés comme du texte mort dans le profil. Une faute de
/// frappe à l'inscription restait donc gravée à vie, y compris sur les
/// documents et messages WhatsApp envoyés aux clients.
///
/// Retourne `true` via `Navigator.pop` si l'enregistrement a réussi.
class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key, required this.user});

  final AppUser user;

  static Future<bool?> show(BuildContext context, AppUser user) {
    return showDialog<bool>(
      context: context,
      builder: (_) => EditProfileDialog(user: user),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.user.fullName,
  );
  late final _phoneController = TextEditingController(text: widget.user.phone);
  late final _atelierController = TextEditingController(
    text: widget.user.atelierName ?? '',
  );
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  String? _error;

  /// L'adresse vit dans `ateliers/{id}.address`, pas dans le compte : on la
  /// relit à l'ouverture pour ne pas l'effacer par une valeur vide au premier
  /// enregistrement.
  bool _addressLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final atelierId = widget.user.atelierId;
    if (atelierId == null) {
      if (mounted) setState(() => _addressLoaded = true);
      return;
    }
    try {
      final atelier = await CompanyService.instance.fetchAtelier(atelierId);
      if (!mounted) return;
      setState(() {
        _addressController.text = atelier?.address ?? '';
        _addressLoaded = true;
      });
    } catch (_) {
      // Adresse indisponible : le champ reste vide, la saisie fonctionne
      // quand même. Ce n'est pas bloquant pour les autres modifications.
      if (mounted) setState(() => _addressLoaded = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _atelierController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _isCompanyOwner => widget.user.isCompanyOwner;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      atelierName: _atelierController.text.trim(),
      atelierAddress: _addressController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _error = auth.errorMessage ?? 'Enregistrement impossible. Réessayez.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(c),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PremiumTextField(
                        controller: _nameController,
                        label: 'Nom complet',
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().length < 2) {
                            return 'Indiquez votre nom complet';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PremiumTextField(
                        controller: _phoneController,
                        label: 'Téléphone',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          final digits = (v ?? '').replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );
                          if (digits.length < 8) {
                            return 'Au moins 8 chiffres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PremiumTextField(
                        controller: _atelierController,
                        label: _isCompanyOwner
                            ? "Nom de l'entreprise"
                            : "Nom de l'atelier",
                        prefixIcon: _isCompanyOwner
                            ? Icons.apartment_rounded
                            : Icons.storefront_outlined,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return _isCompanyOwner
                                ? "Indiquez le nom de l'entreprise"
                                : "Indiquez le nom de l'atelier";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PremiumTextField(
                        controller: _addressController,
                        label: 'Adresse (optionnel)',
                        hint: _addressLoaded
                            ? 'Quartier, ville'
                            : 'Chargement…',
                        prefixIcon: Icons.location_on_outlined,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "L'adresse e-mail de connexion n'est pas modifiable ici.",
                        style: AppTextStyles.bodySm.copyWith(
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: c.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 18,
                                color: c.error,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: c.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(c),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorPalette c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: c.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.edit_outlined, color: c.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Mes informations', style: AppTextStyles.headlineSm),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppColorPalette c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: c.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
