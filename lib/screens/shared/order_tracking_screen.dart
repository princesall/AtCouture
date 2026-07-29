import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/premium_button.dart';
import '../../core/widgets/premium_text_field.dart';
import '../../core/widgets/stitch_widgets.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../services/order_service.dart';

/// Écran public — accessible SANS compte via `/suivi` — permettant à un
/// client final de suivre l'avancement de sa commande à partir du numéro
/// communiqué par l'atelier (WhatsApp, SMS, oral). Ne montre volontairement
/// aucune donnée sensible (prix, acompte, mesures, téléphone) : uniquement
/// le statut et les informations utiles à la livraison.
class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _idController = TextEditingController();
  Order? _result;
  bool _searched = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _search() {
    final id = _idController.text.trim();
    setState(() {
      _searched = true;
      _result = id.isEmpty ? null : OrderService.instance.orderById(id);
    });
  }

  String _statusExplanation(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Votre commande a été enregistrée et sera bientôt prise en charge.';
      case OrderStatus.inProgress:
        return 'Votre commande est en cours de confection.';
      case OrderStatus.completed:
        return 'Votre commande est terminée et prête à être récupérée.';
      case OrderStatus.problem:
        return 'Un problème est survenu sur votre commande — contactez l\'atelier pour plus de détails.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Suivre ma commande'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrez le numéro de commande communiqué par votre atelier '
                '(par exemple par WhatsApp) pour suivre son avancement.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              PremiumTextField(
                controller: _idController,
                label: 'Numéro de commande',
                hint: 'ex : order_1000',
                prefixIcon: Icons.receipt_long_outlined,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumButton(
                label: 'Suivre ma commande',
                onPressed: _search,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_searched) _buildResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final order = _result;
    if (order == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Aucune commande trouvée avec ce numéro. Vérifiez le numéro reçu par votre atelier.',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.atelierName, style: AppTextStyles.titleMd),
              ),
              StatusBadge(order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            order.description ?? 'Vêtement non précisé',
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _statusExplanation(order.status),
            style: AppTextStyles.bodySm,
          ),
          if (order.dueDate != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 16, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Livraison prévue le ${Formatters.date.format(order.dueDate!)}',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
