import 'package:flutter/material.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../models/order.dart';
import '../../models/order_payment.dart';
import '../../screens/stylist/orders/record_payment_dialog.dart';
import '../../services/order_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/build_context_colors.dart';
import '../utils/formatters.dart';
import '../utils/order_messages.dart';
import '../utils/whatsapp_launcher.dart';
import 'premium_button.dart';

/// Bloc « Prix & paiements » d'une commande : liste des versements reçus,
/// total encaissé, reste à payer, encaissement d'un nouveau versement et
/// relance WhatsApp du solde.
///
/// Remplace l'ancien affichage « Acompte / Reste » figé : la source de vérité
/// est désormais `Order.payments`, ce qui permet d'enregistrer un règlement
/// en plusieurs fois sans perdre l'historique ni les dates.
class OrderPaymentsSection extends StatefulWidget {
  const OrderPaymentsSection({
    super.key,
    required this.order,
    this.canEdit = true,
  });

  final Order order;

  /// `false` pour un couturier : il voit les montants mais n'encaisse pas.
  final bool canEdit;

  @override
  State<OrderPaymentsSection> createState() => _OrderPaymentsSectionState();
}

class _OrderPaymentsSectionState extends State<OrderPaymentsSection> {
  late Order _order = widget.order;

  /// Relit la commande dans le service : en mode démo la valeur est mise à jour
  /// immédiatement, en mode Firestore le cache est rafraîchi par l'écoute.
  void _refresh() {
    final fresh = OrderService.instance.orderById(_order.id);
    if (fresh != null) setState(() => _order = fresh);
  }

  Future<void> _recordPayment() async {
    final added = await RecordPaymentDialog.show(context, _order);
    if (added) _refresh();
  }

  Future<void> _deletePayment(OrderPayment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce versement ?'),
        content: Text(
          '${Formatters.formatCurrency(payment.amount)} du '
          '${Formatters.date.format(payment.paidAt)} seront retirés de la '
          'commande. Le solde restant sera recalculé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await OrderService.instance.removePayment(_order.id, payment.id);
    _refresh();
  }

  Future<void> _remindBalance() async {
    final ok = await WhatsAppLauncher.sendMessage(
      phone: _order.clientPhone,
      message: OrderMessages.balanceReminder(_order),
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp n\'a pas pu être ouvert.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final price = _order.price;

    if (price == null) {
      return Text(
        'Renseignez un prix sur la commande pour suivre les versements.',
        style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
      );
    }

    final payments = _order.payments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Formatters.formatCurrency(price),
          style: AppTextStyles.headlineSm.copyWith(color: c.onSurface),
        ),
        const SizedBox(height: 2),
        Text(
          payments.isEmpty
              ? 'Aucun versement enregistré'
              : '${payments.length} versement${payments.length > 1 ? 's' : ''}',
          style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
        ),
        if (payments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ...payments.map(
            (p) => _PaymentRow(
              payment: p,
              canDelete: widget.canEdit,
              onDelete: () => _deletePayment(p),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Divider(color: c.outlineVariant, height: 1),
        const SizedBox(height: AppSpacing.sm),
        _TotalRow(
          label: 'Encaissé',
          value: _order.totalPaid,
          color: _order.totalPaid > 0 ? c.statusDone : c.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        _TotalRow(
          label: 'Reste à payer',
          value: _order.balanceDue,
          color: _order.hasOutstandingBalance ? c.error : c.onSurfaceVariant,
          bold: true,
        ),
        if (widget.canEdit) ...[
          const SizedBox(height: AppSpacing.md),
          PremiumButton(
            label: _order.hasOutstandingBalance
                ? 'Encaisser un versement'
                : 'Ajouter un versement',
            icon: PhosphorIconsRegular.wallet,
            onPressed: _recordPayment,
          ),
          if (_order.hasOutstandingBalance)
            Center(
              child: TextButton.icon(
                onPressed: _remindBalance,
                icon: const Icon(PhosphorIconsRegular.whatsappLogo, size: 16),
                label: const Text('Relancer le solde par WhatsApp'),
                style: TextButton.styleFrom(foregroundColor: c.goldInk),
              ),
            ),
        ],
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.canDelete,
    required this.onDelete,
  });

  final OrderPayment payment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.formatCurrency(payment.amount),
                  style: AppTextStyles.bodyLg.copyWith(color: c.onSurface),
                ),
                Text(
                  '${Formatters.date.format(payment.paidAt)} · ${payment.method.label}'
                  '${payment.note != null ? ' · ${payment.note}' : ''}',
                  style: AppTextStyles.labelXs
                      .copyWith(color: c.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              onPressed: onDelete,
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              color: c.onSurfaceVariant,
              tooltip: 'Supprimer ce versement',
              icon: const Icon(PhosphorIconsRegular.trash),
            ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final String label;
  final int value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySm.copyWith(color: c.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          Formatters.formatCurrency(value),
          style: AppTextStyles.bodyLg.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
