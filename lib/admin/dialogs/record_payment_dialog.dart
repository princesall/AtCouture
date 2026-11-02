import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/build_context_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/admin_account.dart';
import '../../models/app_user.dart';
import '../../models/subscription_plan.dart';

class PaymentDraft {
  const PaymentDraft({
    required this.plan,
    required this.amount,
    required this.method,
    required this.months,
    this.reference,
    this.note,
  });

  final SubscriptionPlan plan;
  final int amount;
  final SubscriptionPaymentMethod method;
  final int months;
  final String? reference;
  final String? note;
}

Future<PaymentDraft?> showRecordPaymentDialog(
  BuildContext context, {
  required AppUser user,
}) {
  return showDialog<PaymentDraft>(
    context: context,
    builder: (_) => _RecordPaymentDialog(user: user),
  );
}

class _RecordPaymentDialog extends StatefulWidget {
  const _RecordPaymentDialog({required this.user});

  final AppUser user;

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  late SubscriptionPlan _plan = widget.user.plan == SubscriptionPlan.free
      ? SubscriptionPlan.starter
      : widget.user.plan;
  SubscriptionPaymentMethod _method = SubscriptionPaymentMethod.orangeMoney;
  int _months = 1;

  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = _plan.price > 0 ? '${_plan.price}' : '';
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get _amount => int.tryParse(_amountController.text.trim()) ?? 0;

  DateTime get _periodStart {
    final now = DateTime.now();
    final expiry = widget.user.planExpiresAt;
    return expiry != null && expiry.isAfter(now) ? expiry : now;
  }

  DateTime get _periodEnd => _addMonths(_periodStart, _months);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final valid = _amount > 0;

    return Dialog(
      backgroundColor: c.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enregistrer un paiement',
                            style: AppTextStyles.titleMd.copyWith(
                              fontSize: 18,
                              color: c.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.user.fullName,
                            style: AppTextStyles.bodySm.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: c.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _label(context, 'FORMULE'),
                const SizedBox(height: 6),
                DropdownButtonFormField<SubscriptionPlan>(
                  initialValue: _plan,
                  decoration: _decoration(context, null),
                  items: [
                    for (final plan in SubscriptionPlan.values)
                      DropdownMenuItem(
                        value: plan,
                        child: Text(
                          plan.price > 0
                              ? '${plan.name} · ${Formatters.formatCurrency(plan.price)}'
                              : plan.name,
                          style: AppTextStyles.bodySm.copyWith(
                            fontSize: 12.5,
                            color: c.onSurface,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (plan) {
                    if (plan == null) return;
                    setState(() {
                      _plan = plan;
                      if (_amountController.text.trim().isEmpty ||
                          _amountController.text == '0') {
                        _amountController.text = '${plan.price}';
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),
                _label(context, 'MONTANT ENCAISSÉ (FCFA)'),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 14,
                    color: c.onSurface,
                  ),
                  decoration: _decoration(context, 'Ex. 12000').copyWith(
                    suffixText: 'FCFA',
                    suffixStyle: AppTextStyles.labelCaps.copyWith(
                      fontSize: 9,
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _label(context, 'PÉRIODE COUVERTE'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final months in [1, 3, 6, 12])
                      ChoiceChip(
                        label: Text(
                          '$months mois',
                          style: AppTextStyles.labelXs.copyWith(
                            fontSize: 10,
                            color: _months == months
                                ? c.onPrimary
                                : c.onSurfaceVariant,
                          ),
                        ),
                        selected: _months == months,
                        selectedColor: c.primary,
                        backgroundColor: c.surfaceContainerLow,
                        side: BorderSide(
                          color: _months == months
                              ? Colors.transparent
                              : c.outlineVariant,
                        ),
                        onSelected: (_) => setState(() => _months = months),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _label(context, 'MOYEN DE PAIEMENT'),
                const SizedBox(height: 6),
                DropdownButtonFormField<SubscriptionPaymentMethod>(
                  initialValue: _method,
                  decoration: _decoration(context, null),
                  items: [
                    for (final method in SubscriptionPaymentMethod.values)
                      DropdownMenuItem(
                        value: method,
                        child: Text(
                          method.label,
                          style: AppTextStyles.bodySm.copyWith(
                            fontSize: 12.5,
                            color: c.onSurface,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (method) {
                    if (method != null) setState(() => _method = method);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(context, 'RÉFÉRENCE (OPTIONNEL)'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _referenceController,
                            style: AppTextStyles.bodySm.copyWith(
                              fontSize: 12.5,
                              color: c.onSurface,
                            ),
                            decoration: _decoration(
                              context,
                              'Ex. OM-2026-00123',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(context, 'NOTE (OPTIONNEL)'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _noteController,
                            style: AppTextStyles.bodySm.copyWith(
                              fontSize: 12.5,
                              color: c.onSurface,
                            ),
                            decoration: _decoration(context, 'Ex. paiement reçu'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_available_rounded, size: 16, color: c.statusDone),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nouvelle expiration : ${Formatters.date.format(_periodEnd)}',
                          style: AppTextStyles.bodySm.copyWith(
                            fontSize: 11.5,
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Annuler',
                        style: AppTextStyles.bodySm.copyWith(
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: valid
                          ? () => Navigator.of(context).pop(
                                PaymentDraft(
                                  plan: _plan,
                                  amount: _amount,
                                  method: _method,
                                  months: _months,
                                  reference: _referenceController.text,
                                  note: _noteController.text,
                                ),
                              )
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(
                        'ENREGISTRER',
                        style: AppTextStyles.labelCaps.copyWith(
                          fontSize: 9.5,
                          color: c.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    final c = context.colors;
    return Text(
      text,
      style: AppTextStyles.labelCaps.copyWith(
        color: c.onSurfaceVariant,
        fontSize: 8.5,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, String? hint) {
    final c = context.colors;
    return InputDecoration(
      filled: true,
      fillColor: c.surfaceContainerLow,
      isDense: true,
      hintText: hint,
      hintStyle: AppTextStyles.bodySm.copyWith(
        fontSize: 12,
        color: c.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.goldInk, width: 1.3),
      ),
    );
  }

  static DateTime _addMonths(DateTime date, int months) {
    final rawMonth = date.month + months;
    final year = date.year + (rawMonth - 1) ~/ 12;
    final month = (rawMonth - 1) % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }
}
