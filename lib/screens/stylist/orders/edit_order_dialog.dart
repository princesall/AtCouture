import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/build_context_colors.dart';
import '../../../core/utils/firebase_error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order.dart';
import '../../../services/order_service.dart';

/// Modification d'une commande déjà créée : description, prix, acompte et date
/// de livraison.
///
/// Jusqu'ici une commande était DÉFINITIVE dès sa création (OrderService
/// .updateOrder existait mais n'était appelé nulle part) : une faute de frappe
/// sur un prix faussait durablement le solde affiché au client, les revenus
/// calculés pour l'atelier, ET le total dépensé du client — sans aucun moyen de
/// corriger. updateOrder met les trois à jour de façon cohérente.
///
/// Champs volontairement limités à la commande : le nom/téléphone du client
/// appartiennent à sa fiche (voir StylistClientsScreen) et le statut a ses
/// propres boutons, protégés par OrderStatus.canTransitionTo.
class EditOrderDialog extends StatefulWidget {
  const EditOrderDialog({super.key, required this.order});

  final Order order;

  /// Retourne true si la commande a effectivement été modifiée.
  static Future<bool?> show(BuildContext context, Order order) =>
      showDialog<bool>(context: context, builder: (_) => EditOrderDialog(order: order));

  @override
  State<EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<EditOrderDialog> {
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.order.description ?? '');
  late final TextEditingController _priceController =
      TextEditingController(text: widget.order.price?.toString() ?? '');
  late DateTime? _dueDate = widget.order.dueDate;

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      helpText: 'Date de livraison',
    );
    if (picked == null || !mounted) return;
    setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final priceText = _priceController.text.trim();
    final price = priceText.isEmpty ? null : int.tryParse(priceText);

    if (priceText.isNotEmpty && price == null) {
      setState(() => _error = 'Le prix total doit être un nombre entier.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await OrderService.instance.updateOrder(
        orderId: widget.order.id,
        // Chaîne vide volontaire (et non null) : updateOrder n'applique que les
        // valeurs non nulles, donc passer '' est le seul moyen d'EFFACER une
        // description existante.
        description: _descriptionController.text.trim(),
        price: price,
        dueDate: _dueDate,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = friendlyFirebaseError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      backgroundColor: c.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Modifier la commande', style: AppTextStyles.titleMd.copyWith(color: c.primary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client : ${widget.order.clientName}',
              style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descriptionController,
              enabled: !_isSubmitting,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _priceController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Prix total (${AppConstants.currency})',
                prefixText: '${AppConstants.currency} ',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: _isSubmitting ? null : _pickDueDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de livraison',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dueDate == null ? 'Non définie' : Formatters.date.format(_dueDate!),
                        style: AppTextStyles.bodyLg,
                      ),
                    ),
                    Icon(Icons.edit_calendar_outlined, size: 18, color: c.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: AppTextStyles.bodySm.copyWith(color: c.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: c.onPrimary),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
