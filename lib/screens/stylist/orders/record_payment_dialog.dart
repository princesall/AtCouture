import 'package:flutter/material.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/build_context_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../models/order.dart';
import '../../../models/order_payment.dart';
import '../../../services/order_service.dart';

/// Dialogue d'encaissement d'un versement (acompte ou règlement partiel).
///
/// Le montant est pré-rempli avec le reste à payer — le cas le plus fréquent
/// étant le règlement du solde à la livraison. Retourne `true` si un versement
/// a bien été enregistré.
class RecordPaymentDialog extends StatefulWidget {
  const RecordPaymentDialog({super.key, required this.order});

  final Order order;

  static Future<bool> show(BuildContext context, Order order) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordPaymentDialog(order: order),
    );
    return result ?? false;
  }

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  late final TextEditingController _amountController = TextEditingController(
    text: widget.order.balanceDue > 0 ? widget.order.balanceDue.toString() : '',
  );
  final _noteController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  late DateTime _paidAt = DateTime.now();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  Future<void> _submit() async {
    final amount = int.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Saisissez un montant valide.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await OrderService.instance.addPayment(
        orderId: widget.order.id,
        amount: amount,
        method: _method,
        paidAt: _paidAt,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on PaymentException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rest = widget.order.balanceDue;

    return Padding(
      // Laisse la place au clavier sur mobile.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
              Text('Encaisser un versement',
                  style: AppTextStyles.headlineSm.copyWith(color: c.onSurface)),
              const SizedBox(height: 4),
              Text(
                rest > 0
                    ? 'Reste à payer : ${Formatters.formatCurrency(rest)}'
                    : 'Cette commande est déjà réglée en totalité.',
                style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),

              PremiumTextField(
                controller: _amountController,
                label: 'Montant reçu (FCFA)',
                hint: '50 000',
                prefixIcon: PhosphorIconsRegular.wallet,
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),

              Text('Moyen de paiement',
                  style: AppTextStyles.labelCaps
                      .copyWith(color: c.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: PaymentMethod.values.map((m) {
                  final selected = m == _method;
                  return ChoiceChip(
                    label: Text(m.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _method = m),
                    showCheckmark: false,
                    labelStyle: AppTextStyles.labelCaps.copyWith(
                      color: selected ? c.onPrimary : c.onSurfaceVariant,
                    ),
                    selectedColor: c.primary,
                    backgroundColor: c.surfaceContainerLowest,
                    side: BorderSide(
                      color: selected ? c.primary : c.outlineVariant,
                      width: 1,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.calendarBlank,
                          size: 18, color: c.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Reçu le ${Formatters.date.format(_paidAt)}',
                        style: AppTextStyles.bodySm
                            .copyWith(color: c.onSurface),
                      ),
                      const Spacer(),
                      Text('Modifier',
                          style: AppTextStyles.bodySm
                              .copyWith(color: c.goldInk)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              PremiumTextField(
                controller: _noteController,
                label: 'Note (facultatif)',
                hint: 'Ex. versement remis par la sœur du client',
                prefixIcon: PhosphorIconsRegular.notePencil,
              ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTextStyles.bodySm
                      .copyWith(color: c.error, fontWeight: FontWeight.w600),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              PremiumButton(
                label: 'Enregistrer le versement',
                icon: PhosphorIconsRegular.check,
                isLoading: _saving,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
