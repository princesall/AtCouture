import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/admin_demo_data.dart';
import '../../models/subscription_plan.dart';
import '../../providers/auth_provider.dart';

/// Sélecteur d'abonnement — accessible à tout moment depuis l'onglet Profil
/// (tuile "Abonnement"), et pas seulement quand une limite de plan est
/// atteinte (voir les dialogues "Limite atteinte" des écrans Commandes/
/// Clients/Couturiers, qui appellent aussi `show()` en dernière étape).
abstract final class SubscriptionDialog {
  static void show(BuildContext context) {
    final user = context.read<AuthProvider>().user!;
    final currentPlan = user.plan;

    // Vérifier si une demande est déjà en cours pour ce compte.
    final entry = AdminDemoData.stylists.where((s) => s.user.id == user.id).firstOrNull;
    final pendingRequest = entry?.subscriptionRequest;

    if (pendingRequest != null && !pendingRequest.approved) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pending_rounded, color: AppColors.tertiary, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Demande en cours',
                  style: AppTextStyles.titleMd.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Votre demande pour le plan ${pendingRequest.requestedPlan.name} est en cours de traitement par l\'administrateur.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Compris'),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 980,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: _PlanPicker(
            currentPlan: currentPlan,
            onPick: (plan) {
              Navigator.pop(context);
              _confirmRequest(context, plan);
            },
          ),
        ),
      ),
    );
  }

  static void _confirmRequest(BuildContext context, SubscriptionPlan plan) {
    final user = context.read<AuthProvider>().user!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la demande'),
        content: Text(
          'Voulez-vous envoyer une demande pour le plan ${plan.name} (${plan.priceLabel}) à l\'administrateur ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AdminDemoData.requestSubscription(user.id, plan);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Demande envoyée pour le plan ${plan.name}'),
                  backgroundColor: AppColors.tertiary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

/// Un point vendu par un plan — icône + couleur + libellé.
typedef _Feature = (IconData, Color, String);

class _PlanPicker extends StatefulWidget {
  const _PlanPicker({required this.currentPlan, required this.onPick});

  final SubscriptionPlan currentPlan;
  final ValueChanged<SubscriptionPlan> onPick;

  @override
  State<_PlanPicker> createState() => _PlanPickerState();
}

class _PlanPickerState extends State<_PlanPicker> {
  bool _annual = false;

  static final _plans = [SubscriptionPlan.starter, SubscriptionPlan.pro, SubscriptionPlan.enterprise];

  List<_Feature> _featuresFor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.starter:
        return [
          (Icons.person_outline_rounded, AppColors.primary, plan.tailorsLabel),
          (Icons.people_outline_rounded, AppColors.primary, plan.clientsLabel),
          (Icons.receipt_long_outlined, AppColors.success, plan.ordersLabel),
          (Icons.straighten_rounded, AppColors.success, 'Mensurations sauvegardées'),
          (Icons.notifications_active_outlined, AppColors.secondary, 'Notifications push'),
        ];
      case SubscriptionPlan.pro:
        return [
          (Icons.person_outline_rounded, AppColors.primary, plan.tailorsLabel),
          (Icons.people_outline_rounded, AppColors.primary, 'Clients illimités'),
          (Icons.insights_rounded, AppColors.success, 'Statistiques avancées'),
          (Icons.calendar_month_rounded, AppColors.secondary, 'Calendrier & rappels automatiques'),
          (Icons.request_quote_outlined, AppColors.secondary, 'Devis & factures PDF'),
          (Icons.headset_mic_outlined, AppColors.tertiary, 'Support prioritaire'),
        ];
      case SubscriptionPlan.enterprise:
        return [
          (Icons.person_outline_rounded, AppColors.primary, 'Couturiers illimités'),
          (Icons.people_outline_rounded, AppColors.primary, 'Clients illimités'),
          (Icons.apartment_rounded, AppColors.success, 'Plusieurs ateliers'),
          (Icons.palette_outlined, AppColors.secondary, 'Personnalisation & API'),
          (Icons.verified_outlined, AppColors.tertiary, 'Toutes les fonctionnalités Pro incluses'),
          (Icons.headset_mic_outlined, AppColors.tertiary, 'Gestionnaire dédié 24/7'),
        ];
      case SubscriptionPlan.free:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: AppColors.tertiary, size: 28),
              const SizedBox(width: 12),
              Text('Choisir un abonnement', style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              text: 'Votre plan actuel : ',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              children: [
                TextSpan(
                  text: widget.currentPlan.name,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text('Plan actuel', style: AppTextStyles.labelXs.copyWith(color: AppColors.success)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Flexible(
            child: SingleChildScrollView(
              child: LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 760;
                final cards = _plans
                    .map((plan) => _PlanCard(
                          plan: plan,
                          annual: _annual,
                          isCurrent: plan == widget.currentPlan,
                          isPopular: plan == SubscriptionPlan.pro,
                          features: _featuresFor(plan),
                          onPick: () => widget.onPick(plan),
                        ))
                    .toList();

                if (isWide) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final card in cards) ...[
                          Expanded(child: card),
                          if (card != cards.last) const SizedBox(width: AppSpacing.md),
                        ],
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      if (card != cards.last) const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Facturation annuelle', style: AppTextStyles.titleSm),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          text: 'Économisez ',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                          children: [
                            TextSpan(
                              text: 'jusqu\'à 20%',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                            ),
                            const TextSpan(text: ' avec l\'abonnement annuel.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _annual,
                  onChanged: (value) => setState(() => _annual = value),
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('-20%', style: AppTextStyles.labelXs.copyWith(color: AppColors.success)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Vous pourrez changer d\'abonnement à tout moment. Sans engagement. Annulez quand vous voulez.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.annual,
    required this.isCurrent,
    required this.isPopular,
    required this.features,
    required this.onPick,
  });

  final SubscriptionPlan plan;
  final bool annual;
  final bool isCurrent;
  final bool isPopular;
  final List<_Feature> features;
  final VoidCallback onPick;

  Color get _accent => plan == SubscriptionPlan.enterprise
      ? AppColors.tertiary
      : (isPopular ? AppColors.primary : AppColors.onSurfaceVariant);

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern('fr_FR');
    final displayAmount = annual ? (plan.price * 12 * 0.8).round() : plan.price;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(top: isPopular ? 14 : 0),
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
          decoration: BoxDecoration(
            color: plan == SubscriptionPlan.enterprise
                ? AppColors.tertiary.withValues(alpha: 0.05)
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isPopular ? AppColors.primary : _accent.withValues(alpha: 0.3),
              width: isPopular ? 2 : 1,
            ),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  plan.name.toUpperCase(),
                  style: AppTextStyles.labelCaps.copyWith(color: _accent),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: numberFormat.format(displayAmount),
                    style: AppTextStyles.headlineMd.copyWith(color: _accent, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(
                        text: ' FCFA',
                        style: AppTextStyles.bodySm.copyWith(color: _accent),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Text(
                  annual ? '/an' : '/mois',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              for (final feature in features) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: feature.$2.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Icon(feature.$1, size: 13, color: feature.$2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(feature.$3, style: AppTextStyles.bodySm)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: isCurrent
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Plan actuel'),
                      )
                    : isPopular
                        ? ElevatedButton(
                            onPressed: onPick,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: const Text('Choisir'),
                          )
                        : OutlinedButton(
                            onPressed: onPick,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accent,
                              side: BorderSide(color: _accent),
                            ),
                            child: const Text('Choisir'),
                          ),
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'LE PLUS POPULAIRE',
                      style: AppTextStyles.labelXs.copyWith(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
