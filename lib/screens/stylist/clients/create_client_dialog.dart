import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_color_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/build_context_colors.dart';
import '../../../core/utils/firebase_error_messages.dart';
import '../../../models/app_user.dart';
import '../../../models/client.dart';
import '../../../services/order_service.dart';

/// Fiche de création d'un client.
///
/// Remplace l'ancien `AlertDialog` minimal (nom / téléphone / email) par un
/// formulaire dédié : validation dans les champs, détection immédiate d'un
/// client déjà existant, notes libres et confirmation explicite. Retourne le
/// [Client] créé via `Navigator.pop`, ou `null` si l'utilisateur annule.
class CreateClientDialog extends StatefulWidget {
  const CreateClientDialog({super.key, required this.user});

  final AppUser user;

  @override
  State<CreateClientDialog> createState() => _CreateClientDialogState();
}

class _CreateClientDialogState extends State<CreateClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  final _idempotencyKey = const Uuid().v4();

  bool _isSubmitting = false;
  Client? _duplicate;
  Timer? _duplicateDebounce;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_scheduleDuplicateCheck);
    _phoneController.addListener(_scheduleDuplicateCheck);
  }

  @override
  void dispose() {
    _duplicateDebounce?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _scheduleDuplicateCheck() {
    _duplicateDebounce?.cancel();
    _duplicateDebounce = Timer(
      const Duration(milliseconds: 350),
      _checkDuplicate,
    );
  }

  void _checkDuplicate() {
    if (!mounted) return;
    final atelierId = widget.user.atelierId;
    if (atelierId == null) return;

    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    Client? match;
    if (phone.length >= 6) {
      match = OrderService.instance.findClientByPhone(phone, atelierId);
    }
    if (match == null && name.length >= 3) {
      match = OrderService.instance.findClientByName(name, atelierId);
    }

    if (match?.id != _duplicate?.id) {
      setState(() => _duplicate = match);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final atelierId = widget.user.atelierId;
    if (atelierId == null) {
      _showMessage('Atelier introuvable. Reconnectez-vous puis réessayez.');
      return;
    }

    // Un même numéro de téléphone identifie la même personne : on bloque la
    // création d'un doublon et on invite à ouvrir la fiche existante. Un nom
    // identique seul reste autorisé (homonymes), avec un avertissement.
    // La vérification est refaite ici (et pas seulement dans le debounce de
    // saisie) : un utilisateur qui remplit le formulaire très vite pouvait
    // soumettre avant que la détection asynchrone n'ait eu le temps de courir.
    final phone = _phoneController.text.trim();
    final existingByPhone = OrderService.instance.findClientByPhone(
      phone,
      atelierId,
    );
    final duplicate = existingByPhone ?? _duplicate;
    if (duplicate != null && duplicate.phone == phone) {
      _showMessage(
        'Un client utilise déjà ce numéro : ${duplicate.fullName}. '
        'Ouvrez sa fiche depuis la liste des clients.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final client = await OrderService.instance.addClient(
        atelierId: atelierId,
        atelierName: widget.user.atelierName ?? '',
        fullName: _nameController.text,
        phone: phone,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        idempotencyKey: _idempotencyKey,
      );
      if (!mounted) return;
      Navigator.pop(context, client);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage(friendlyFirebaseError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(c),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionCard(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'Identité du client',
                        subtitle: 'Le nom et le téléphone sont obligatoires.',
                        children: [
                          _ClientField(
                            controller: _nameController,
                            label: 'Nom complet *',
                            hint: 'Ex. Fatoumata Diallo',
                            icon: Icons.badge_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Le nom du client est obligatoire.'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _ClientField(
                            controller: _phoneController,
                            label: 'Téléphone *',
                            hint: '70 00 00 00',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Le téléphone est obligatoire.';
                              }
                              final digits = text.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              );
                              if (digits.length < 8) {
                                return 'Numéro trop court (8 chiffres minimum).';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _ClientField(
                            controller: _emailController,
                            label: 'Email (optionnel)',
                            hint: 'client@email.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return null;
                              // Contrôle volontairement simple : on veut
                              // attraper les fautes évidentes sans rejeter des
                              // adresses professionnelles valides.
                              if (!RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(text)) {
                                return 'Adresse email invalide.';
                              }
                              return null;
                            },
                          ),
                          if (_duplicate != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _DuplicateBanner(client: _duplicate!),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        icon: Icons.sticky_note_2_outlined,
                        title: 'Préférences & notes',
                        subtitle:
                            'Facultatif — utile pour la prochaine commande.',
                        children: [
                          _ClientField(
                            controller: _notesController,
                            label: 'Notes internes',
                            hint:
                                'Style préféré, allergies, retouches habituelles…',
                            icon: Icons.notes_rounded,
                            maxLines: 3,
                            textInputAction: TextInputAction.newline,
                          ),
                        ],
                      ),
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
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: c.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_add_alt_1_rounded,
              color: c.secondary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouveau client',
                  style: AppTextStyles.titleMd.copyWith(color: c.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  'Créez une fiche réutilisable pour toutes ses commandes.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close_rounded),
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
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
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(_isSubmitting ? 'Création…' : 'Créer le client'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: c.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: c.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: c.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: c.secondary),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleSm.copyWith(color: c.onSurface),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: AppTextStyles.bodySm.copyWith(
                color: c.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _ClientField extends StatelessWidget {
  const _ClientField({
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      maxLines: maxLines,
      textCapitalization: maxLines > 1
          ? TextCapitalization.sentences
          : TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

class _DuplicateBanner extends StatelessWidget {
  const _DuplicateBanner({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: c.tertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: c.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fiche existante : ${client.fullName}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: c.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${client.phone} · ${client.orderCount} commande(s)',
                  style: AppTextStyles.bodySm.copyWith(
                    color: c.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
