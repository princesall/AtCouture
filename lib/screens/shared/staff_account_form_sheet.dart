import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/firebase_error_messages.dart';
import '../../core/utils/whatsapp_launcher.dart';
import '../../core/widgets/premium_button.dart';
import '../../core/widgets/premium_text_field.dart';

/// Feuille de création / modification d'un compte du staff (couturier ou chef
/// d'atelier), au langage éditorial de l'app.
///
/// Remplace les anciens `AlertDialog` + `TextFormField` Material, qui juraient
/// avec le reste de l'interface (icônes Google, boutons pleins, pas de
/// hiérarchie typographique).
class StaffAccountFormSheet extends StatefulWidget {
  const StaffAccountFormSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.submitLabel,
    required this.onSubmit,
    this.initialName,
    this.initialPhone,
    this.initialEmail,
    this.footer,
  });

  final String title;
  final String subtitle;
  final String submitLabel;

  /// Lève une exception en cas d'échec : son message est affiché dans la
  /// feuille, qui reste ouverte pour laisser corriger la saisie.
  final Future<void> Function({
    required String fullName,
    required String phone,
    required String email,
  })
  onSubmit;

  final String? initialName;
  final String? initialPhone;
  final String? initialEmail;

  /// Zone libre sous les champs (ex. « envoyer un lien de réinitialisation »).
  final Widget? footer;

  static Future<bool> show(
    BuildContext context,
    StaffAccountFormSheet sheet,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
    return result ?? false;
  }

  @override
  State<StaffAccountFormSheet> createState() => _StaffAccountFormSheetState();
}

class _StaffAccountFormSheetState extends State<StaffAccountFormSheet> {
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _phoneController = TextEditingController(
    text: widget.initialPhone,
  );
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  final _formKey = GlobalKey<FormState>();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSubmit(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyFirebaseError(e);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: c.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    widget.title,
                    style: AppTextStyles.headlineSm.copyWith(
                      color: c.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: AppTextStyles.bodySm.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  PremiumTextField(
                    controller: _nameController,
                    label: 'Nom complet',
                    hint: 'Ex. Fatoumata Traoré',
                    prefixIcon: PhosphorIconsRegular.user,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PremiumTextField(
                    controller: _phoneController,
                    label: 'Téléphone',
                    hint: '70 00 00 00',
                    prefixIcon: PhosphorIconsRegular.phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PremiumTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'prenom@email.com',
                    prefixIcon: PhosphorIconsRegular.envelope,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Email valide requis'
                        : null,
                  ),
                  const SizedBox(height: 6),
                  // Seul moyen de récupérer un accès en cas d'oubli : le lien
                  // de réinitialisation part à CETTE adresse.
                  Text(
                    'Adresse consultable par la personne : c\'est le seul moyen de récupérer son accès en cas de mot de passe oublié.',
                    style: AppTextStyles.labelXs.copyWith(
                      color: c.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),

                  if (widget.footer != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    widget.footer!,
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _error!,
                      style: AppTextStyles.bodySm.copyWith(
                        color: c.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                  PremiumButton(
                    label: widget.submitLabel,
                    icon: PhosphorIconsRegular.check,
                    isLoading: _saving,
                    onPressed: _saving ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: c.onSurfaceVariant,
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Récapitulatif des identifiants d'un compte staff tout juste créé.
///
/// Le mot de passe temporaire n'est affiché qu'une seule fois : la feuille
/// offre donc un bouton « Copier » et un envoi WhatsApp pour ne pas dépendre
/// d'une recopie manuelle approximative.
class StaffCredentialsSheet extends StatelessWidget {
  const StaffCredentialsSheet({
    super.key,
    required this.fullName,
    required this.email,
    required this.temporaryPassword,
    this.phone,
  });

  final String fullName;
  final String email;
  final String temporaryPassword;
  final String? phone;

  static Future<void> show(
    BuildContext context, {
    required String fullName,
    required String email,
    required String temporaryPassword,
    String? phone,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StaffCredentialsSheet(
      fullName: fullName,
      email: email,
      temporaryPassword: temporaryPassword,
      phone: phone,
    ),
  );

  Future<void> _copy(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copié.')));
  }

  Future<void> _sendByWhatsApp(BuildContext context) async {
    final message =
        'Bonjour $fullName, votre accès StyleConnect est prêt.\n'
        'Email : $email\n'
        'Mot de passe temporaire : $temporaryPassword\n'
        'Vous devrez le changer à votre première connexion.';
    final ok = phone != null && phone!.trim().isNotEmpty
        ? await WhatsAppLauncher.sendMessage(phone: phone!, message: message)
        : false;
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp n\'a pas pu être ouvert.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: c.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Compte créé',
              style: AppTextStyles.headlineSm.copyWith(color: c.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Transmettez ces identifiants à $fullName. Le mot de passe '
              'temporaire ne sera plus affiché ensuite.',
              style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            _CredentialsCard(
              children: [
                _CredentialsRow(
                  label: 'Email',
                  value: email,
                  onCopy: () => _copy(context, 'Email', email),
                ),
                Divider(color: c.outlineVariant, height: AppSpacing.lg),
                _CredentialsRow(
                  label: 'Mot de passe temporaire',
                  value: temporaryPassword,
                  strong: true,
                  onCopy: () =>
                      _copy(context, 'Mot de passe', temporaryPassword),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  PhosphorIconsRegular.info,
                  size: 14,
                  color: c.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'La personne devra définir son propre mot de passe à sa '
                    'première connexion.',
                    style: AppTextStyles.labelXs.copyWith(
                      color: c.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PremiumButton(
              label: 'Envoyer par WhatsApp',
              icon: PhosphorIconsRegular.whatsappLogo,
              variant: PremiumButtonVariant.outline,
              onPressed: () => _sendByWhatsApp(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            PremiumButton(
              label: 'Terminé',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CredentialsCard extends StatelessWidget {
  const _CredentialsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: c.outlineVariant, width: 1),
        boxShadow: c.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _CredentialsRow extends StatelessWidget {
  const _CredentialsRow({
    required this.label,
    required this.value,
    required this.onCopy,
    this.strong = false,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelCaps.copyWith(
                  color: c.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: (strong ? AppTextStyles.titleSm : AppTextStyles.bodyLg)
                    .copyWith(
                      color: c.onSurface,
                      letterSpacing: strong ? 1.2 : 0,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onCopy,
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          color: c.goldInk,
          tooltip: 'Copier',
          icon: const Icon(PhosphorIconsRegular.copy),
        ),
      ],
    );
  }
}
